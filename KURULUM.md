# ABSWAR — Küresel Savaş MMO

Web3 tabanlı, gerçek zamanlı, çok oyunculu savaş oyunu.
Cyberpunk arayüz · 119 ülkeli dünya haritası · Smart contract ekonomisi.

═══════════════════════════════════════════════════════════
## PAKET İÇERİĞİ
═══════════════════════════════════════════════════════════

  frontend/
    index.html      → Tüm oyun arayüzü (tek dosya)
    vercel.json     → Vercel deploy ayarı

  backend/
    server.js       → Realtime savaş motoru (Node.js + Socket.io)

  smart-contract/
    AbswarGameV2.sol → Ekonomi contract'ı (zaten deploy edildi)

═══════════════════════════════════════════════════════════
## CANLI ADRESLER
═══════════════════════════════════════════════════════════

  Frontend  : https://abswar-ui.vercel.app
  Backend   : https://abswar-clean-backend-production.up.railway.app
  Contract  : 0x325b18816734210e9fEbAA0516030A8Ec74bE3d4
              (Abstract Testnet — Chain ID 11124)

═══════════════════════════════════════════════════════════
## KURULUM / GÜNCELLEME
═══════════════════════════════════════════════════════════

### 1. Frontend (Vercel)
  - GitHub'da `abswar-ui` reposunu aç
  - `frontend/index.html` dosyasını repodakiyle değiştir
  - Vercel otomatik deploy eder (1-2 dk)

### 2. Backend (Railway)
  - GitHub'da `abswar-clean-backend` reposunu aç
  - `backend/server.js` dosyasını repodakiyle değiştir
  - Railway otomatik deploy eder (1-2 dk)

### 3. Smart Contract
  - Zaten deploy edildi, bir şey yapmana gerek yok.
  - Yeniden deploy gerekirse: Remix IDE → AbswarGameV2.sol → Abstract Testnet

═══════════════════════════════════════════════════════════
## ÇALIŞAN SİSTEMLER
═══════════════════════════════════════════════════════════

  [✓] 119 ülkeli gerçek coğrafi dünya haritası
  [✓] MetaMask cüzdan bağlama
  [✓] Ülke seçme (arama özellikli modal)
  [✓] Saldırı sistemi — gerçek zamanlı HP düşürme
  [✓] Smart contract'a bağlı mermi satın alma
  [✓] İttifak kurma / katılma / telsiz komutları
  [✓] İttifak sohbeti
  [✓] Radar sistemi (yükseltilebilir, 3→10 seviye)
  [✓] Kaynak kontrolü (tıklanabilir, canlı dalgalanan)
  [✓] Üst menü sekmeleri (panel odaklama)
  [✓] Leaderboard — canlı ülke sıralaması
  [✓] WebSocket gerçek zamanlı senkronizasyon
  [✓] Sinematik harita efektleri (radar tarama, yıldızlar,
      saldırı dalgaları, parlayan füze izleri)

### Mermi Fiyatları
  Temel     : 0.001 ETH →    100 mermi
  Gelişmiş  : 0.01 ETH  →  1.000 mermi
  Prim      : 0.1 ETH   → 10.000 mermi
  Efsanevi  : 1.0 ETH   → 100.000 mermi

### Gelir Bölüşümü (contract otomatik)
  %70 → Ödül havuzu
  %20 → Hazine
  %10 → Operasyon

═══════════════════════════════════════════════════════════
## ÖNEMLİ NOTLAR
═══════════════════════════════════════════════════════════

  • Smart contract ŞU AN TEST AĞINDA (Abstract Testnet).
    Gerçek para yok, test ETH ile çalışıyor.

  • Backend verileri bellekte tutuluyor — Railway yeniden
    başlarsa oyun durumu sıfırlanır. Kalıcı veri için
    ileride PostgreSQL eklenebilir.

  • Mainnet'e geçmeden önce smart contract'ın bağımsız
    denetimden (audit) geçirilmesi önerilir.

═══════════════════════════════════════════════════════════
## SONRAKİ ADIMLAR (opsiyonel)
═══════════════════════════════════════════════════════════

  1. Test — oyunu arkadaşlarınla dene, geri bildirim topla
  2. Kalıcı veritabanı — PostgreSQL entegrasyonu
  3. Smart contract audit — mainnet öncesi güvenlik denetimi
  4. Mainnet deploy — testte kanıtlandıktan sonra

═══════════════════════════════════════════════════════════

ABSWAR v1.0 — Tüm sistemler çalışır durumda.
