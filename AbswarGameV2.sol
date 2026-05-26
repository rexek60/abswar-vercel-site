// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * ABSWAR - Oyun Ekonomi Contract'i (v2)
 *
 * Abstract Testnet'e deploy edildi.
 * Deploy adresi: 0x325b18816734210e9fEbAA0516030A8Ec74bE3d4
 *
 * Ammo satis geliri otomatik bolunur:
 *   %70 -> Reward Pool (kazanan ulkeye dagitilir)
 *   %20 -> Treasury (proje payi)
 *   %10 -> Operations (sunucu/bakim)
 */
contract AbswarGameV2 {

    address public owner;

    uint256 public rewardPool;
    uint256 public treasury;
    uint256 public operations;

    uint256 public rewardPct = 70;
    uint256 public treasuryPct = 20;
    uint256 public operationsPct = 10;

    uint256 public ammoPrice = 0.001 ether;
    mapping(address => uint256) public ammoBalance;
    uint256 public totalAmmoSold;

    bool public gameActive = true;

    event AmmoPurchased(address indexed buyer, uint256 amount, uint256 ethPaid);
    event RevenueSplit(uint256 toReward, uint256 toTreasury, uint256 toOps);
    event RewardPaid(address indexed winner, uint256 amount);
    event TreasuryWithdrawn(address indexed to, uint256 amount);
    event OperationsWithdrawn(address indexed to, uint256 amount);
    event GameStatusChanged(bool active);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sadece sahip yapabilir");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function buyAmmo() external payable {
        require(gameActive, "Oyun aktif degil");
        require(msg.value > 0, "ETH gondermelisiniz");

        uint256 amount = msg.value / ammoPrice;
        require(amount > 0, "Yetersiz ETH - en az 1 paket aliniz");

        ammoBalance[msg.sender] += amount;
        totalAmmoSold += amount;

        uint256 toReward = (msg.value * rewardPct) / 100;
        uint256 toTreasury = (msg.value * treasuryPct) / 100;
        uint256 toOps = msg.value - toReward - toTreasury;

        rewardPool += toReward;
        treasury += toTreasury;
        operations += toOps;

        emit AmmoPurchased(msg.sender, amount, msg.value);
        emit RevenueSplit(toReward, toTreasury, toOps);
    }

    function payReward(address winner, uint256 amount) external onlyOwner {
        require(winner != address(0), "Gecersiz adres");
        require(amount <= rewardPool, "Havuzda yeterli ETH yok");

        rewardPool -= amount;
        (bool success, ) = payable(winner).call{value: amount}("");
        require(success, "Odeme basarisiz");

        emit RewardPaid(winner, amount);
    }

    function withdrawTreasury() external onlyOwner {
        uint256 amount = treasury;
        require(amount > 0, "Cekilecek hazine yok");

        treasury = 0;
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Cekme basarisiz");

        emit TreasuryWithdrawn(owner, amount);
    }

    function withdrawOperations() external onlyOwner {
        uint256 amount = operations;
        require(amount > 0, "Cekilecek operasyon butcesi yok");

        operations = 0;
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Cekme basarisiz");

        emit OperationsWithdrawn(owner, amount);
    }

    function setGameActive(bool active) external onlyOwner {
        gameActive = active;
        emit GameStatusChanged(active);
    }

    function setPrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Fiyat sifir olamaz");
        ammoPrice = newPrice;
    }

    function getAmmo(address player) external view returns (uint256) {
        return ammoBalance[player];
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
