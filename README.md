# 🍇 Blox Fruits Script Hub

Script lengkap untuk Blox Fruits dengan berbagai fitur auto farm, ESP, teleport, dan lainnya.

---

## 📋 Cara Pakai

### **Metode 1: Copy-Paste Langsung (Paling Mudah)**

1. **Buka file** `BloxFruits.lua`
2. **Copy semua isinya** (Ctrl + A, lalu Ctrl + C)
3. **Buka executor** Anda (Solara, Wave, Fluxus, dll)
4. **Paste** ke executor (Ctrl + V)
5. **Klik Execute**
6. **UI akan muncul**, tekan `RightShift` untuk buka/tutup

---

### **Metode 2: Loadstring dari GitHub (Lebih Praktis)**

#### **Langkah 1: Upload ke GitHub**

1. Buat akun GitHub (jika belum punya)
2. Buat repository baru (nama bebas, misal: `roblox-scripts`)
3. Upload file `BloxFruits.lua`
4. Klik file tersebut, lalu klik tombol **Raw**
5. Copy URL-nya (contoh: `https://raw.githubusercontent.com/username/repo/main/BloxFruits.lua`)

#### **Langkah 2: Buat Loadstring**

Paste kode ini ke executor Anda:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/BloxFruits.lua"))()
```

**Ganti `USERNAME/REPO`** dengan username dan nama repository Anda!

**Contoh:**
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/tezydner/bloxfruits/main/BloxFruits.lua"))()
```

---

### **Metode 3: Loadstring dari Pastebin (Alternatif)**

#### **Langkah 1: Upload ke Pastebin**

1. Buka [pastebin.com](https://pastebin.com)
2. Paste isi `BloxFruits.lua`
3. Klik **Create New Paste**
4. Klik tombol **Raw**, copy URL-nya

#### **Langkah 2: Buat Loadstring**

```lua
loadstring(game:HttpGet("https://pastebin.com/raw/PASTEID"))()
```

**Ganti `PASTEID`** dengan ID paste Anda!

**Contoh:**
```lua
loadstring(game:HttpGet("https://pastebin.com/raw/abc123XY"))()
```

---

## 🎮 Fitur-Fitur

### 🌾 **Auto Farm**
- ✅ Auto Farm Level (farm mob terdekat otomatis)
- ✅ Auto Quest (ambil quest otomatis)
- ✅ Auto Click / Auto Attack
- ✅ Fast Attack (serangan cepat tanpa cooldown)
- ✅ Atur jarak farm (5-30 studs)

### ⚔️ **Combat**
- ✅ Auto Skill (otomatis pakai Z, X, C, V)
- ✅ Equip Melee cepat
- ✅ Equip Devil Fruit cepat

### 👤 **Player Enhancement**
- ✅ Walk Speed (16-200)
- ✅ Jump Power (50-300)
- ✅ No Clip (tembus tembok)
- ✅ Anti-AFK (tidak akan di-kick server)
- ✅ Infinite Energy (experimental)

### 👁️ **ESP (Wallhack)**
- ✅ Mob ESP (lihat musuh + HP + jarak)
- ✅ Player ESP (lihat player lain)
- ✅ Devil Fruit ESP (cari buah langka)
- ✅ Chest ESP (cari peti treasure)

### 🌍 **Teleport**
- ✅ Teleport ke 20+ pulau:
  - **First Sea**: Starter Island, Jungle, Desert, Frozen Village, dll
  - **Second Sea**: Kingdom of Rose, Cafe, Mansion, dll
  - **Third Sea**: Port Town, Hydra Island, Great Tree, dll
- ✅ Quick TP ke mob terdekat
- ✅ TP ke spawn point

### ⚙️ **Misc**
- ✅ Auto Buy Melee
- ✅ Server Info (ping, jumlah player)
- ✅ Rejoin Server
- ✅ Server Hop (pindah ke server sepi)

---

## ⌨️ Keybinds

| Key | Function |
|-----|----------|
| **RightShift** | Toggle UI (buka/tutup menu) |
| **F** | Toggle Auto Farm on/off |

---

## 🚀 Tips & Trik

### **Untuk Farming Cepat:**
1. Enable: `Auto Farm` + `Auto Click` + `Fast Attack`
2. Enable: `Auto Quest` (ambil quest otomatis)
3. Atur `Walk Speed` ke 100-150
4. Atur `Farm Distance` ke 15 studs
5. Enable `Mob ESP` untuk monitoring

### **Untuk Explore Aman:**
1. Enable: `No Clip` + `Walk Speed` tinggi (150-200)
2. Enable: `Anti-AFK`
3. Gunakan fitur `Teleport` untuk berpindah pulau

### **Untuk Cari Devil Fruit:**
1. Enable: `Fruit ESP`
2. Keliling map atau gunakan `Teleport`
3. Jika tidak ada fruit, gunakan `Server Hop`

### **Untuk Combat:**
1. Equip weapon yang bagus
2. Enable: `Auto Skill` + `Fast Attack`
3. Enable: `Player ESP` untuk PvP

---

## ⚠️ Disclaimer

- **Gunakan dengan risiko Anda sendiri!**
- Script ini mungkin **terdeteksi** oleh anti-cheat Roblox
- **Jangan gunakan di akun utama** yang penting
- Buat akun alt untuk testing
- **Saya tidak bertanggung jawab** atas banned account

---

## 🐛 Troubleshooting

### **❌ Script tidak jalan?**
- Pastikan executor Anda support `loadstring`
- Coba restart Roblox dan executor
- Cek apakah ada error di console

### **❌ UI tidak muncul?**
- Tekan `RightShift` untuk toggle UI
- Coba execute ulang scriptnya

### **❌ Auto Farm tidak attack?**
- Pastikan Anda sudah equip weapon (melee/sword)
- Enable `Auto Click`
- Pastikan ada mob di sekitar

### **❌ Teleport tidak jalan?**
- Pastikan Anda di sea yang benar (First/Second/Third Sea)
- Beberapa pulau hanya ada di sea tertentu

### **❌ ESP tidak muncul?**
- Tunggu 1-2 detik setelah enable
- Script perlu waktu untuk scan map

---

## 📝 Changelog

### **v1.0 (Current)**
- ✅ Initial release
- ✅ Auto Farm system
- ✅ ESP system (Mob, Player, Fruit, Chest)
- ✅ Teleport ke 20+ pulau
- ✅ Combat features
- ✅ Player enhancement
- ✅ Misc features

---

## 👨‍💻 Credits

**Created by:** Tezydner  
**UI Library:** Rayfield  
**Game:** Blox Fruits (Roblox)

---

## 📞 Support

Jika ada bug atau request fitur, silahkan hubungi saya atau buat issue di GitHub.

**Enjoy the script! 🍇**
