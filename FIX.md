# MISSION
Kamu adalah Expert Flutter Developer & Senior UI/UX Designer. Saya memiliki serangkaian perbaikan UI besar-besaran untuk menyempurnakan aplikasi "Gumregah Dongeng". 

**⚠️ INSTRUKSI KRUSIAL:**
**JANGAN TULIS KODE ATAU EKSEKUSI PERBAIKAN INI DULU!** 
Tugasmu saat ini HANYA membaca, memahami, menganalisis struktur yang diminta, dan membalas dengan "SIAP DIEKSEKUSI. SILAKAN BERIKAN PERINTAH MULAI" beserta ringkasan singkat rencanamu.

# TASKS TO ANALYZE

## 1. Perbaikan System UI Overlay (Status Bar Putih)
- **Masalah:** Warna jam, baterai, dan sinyal di *status bar* HP saat ini berwarna putih, bertabrakan dengan *background* AppBar aplikasi yang juga putih.
- **Solusi:** Terapkan `SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark)` secara global atau atur `systemOverlayStyle: SystemUiOverlayStyle.dark` pada setiap `AppBar` yang berwarna putih. Ikon status bar HARUS menjadi hitam/gelap.

## 2. Redesign Halaman Detail Cerita / Ebook
- **Konsep:** Gaya sinopsis premium ala Netflix/Apple Books.
- **Header:** `AppBar` transparan/putih dengan tombol Back. **Hapus** tombol Like/Share jika ada (tidak diperlukan).
- **Hero Image (Thumbnail):** 
  - Letakkan *cover* buku di tengah atas.
  - Gunakan proporsi potret/buku, berikan `ClipRRect` (radius 12), dan berikan *drop shadow* tebal namun lembut agar buku terlihat menonjol (3D effect).
- **Info Singkat:** Judul cerita (Besar, Bold), Nama Penulis/Kategori di bawahnya (Abu-abu).
- **Stats Row:** Buat barisan informasi menggunakan kotak/container kecil berjejer mendatar (misal: Rating, Durasi, Kategori Umur) dengan warna latar Tosca sangat pudar.
- **Action Buttons:** Sesuaikan dengan tombol yang sudah ada (misal: "Mulai Membaca" atau "Kerjakan Kuis"). Gunakan desain *stadium border* berwarna Tosca, teks putih, ikon di sebelah kiri.
- **Sinopsis & Komentar:** 
  - Teks sinopsis rapi dengan opsi "Baca Selengkapnya".
  - Di bawahnya, letakkan komponen **Komentar** yang sudah ada sebelumnya.

## 3. Sinkronisasi Tombol Filter di Halaman Favorit
- **Masalah:** Desain tombol filter (Semua, Fabel, Legenda, dll) di halaman "Koleksi Favorit" berbeda dengan yang ada di halaman "Jelajahi Dongeng".
- **Solusi:** Samakan 100% komponen `ChoiceChip` (baik *style* chip aktif yang berwarna Tosca maupun chip inaktif) di `bookmark_screen.dart` agar identik dengan yang ada di `daftar_cerita_screen.dart`.

## 4. Pembersihan Search Bar
- **Masalah:** Ada ikon filter (suffix icon) di dalam kolom pencarian yang tidak diperlukan.
- **Solusi:** Hapus ikon filter/slider tersebut dari *widget* Search Bar di Halaman Jelajah dan Halaman Favorit. Cukup ikon kaca pembesar (*search*) di sebelah kiri dan teks *placeholder*.

# REMINDER
Pahami baik-baik keempat poin di atas. Jawab HANYA dengan konfirmasi bahwa kamu mengerti dan siap mengeksekusi satu per satu saat saya beri aba-aba.
Jangan dilakukan build dahulu sebelum diperintahkan!