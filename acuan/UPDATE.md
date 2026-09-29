# Dokumentasi Arsitektur Upload Direct-to-S3 (S3 Pre-signed URL)

Dokumen ini memuat perubahan arsitektur pengunggahan file dari yang sebelumnya berbasis `multipart/form-data` melalui Backend CodeIgniter 4, menjadi **Direct Upload ke S3** menggunakan S3 Pre-signed URL. Ini mencegah *crash* pada server (terutama IIS) ketika meng-handle file besar.

---

## 1. Konsep Dasar & Langkah untuk Flutter

1. **Request URL (POST):** Flutter meminta izin (URL) untuk mengunggah file ke suatu *endpoint* di Backend CI4 dengan mengirimkan ekstensi file dan MIME type.
2. **Terima URL:** Backend CI4 mengembalikan `upload_url` (berlaku 15-60 menit) dan `file_key`.
3. **Upload (PUT):** Flutter melakukan HTTP `PUT` **langsung** ke `upload_url` tersebut dengan melampirkan file biner. **Penting:** Header `Content-Type` pada proses PUT ini harus persis sama dengan yang dikirimkan ke CI4 pada langkah 1.
4. **Konfirmasi (POST):** Setelah proses `PUT` ke S3 berhasil (mengembalikan status 200), Flutter memberi tahu Backend bahwa file sudah terunggah dengan mengirimkan referensi `file_key` untuk disimpan di Database.

---

## 2. Implementasi Kode di Flutter (Dart)

Berikut adalah *blueprint* fungsi di Flutter untuk melakukan pengunggahan *Direct-to-S3*:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

Future<void> uploadFotoProfil(File imageFile, int userId) async {
  String extension = path.extension(imageFile.path).replaceAll('.', '');
  // Sesuaikan tipe MIME dengan ekstensinya
  String mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
  
  // ---------------------------------------------------------
  // TAHAP 1: MINTA URL UPLOAD KE BACKEND
  // ---------------------------------------------------------
  var genUrlResponse = await http.post(
    Uri.parse('https://api-service.toscaflow.id/api/user/profil/generate-url/$userId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer T0sc4Fl0w_S3cr3t_2026',
    },
    body: jsonEncode({
      "extension": extension,
      "content_type": mimeType
    }),
  );

  if (genUrlResponse.statusCode != 200) {
    print('Gagal meminta URL upload dari Backend');
    return;
  }

  var genUrlData = jsonDecode(genUrlResponse.body);
  String uploadUrl = genUrlData['data']['upload_url'];
  String fileKey = genUrlData['data']['file_key'];

  // ---------------------------------------------------------
  // TAHAP 2: DIRECT UPLOAD KE S3 (TANPA MULTIPART)
  // ---------------------------------------------------------
  // BACA FILE SEBAGAI BINARY
  List<int> imageBytes = await imageFile.readAsBytes();
  
  var s3Response = await http.put(
    Uri.parse(uploadUrl),
    headers: {
      'Content-Type': mimeType, // WAJIB SAMA DENGAN TAHAP 1
    },
    body: imageBytes, // KIRIM BYTE LANGSUNG, BUKAN MULTIPART
  );

  if (s3Response.statusCode != 200) {
    print('Gagal mengunggah file ke S3');
    return;
  }

  // ---------------------------------------------------------
  // TAHAP 3: KONFIRMASI KE BACKEND
  // ---------------------------------------------------------
  var confirmResponse = await http.post(
    Uri.parse('https://api-service.toscaflow.id/api/user/profil/confirm/$userId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer T0sc4Fl0w_S3cr3t_2026',
    },
    body: jsonEncode({
      "file_key": fileKey
    }),
  );

  if (confirmResponse.statusCode == 200) {
    print('Berhasil memperbarui foto profil!');
    // Tampilkan foto menggunakan url dari response konfirmasi
  }
}
```

---

## 3. Detail API Endpoint (Backend Reference)

### A. API Foto Profil User
- **Minta URL (`POST /api/user/profil/generate-url/{id}`)**
  - **Body (JSON):** `{"extension": "jpg", "content_type": "image/jpeg"}`
  - **Response:** Mendapatkan `upload_url` dan `file_key`.
- **Konfirmasi Upload (`POST /api/user/profil/confirm/{id}`)**
  - **Body (JSON):** `{"file_key": "foto_profil/user_1_17000000.jpg"}`
  - **Response:** Backend mengupdate database dan merespons dengan URL gambar permanen.

### B. API Materi (PDF / Video / Cerita)
Untuk materi, Flutter harus memanggil API Generate URL secara paralel/berurutan untuk PDF dan Cover.

- **Minta URL Materi (`POST /api/materi/generate-url`)**
  - **Body PDF:** `{"type": "pdf", "extension": "pdf", "content_type": "application/pdf"}`
  - **Body Cover:** `{"type": "cover", "extension": "png", "content_type": "image/png"}`
  - **Response:** Mendapatkan `upload_url` dan `file_key` masing-masing.

- **Simpan Data Materi Baru (`POST /api/materi`)**
  - Dipanggil **setelah** file PDF dan Cover berhasil diunggah via `http.put` ke S3.
  - **Body (JSON):**
    ```json
    {
        "judul": "Belajar Algoritma",
        "tipe": "pdf",
        "sinopsis": "Buku ini membahas tentang algoritma dasar.",
        "file_materi": "materi_pdf/materi_17000000.pdf",
        "file_sampul": "sampul/cover_17000000.png"
    }
    ```
  - **Catatan:** Jangan gunakan form-data / multipart. Pastikan Header adalah `application/json`. Backend hanya butuh parameter teks dan *file_key*.
