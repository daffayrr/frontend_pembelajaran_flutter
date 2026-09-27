# MISSION
Kamu adalah Expert Flutter Developer & UI/UX Specialist. Tugasmu adalah membuat alur lengkap fitur Kuis (Quiz) pada aplikasi "Gumregah Dongeng" yang terdiri dari 3 layar: Menu Kuis, Pengerjaan Kuis, dan Hasil Kuis. Desain harus sangat menarik, interaktif (gamified), namun tetap mengedepankan kenyamanan membaca (comfortable UX).

# TECHNICAL & API CONTEXT
- Base API URL: Sudah dikonfigurasi di `lib/constants/api.dart`.
- Warna Utama: `warnaTosca` (dari `lib/constants/colors.dart`).
- **Endpoint GET Soal:** `GET /api/quiz?level={level}` (Response berupa List of Object tanpa `kunci_jawaban`).
- **Endpoint POST Submit:** `POST /api/quiz/submit` (Menerima body JSON Array: `[{"soal_id": 1, "jawaban": "A"}]`). Response mengembalikan `skor_total`, `jumlah_benar`, `jumlah_salah`, dan array `koreksi`.

# REQUIRED SCREENS & UI SPECIFICATIONS

## 1. `lib/screens/quiz_screen.dart` (Menu / Lobby Kuis)
- **Fungsi:** Menampilkan pilihan level kuis (Asal Cerita, Nama Tokoh, Makna Cerita).
- **UI Design:** 
  - Gunakan `Scaffold` dengan background warna terang (`Color(0xFFF8F9FA)`).
  - AppBar simpel dan elegan.
  - Tampilkan *header card* atau ilustrasi menarik yang memotivasi pengguna (misal: "Uji Pengetahuanmu!").
  - Tampilkan 3 buah *Card* vertikal untuk masing-masing level. Setiap *card* memiliki ikon yang relevan, judul level, dan tombol "Mulai Kuis".
  - Saat tombol "Mulai Kuis" ditekan, navigasikan ke `QuizPlayScreen` dengan membawa parameter `level`.

## 2. `lib/screens/quiz_play_screen.dart` (Layar Pengerjaan Kuis)
- **Fungsi:** Mengambil data soal dari API berdasarkan level, dan menangani interaksi pengerjaan soal dengan *local state*.
- **UI Design:**
  - Tampilkan indikator *Loading* saat mengambil soal. Jika kosong, tampilkan *empty state* "Soal belum tersedia".
  - **Header:** Tampilkan `LinearProgressIndicator` di bagian atas untuk menunjukkan progres (misal: Soal 2 dari 10).
  - **Area Pertanyaan:** Letakkan teks pertanyaan di dalam wadah (Container) beraksen putih dengan *shadow* lembut, font tebal dan ukuran nyaman dibaca (minimal 16pt).
  - **Area Opsi Jawaban (A, B, C, D):** 
    - Buat dalam bentuk *List* atau *Column* dari *Card/Container* yang bisa di-tap.
    - Jika opsi belum dipilih, warna background putih dengan border abu-abu transparan.
    - **Interactive State:** Jika opsi DIPILIH oleh user, ubah warna background menjadi `warnaTosca.withOpacity(0.1)` dan berikan border/stroke berwarna `warnaTosca` agar jelas terlihat.
  - **Footer (Navigasi):**
    - Tombol "Sebelumnya" (jika bukan soal pertama) dan "Selanjutnya" (jika bukan soal terakhir).
    - Jika berada di soal terakhir, tombol "Selanjutnya" berubah menjadi "Selesai & Kumpulkan" (warna mencolok).
- **State Management:** Simpan jawaban user dalam `Map<int, String> answers` (contoh: `{ id_soal: 'A' }`).
- **Submit Action:** Saat "Selesai" ditekan, munculkan konfirmasi dialog. Jika *Yes*, ubah *Map* jawaban menjadi JSON Array, lakukan HTTP POST ke `/api/quiz/submit`, lalu `Navigator.pushReplacement` ke `QuizResultScreen` membawa data response JSON. Tampilkan *loading overlay* saat menembak API.

## 3. `lib/screens/quiz_result_screen.dart` (Layar Hasil Kuis)
- **Fungsi:** Menampilkan skor akhir dan evaluasi/koreksi jawaban.
- **UI Design:**
  - **Area Skor (Header):** Tampilkan `CircularProgressIndicator` besar atau desain melingkar di tengah layar yang menunjukkan `skor_total`. Beri warna hijau jika skor > 70, merah/oranye jika di bawahnya. Tampilkan teks ucapan selamat atau semangat.
  - **Area Ringkasan:** Tampilkan *Row* berisi *Badge/Chip* untuk `jumlah_benar` dan `jumlah_salah`.
  - **Area Koreksi (List):**
    - Render *ListView* dari array `koreksi`.
    - Tiap item menampilkan nomor/ID soal (opsional), teks tebal "Jawabanmu: X" dan "Jawaban Benar: Y".
    - Beri indikator ikon Centang Hijau (jika benar) atau Silang Merah (jika salah) di tiap item *card* koreksi.
  - **Footer:** Tombol "Kembali ke Beranda" (kembali ke menu utama/dashboard).

# EXECUTION
Buatkan kode lengkap untuk ketiga file tersebut (`quiz_screen.dart`, `quiz_play_screen.dart`, dan `quiz_result_screen.dart`). Pastikan kode rapi, *null-safe*, menangani *error handling* HTTP dengan baik, dan langsung bisa di-*build*. Gunakan nama kelas dan properti sesuai standar Flutter.

Jika sudah selesai menulis, langsung lakukan build APK Release