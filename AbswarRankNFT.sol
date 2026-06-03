// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * ABSWAR Rank NFT badges.
 *
 * Soulbound ERC-721 style prestige badges. They do not give game power.
 * A player can mint a rank badge only with a backend signature proving
 * that the wallet reached the required contribution threshold.
 */
contract AbswarRankNFT {
    string public name = "ABSWAR Rank Badges";
    string public symbol = "ABSRANK";

    address public owner;
    address public signer;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(uint8 => bool)) public claimed;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event SignerChanged(address indexed oldSigner, address indexed newSigner);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event RankMinted(address indexed player, uint8 indexed rank, uint256 indexed tokenId);

    error NotOwner();
    error ZeroAddress();
    error InvalidRank();
    error ExpiredSignature();
    error AlreadyClaimed();
    error InvalidSignature();
    error Soulbound();
    error TokenMissing();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address initialSigner) {
        owner = msg.sender;
        signer = initialSigner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setSigner(address newSigner) external onlyOwner {
        emit SignerChanged(signer, newSigner);
        signer = newSigner;
    }

    function mintRank(uint8 rank, uint256 deadline, bytes calldata signature) external {
        if (rank >= 7) revert InvalidRank();
        if (block.timestamp > deadline) revert ExpiredSignature();
        if (claimed[msg.sender][rank]) revert AlreadyClaimed();
        if (!_verify(msg.sender, rank, deadline, signature)) revert InvalidSignature();

        uint256 tokenId = getTokenId(msg.sender, rank);
        claimed[msg.sender][rank] = true;
        _owners[tokenId] = msg.sender;
        _balances[msg.sender] += 1;

        emit Transfer(address(0), msg.sender, tokenId);
        emit RankMinted(msg.sender, rank, tokenId);
    }

    function hasRankNFT(address player, uint8 rank) external view returns (bool) {
        if (rank >= 7) return false;
        return claimed[player][rank];
    }

    function getTokenId(address player, uint8 rank) public pure returns (uint256) {
        return (uint256(uint160(player)) << 8) | uint256(rank);
    }

    function claimDigest(address player, uint8 rank, uint256 deadline) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), block.chainid, player, rank, deadline));
    }

    function balanceOf(address account) external view returns (uint256) {
        if (account == address(0)) revert ZeroAddress();
        return _balances[account];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address tokenOwner = _owners[tokenId];
        if (tokenOwner == address(0)) revert TokenMissing();
        return tokenOwner;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        ownerOf(tokenId);
        uint8 rank = uint8(tokenId & 0xff);
        string memory rankName = _rankName(rank);
        string memory json = string.concat(
            '{"name":"ABSWAR ', rankName, ' Badge",',
            '"description":"Soulbound ABSWAR prestige badge. It proves the wallet reached this rank; it gives no extra game power.",',
            '"image":"data:image/svg+xml;base64,', Base64.encode(bytes(_badgeSvg(rank))), '",',
            '"attributes":[',
            '{"trait_type":"Rank","value":"', rankName, '"},',
            '{"trait_type":"Contribution Threshold","value":"', Strings.toString(_rankMin(rank)), '"},',
            '{"trait_type":"Bonus Percent","value":"', Strings.toString(_rankBonus(rank)), '"},',
            '{"trait_type":"Transferability","value":"Soulbound"}',
            ']}'
        );
        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x5b5e139f;   // ERC721 metadata
    }

    function approve(address, uint256) external pure { revert Soulbound(); }
    function setApprovalForAll(address, bool) external pure { revert Soulbound(); }
    function transferFrom(address, address, uint256) external pure { revert Soulbound(); }
    function safeTransferFrom(address, address, uint256) external pure { revert Soulbound(); }
    function safeTransferFrom(address, address, uint256, bytes calldata) external pure { revert Soulbound(); }
    function getApproved(uint256) external pure returns (address) { return address(0); }
    function isApprovedForAll(address, address) external pure returns (bool) { return false; }

    function _verify(address player, uint8 rank, uint256 deadline, bytes calldata signature) internal view returns (bool) {
        if (signer == address(0) || signature.length != 65) return false;
        bytes32 digest = claimDigest(player, rank, deadline);
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", digest));

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := calldataload(signature.offset)
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }
        if (v < 27) v += 27;
        if (v != 27 && v != 28) return false;
        if (uint256(s) > 0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0) return false;
        return ecrecover(ethHash, v, r, s) == signer;
    }

    function _rankName(uint8 rank) internal pure returns (string memory) {
        if (rank == 0) return "Asker";
        if (rank == 1) return "Onbasi";
        if (rank == 2) return "Cavus";
        if (rank == 3) return "Tegmen";
        if (rank == 4) return "Yuzbasi";
        if (rank == 5) return "Binbasi";
        return "General";
    }

    function _rankMin(uint8 rank) internal pure returns (uint256) {
        if (rank == 0) return 0;
        if (rank == 1) return 50;
        if (rank == 2) return 200;
        if (rank == 3) return 500;
        if (rank == 4) return 1500;
        if (rank == 5) return 5000;
        return 15000;
    }

    function _rankBonus(uint8 rank) internal pure returns (uint256) {
        if (rank == 0) return 0;
        if (rank == 1) return 5;
        if (rank == 2) return 10;
        if (rank == 3) return 15;
        if (rank == 4) return 20;
        if (rank == 5) return 25;
        return 30;
    }

    function _badgeSvg(uint8 rank) internal pure returns (string memory) {
        string memory color = rank >= 5 ? "#f5c842" : rank >= 3 ? "#c9d6df" : rank >= 1 ? "#f5c842" : "#00c853";
        string memory rare = rank == 6 ? '<text x="128" y="218" text-anchor="middle" fill="#f5c842" font-size="12">EN NADIR</text>' : "";
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">',
            '<rect width="256" height="256" rx="24" fill="#090c0f"/>',
            '<circle cx="128" cy="116" r="82" fill="#0d1117" stroke="', color, '" stroke-width="6"/>',
            '<circle cx="128" cy="116" r="62" fill="none" stroke="#e8162a" stroke-width="2" opacity=".55"/>',
            '<text x="128" y="88" text-anchor="middle" fill="', color, '" font-family="monospace" font-size="18">ABSWAR</text>',
            '<text x="128" y="130" text-anchor="middle" fill="#ffffff" font-family="monospace" font-size="24">', _rankStars(rank), '</text>',
            '<text x="128" y="166" text-anchor="middle" fill="', color, '" font-family="monospace" font-size="20">', _rankName(rank), '</text>',
            '<text x="128" y="196" text-anchor="middle" fill="#b8ccd8" font-family="monospace" font-size="12">', Strings.toString(_rankMin(rank)), ' katki / +', Strings.toString(_rankBonus(rank)), '%</text>',
            rare,
            '</svg>'
        );
    }

    function _rankStars(uint8 rank) internal pure returns (string memory) {
        if (rank == 0) return "HELM";
        if (rank == 1) return "-";
        if (rank == 2) return "--";
        if (rank == 3) return "*";
        if (rank == 4) return "**";
        if (rank == 5) return "***";
        return "****";
    }
}

library Strings {
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }
        return result;
    }
}
