# MISSION
Kamu adalah Expert Flutter Developer & UI/UX Specialist. Tugasmu adalah merombak file `lib/screens/dashboard_screen.dart` untuk mengimplementasikan dynamic scrolling header (seperti aplikasi Gojek), mengganti menu pintasan, menyiapkan wadah untuk ikon semi-3D, dan membuat halaman kosong untuk Kuis.

# TECHNICAL REQUIREMENTS

## 1. Refactor `dashboard_screen.dart` (Dynamic Header & Layout)
- Ubah struktur utama `Scaffold` body dari `SingleChildScrollView` menjadi `CustomScrollView`.
- Gunakan `SliverAppBar` untuk membuat efek header dinamis:
  - `pinned: true`, `floating: false`.
  - Saat berada di posisi paling atas (expanded): Background berwarna transparan atau gradasi Tosca, teks/ikon warna putih.
  - Saat di-scroll ke bawah (collapsed): Background berubah menjadi Putih pekat, teks/ikon berubah menjadi hitam/gelap, dan muncul *elevation/shadow* tipis di bagian bawah header.
- **Isi Header (`title` / `flexibleSpace`):**
  - Terdapat Search Bar tiruan (membuka `SearchDelegate` saat di-tap) yang mendominasi area kiri.
  - Terdapat foto profil (CircleAvatar) di area kanan.
  - **TIDAK BOLEH** ada tombol "Ambil Star" atau elemen lain di dekat foto profil.

## 2. Menu Pintasan Utama (Grid/Row Menu)
- Tepat di bawah header (di dalam `SliverList` atau `SliverToBoxAdapter`), buat sebuah *section* menu yang terdiri dari 4 tombol berjejer rapi:
  1. Kuis (Navigasi ke `QuizScreen`)
  2. Favorit (Navigasi ke `BookmarkScreen`)
  3. Buku (Navigasi ke `DaftarCeritaScreen`)
  4. Tulis Cerita (Navigasi ke `BuatCeritaScreen`)
- **Desain Tombol:** Siapkan struktur UI yang menggunakan `Image.asset` (misal: `assets/icons/3d_quiz.png`, `assets/icons/3d_fav.png`, dst) dengan ukuran sekitar 45x45, bukan menggunakan `Icon()` bawaan Flutter. Berikan efek shadow lembut di bawah ikon agar nuansa semi-3D lebih terasa, diikuti teks label kecil di bawahnya.
- Berikan *fallback* berupa `Icon()` sementara jika gambar asset belum ditemukan (gunakan `errorBuilder`).

## 3. Pertahankan Konten Lama
- Konten slider horizontal untuk "Buku Dongeng Digital", "Video Dongeng", dan "Cerita Pilihan" yang sudah dirapikan jaraknya sebelumnya HARUS dipertahankan dan dimasukkan ke dalam susunan `SliverList` di bawah menu utama.

## 4. Buat File `lib/screens/quiz_screen.dart`
- Buat *StatefulWidget* kosong bernama `QuizScreen`.
- Isi dengan `Scaffold`, `AppBar` putih bertuliskan "Tantangan Kuis", dan body berupa ilustrasi/teks di tengah layar: "Halaman Kuis Sedang Disiapkan".

# EXECUTION
1. Berikan kode lengkap untuk `lib/screens/dashboard_screen.dart` menggunakan arsitektur `CustomScrollView`.
2. Berikan kode untuk `lib/screens/quiz_screen.dart`.
3. Pastikan manajemen state warna pada `SliverAppBar` berjalan mulus dengan mendengarkan perubahan posisi *scroll* (gunakan `ScrollController` dan `addListener`).