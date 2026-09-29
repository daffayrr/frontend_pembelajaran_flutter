# MISSION
Kamu adalah Expert Flutter Developer. Tim Backend telah merombak total arsitektur aplikasi untuk mengamankan stabilitas server, memindahkan sistem *upload* menjadi **Direct-to-S3 via Pre-signed URL**, serta memperbaiki *silent failure* pada sistem Rating. 

Tugasmu adalah merombak keseluruhan kode *frontend* Flutter agar terintegrasi sempurna dengan arsitektur backend terbaru.

# REFERENCE DOCUMENTS
Kamu WAJIB membaca dan mematuhi dokumentasi API terbaru yang telah disiapkan di dalam folder root project:
1. `acuan/UPDATE.md` (Untuk arsitektur Direct-to-S3 Foto Profil & Materi)
2. `acuan/UPDATE_RATING.md` (Untuk perbaikan sistem Rating)

# PRE-EXECUTION COMMANDS
Sebelum mengubah kode, lakukan pembersihan ruang kerja untuk menghindari masalah *cache*:
1. Jalankan `flutter clean` di terminal.
2. Jalankan `flutter pub get` untuk menginstal ulang semua dependensi.
3. **PENTING:** JANGAN melakukan *build* APK atau *release* dulu setelah kode selesai. Fokus pada perbaikan kode sumber saja.

# EXECUTION INSTRUCTIONS: FLUTTER REFACTORING

## 1. Refactor Fitur Upload Foto Profil (`lib/screens/profile_screen.dart` atau `edit_profile_screen.dart`)
Ganti logika `MultipartRequest` lama dengan metode *Direct-to-S3* sesuai `UPDATE_2.md`:
- **Generate URL:** Lakukan POST ke `/api/user/profil/generate-url/{id}` dengan JSON body berisi `extension` dan `content_type` gambar.
- **Direct Upload S3:** Gunakan `http.put` langsung ke `upload_url` yang didapat. Kirim byte gambar (`readAsBytes()`) murni di body, bukan multipart. Wajib set header `'Content-Type'` persis seperti saat generate.
- **Confirm:** Setelah PUT sukses (status 200), POST ke `/api/user/profil/confirm/{id}` dengan JSON body `file_key`. Update state UI `CircleAvatar` dengan URL final dari respons.

## 2. Refactor Fitur Upload Materi (`lib/screens/tambah_materi_screen.dart`)
Rombak halaman Tambah Materi untuk PDF dan Sampul sesuai `UPDATE_2.md`:
- Hapus penggunaan `MultipartRequest` ke CodeIgniter.
- Buat fungsi *helper* asinkron untuk mengunggah file satu per satu (PDF lalu Cover) menggunakan alur: POST Generate URL -> PUT S3 -> Return `file_key`.
- Setelah semua file fisik berhasil masuk ke S3, kirim data teks final (Judul, Sinopsis, `file_materi`, `file_sampul`) ke POST `/api/materi` dengan tipe `application/json`.

## 3. Refactor Sistem Rating (`lib/screens/detail_materi_screen.dart` atau terkait)
Perbaiki integrasi fitur rating sesuai panduan `UPDATE_RATING.md`:
- **Strict Casting:** Pastikan payload yang dikirim (`user_id`, `materi_id`, `rating`) di-parsing dengan ketat menggunakan `int.parse()` atau bertipe `int` sebelum di-`jsonEncode`. Jangan kirim *String*.
- **Error Handling:** Backend sekarang akan melemparkan status 500/400 jika *database* menolak (tidak lagi memalsukan 200 OK). Tangkap status ini dan tampilkan `ScaffoldMessenger` (SnackBar) error berwarna merah jika gagal.
- **State Refresh:** Jika HTTP response merespons 200 OK (berhasil), kamu WAJIB memanggil kembali fungsi `fetchMateriRating()` (atau yang setara) dan melakukan `setState()` agar bintang dan angka rata-rata di layar HP pengguna langsung berubah detik itu juga tanpa perlu memuat ulang halaman.

# STRICT CONSTRAINTS
- Setiap *request* ke API Backend CI4 (bukan ke S3) WAJIB menggunakan header:
  `'Content-Type': 'application/json'`
  `'Authorization': 'Bearer T0sc4Fl0w_S3cr3t_2026'`
- Tampilkan `CircularProgressIndicator` yang memblokir layar selama proses *upload* agar pengguna tidak menekan tombol dua kali.

# PERUBAHAN ICON
1. Pastikan *package* `flutter_launcher_icons` sudah ada di `dev_dependencies` dalam file `pubspec.yaml`. Jika belum, tambahkan.
2. Tambahkan atau perbarui blok konfigurasi berikut di bagian bawah `pubspec.yaml` (pastikan *path* mengarah ke file logo/ikon yang benar di folder assets):
3. Buka terminal internal, lalu eksekusi *command* ini untuk men-generate semua aset ikon iOS dan Android secara otomatis:
   `dart run flutter_launcher_icons`

Tuliskan/update file-file Dart tersebut sekarang dan berikan konfirmasi log jika sudah selesai!

# REMINDER
Jangan pernah lakukan build dan release dahulu!