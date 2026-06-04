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
        if (rank == 6) {
            return string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="170" viewBox="0 0 200 170">',
                _badgeDefs(),
                '<rect x="0" y="0" width="200" height="170" rx="12" fill="url(#genPlate)" stroke="#8f7320" stroke-width="2"/>',
                '<g stroke="#c9a84a" stroke-width="1.8" fill="none" opacity="0.85">',
                '<path d="M62 70 q-12 -18 -7 -36"/><path d="M60 62 q-10 -3 -13 -11"/><path d="M62 52 q-10 -3 -13 -11"/>',
                '<path d="M138 70 q12 -18 7 -36"/><path d="M140 62 q10 -3 13 -11"/><path d="M138 52 q10 -3 13 -11"/></g>',
                '<circle cx="100" cy="58" r="40" fill="none" stroke="#f0c850" stroke-width="3"/>',
                '<circle cx="100" cy="58" r="32" fill="url(#genDisk)" stroke="#8f7320" stroke-width="1"/>',
                '<path d="M100 34 l5 13 l14 0 l-11 8 l4 13 l-12 -8 l-12 8 l4 -13 l-11 -8 l14 0 z" fill="#ffd966"/>',
                '<path d="M78 56 l3 10 l11 0 l-9 6 l3 11 l-8 -6 l-8 6 l3 -11 l-9 -6 l11 0 z" fill="#ffd966"/>',
                '<path d="M122 56 l3 10 l11 0 l-9 6 l3 11 l-8 -6 l-8 6 l3 -11 l-9 -6 l11 0 z" fill="#ffd966"/>',
                '<path d="M100 74 l3 10 l11 0 l-9 6 l3 11 l-8 -6 l-8 6 l3 -11 l-9 -6 l11 0 z" fill="#ffd966"/>',
                '<text x="100" y="122" text-anchor="middle" fill="#ffe9a8" font-family="sans-serif" font-size="16" font-weight="700">GENERAL</text>',
                '<text x="100" y="142" text-anchor="middle" fill="#8f7320" font-family="monospace" font-size="10">15.000 katk&#305; &#183; +%30</text>',
                '<text x="100" y="159" text-anchor="middle" fill="#6f5a20" font-family="monospace" font-size="9" letter-spacing="1">&#9733; EN NAD&#304;R &#9733;</text>',
                '</svg>'
            );
        }
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="150" viewBox="0 0 200 150">',
            _badgeDefs(),
            '<rect x="0" y="0" width="200" height="150" rx="10" fill="url(#plate)" stroke="', _rankBorder(rank), '" stroke-width="', rank == 5 ? "1.5" : "1", '"/>',
            '<circle cx="100" cy="55" r="36" fill="none" stroke="', _rankStroke(rank), '" stroke-width="', rank == 5 ? "2.5" : "2", '"/>',
            '<circle cx="100" cy="55" r="29" fill="#0e1a14"/>',
            _rankIcon(rank),
            '<text x="100" y="112" text-anchor="middle" fill="', rank == 5 ? "#f5ecd8" : "#e8f5ec", '" font-family="sans-serif" font-size="15" font-weight="600">', _rankDisplayName(rank), '</text>',
            '<text x="100" y="133" text-anchor="middle" fill="', _rankAccent(rank), '" font-family="monospace" font-size="10">', _rankMinLabel(rank), ' katk&#305; &#183; +%', Strings.toString(_rankBonus(rank)), '</text>',
            '</svg>'
        );
    }

    function _badgeDefs() internal pure returns (string memory) {
        return string.concat(
            '<defs>',
            '<linearGradient id="plate" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#16221c"/><stop offset="1" stop-color="#0c1410"/></linearGradient>',
            '<linearGradient id="genPlate" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#1a1408"/><stop offset="1" stop-color="#0c0a04"/></linearGradient>',
            '<radialGradient id="genDisk" cx="0.5" cy="0.4" r="0.6"><stop offset="0" stop-color="#1a2018"/><stop offset="1" stop-color="#0a0e0a"/></radialGradient>',
            '</defs>'
        );
    }

    function _rankDisplayName(uint8 rank) internal pure returns (string memory) {
        if (rank == 0) return "ASKER";
        if (rank == 1) return "ONBA&#350;I";
        if (rank == 2) return "&#199;AVU&#350;";
        if (rank == 3) return "TE&#286;MEN";
        if (rank == 4) return "Y&#220;ZBA&#350;I";
        if (rank == 5) return "B&#304;NBA&#350;I";
        return "GENERAL";
    }

    function _rankMinLabel(uint8 rank) internal pure returns (string memory) {
        if (rank == 4) return "1.500";
        if (rank == 5) return "5.000";
        if (rank == 6) return "15.000";
        return Strings.toString(_rankMin(rank));
    }

    function _rankStroke(uint8 rank) internal pure returns (string memory) {
        if (rank == 0) return "#3a8f5c";
        if (rank == 1 || rank == 2) return "#c9a84a";
        if (rank == 3 || rank == 4) return "#d4d4d8";
        if (rank == 5) return "#e0b84a";
        return "#f0c850";
    }

    function _rankFill(uint8 rank) internal pure returns (string memory) {
        if (rank == 0) return "#5fae7a";
        if (rank == 1 || rank == 2) return "#c9a84a";
        if (rank == 3 || rank == 4) return "#e4e4e8";
        if (rank == 5) return "#f0c850";
        return "#ffd966";
    }

    function _rankPlate(uint8 rank) internal pure returns (string memory) {
        if (rank == 6) return "#1a1408";
        if (rank == 5) return "#17150f";
        return "#16221c";
    }

    function _rankBorder(uint8 rank) internal pure returns (string memory) {
        if (rank == 6) return "#8f7320";
        if (rank == 5) return "#5a4a2a";
        if (rank >= 3) return "#3a4a40";
        return "#2a3a30";
    }

    function _rankAccent(uint8 rank) internal pure returns (string memory) {
        if (rank >= 6) return "#8f7320";
        if (rank == 5) return "#6f5a2a";
        return "#4a6f58";
    }

    function _rankIcon(uint8 rank) internal pure returns (string memory) {
        string memory fill = _rankFill(rank);
        string memory stroke = _rankStroke(rank);
        if (rank == 0) {
            return string.concat('<path d="M82 62 a18 14 0 0 1 36 0 z" fill="', fill, '"/><rect x="80" y="60" width="40" height="4" rx="2" fill="', stroke, '"/>');
        }
        if (rank == 1) {
            return string.concat('<path d="M84 50 l16 10 l16 -10 v8 l-16 10 l-16 -10 z" fill="', fill, '"/>');
        }
        if (rank == 2) {
            return string.concat(
                '<path d="M84 44 l16 10 l16 -10 v8 l-16 10 l-16 -10 z" fill="', fill, '"/>',
                '<path d="M84 58 l16 10 l16 -10 v8 l-16 10 l-16 -10 z" fill="', fill, '"/>'
            );
        }
        if (rank == 3) {
            return string.concat('<path d="M100 36 l5 15 l16 0 l-13 9 l5 15 l-13 -9 l-13 9 l5 -15 l-13 -9 l16 0 z" fill="', fill, '"/>');
        }
        if (rank == 4) {
            return string.concat(
                '<path d="M82 48 l4 12 l13 0 l-10 8 l4 12 l-11 -8 l-11 8 l4 -12 l-10 -8 l13 0 z" fill="', fill, '"/>',
                '<path d="M118 48 l4 12 l13 0 l-10 8 l4 12 l-11 -8 l-11 8 l4 -12 l-10 -8 l13 0 z" fill="', fill, '"/>'
            );
        }
        if (rank == 5) {
            return string.concat(
                '<path d="M100 34 l5 14 l15 0 l-12 9 l5 14 l-13 -9 l-13 9 l5 -14 l-12 -9 l15 0 z" fill="', fill, '"/>',
                '<path d="M76 60 l4 10 l11 0 l-9 7 l3 11 l-9 -7 l-9 7 l3 -11 l-9 -7 l11 0 z" fill="', fill, '"/>',
                '<path d="M124 60 l4 10 l11 0 l-9 7 l3 11 l-9 -7 l-9 7 l3 -11 l-9 -7 l11 0 z" fill="', fill, '"/>'
            );
        }
        return "";
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
