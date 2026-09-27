# MISSION
Kamu adalah Expert Flutter Developer & Senior UI/UX Designer. Tugasmu adalah merombak halaman "Koleksi Favorit" (`lib/screens/bookmark_screen.dart` atau nama file yang sesuai) menjadi desain *list* vertikal yang premium dan modern. Kamu juga harus membuat *Empty State* yang interaktif ketika koleksi masih kosong, lalu berikan instruksi untuk melakukan *build release* APK.

# GLOBAL DESIGN SYSTEM
- **Background:** Putih bersih (`Colors.white`).
- **Warna Aksen:** Tosca (`#00B4C0`).
- **Radius & Shadow:** Radius 16px untuk gambar/card, bayangan lembut untuk komponen *Empty State*.

# UI/UX ARCHITECTURE

## 1. Custom AppBar (Header)
- Gunakan `AppBar` dengan `elevation: 0`, warna latar putih.
- **Kiri:** Tombol *back* standar.
- **Tengah:** `Column` rata kiri berisi "Koleksi Favorit" (bold, hitam) dan "Dongeng yang sudah kamu simpan" (abu-abu, kecil).
- **Kanan:** `Row` berisi ikon Search dan ikon Filter/Sort, masing-masing dengan padding yang cukup.

## 2. Filter Chips (Kategori)
- Di bawah AppBar, letakkan `SizedBox` horizontal berisi `ListView`.
- Daftar kategori: "Semua", "Fabel", "Legenda", "Cerita Rakyat", "Petualangan".
- **Chip Aktif:** Latar Tosca, teks putih, *rounded* (radius 20).
- **Chip Inaktif:** Latar putih, teks abu-abu, tanpa border tegas atau hanya garis tipis `Colors.grey.shade200`.

## 3. State 1: Ada Data (List Item Design)
- Gunakan `ListView.builder` dengan *padding* horizontal 16px.
- **Desain Item (Bukan Card, tapi Row dalam Container):**
  - Bungkus dalam `Container` dengan border tipis abu-abu sangat muda dan margin bawah 12px.
  - **Kiri (Gambar):** `ClipRRect` ukuran sekitar 80x80px. Di atas gambar ada *Stack*:
    - *Badge* kategori (misal "Fabel") di pojok kiri atas (latar Tosca transparan).
    - Ikon *Bookmark* (putih) di pojok kanan atas gambar.
  - **Tengah (Teks):** `Expanded` Column.
    - Judul Dongeng (Bold, maksimal 2 baris).
    - Kategori Dongeng (Abu-abu, ukuran kecil).
    - `Row` berisi Rating (Bintang + 4.8) dan Durasi (Jam + 5 mnt).
  - **Kanan (Aksi):** Ikon Tong Sampah (*Delete*) warna abu-abu. Jika ditekan, muncul dialog konfirmasi hapus.

## 4. State 2: Kosong (Empty State)
- Buat fungsi atau *widget* khusus jika `koleksiList.isEmpty`.
- Tempatkan di tengah layar (`Center`).
- **Desain Empty State:**
  - `Container` dengan latar warna Tosca sangat pudar (opacity 0.05), ber-border garis putus-putus atau *shadow* super tipis.
  - Ikon buku terbuka (warna Tosca) di bagian atas.
  - Teks utama: "Belum ada dongeng favorit." (Bold, hitam).
  - Teks deskripsi: "Mulai jelajahi dan simpan dongeng yang kamu suka!" (Abu-abu, *center alignment*).
  - Tombol "Jelajahi Dongeng": `ElevatedButton` warna Tosca, ikon kompas/explore, yang akan menavigasikan user kembali ke tab Jelajah atau Dashboard.

# EXECUTION INSTRUCTIONS
1. Berikan kode Flutter lengkap untuk halaman Koleksi Favorit ini yang meng-handle percabangan antara `State 1` (ada isi) dan `State 2` (kosong).
2. Setelah kode selesai, berikan instruksi terminal singkat untuk melakukan kompilasi (build) aplikasi menjadi APK *Release* yang siap didistribusikan.