# Dokumentasi Perbaikan Fitur Rating Materi (Bug Silent Failure)

Bug *silent failure* pada *endpoint* `POST /api/materi/rating` telah berhasil diidentifikasi dan diselesaikan. Sebelumnya, API merespons `200 OK` meskipun data gagal masuk (misal: akibat *Foreign Key Constraint*, tipe data tidak valid, atau kesalahan Query Builder saat operasi `insert`). 

Berikut ini adalah laporan perombakan *Controller* dan panduan penggunaannya:

---

## 1. Perubahan Logika Backend (`RatingController.php`)

1. **Implementasi Try-Catch:**
   Seluruh blok pemrosesan sekarang dibungkus dalam blok `try-catch`. Jika ada gangguan pada sistem database, API akan otomatis memberikan HTTP `500 Internal Server Error` (bukan 200).
2. **Strict Data Casting (Type Juggling):**
   Mencegah *error* dari Flutter yang terkadang mengirim nilai `user_id` atau `materi_id` sebagai `String`. Data JSON di-parsing secara paksa (Casting) menjadi `(int)` sebelum berhadapan dengan *database*.
3. **Validasi Query Builder:**
   Sebelumnya, *query builder* CI4 menelan *error* (gagal insert) secara diam-diam. Kini, kami menangkap nilai kembali (return value) `insert()` dan `update()`. Jika menghasilkan `false`, metode `errors()` dipanggil untuk mencetak akar masalah (misal: *Foreign Key Fails*) ke dalam *exception*.

---

## 2. API Endpoint Info

**Endpoint:** `POST /api/materi/rating`  
**Headers:** 
- `Content-Type: application/json`
- `Authorization: Bearer T0sc4Fl0w_S3cr3t_2026`

**Request Body (JSON):**
```json
{
    "user_id": 1,
    "materi_id": 3,
    "rating": 5
}
```

**Response Sukses (Insert) (200 OK):**
```json
{
    "status": 200,
    "message": "Rating berhasil ditambahkan"
}
```

**Response Sukses (Update) (200 OK):**
```json
{
    "status": 200,
    "message": "Rating berhasil diperbarui"
}
```

**Response Gagal (Materi tidak ditemukan/Data salah) (500/400):**
```json
{
    "status": 500,
    "message": "Internal Server Error: Gagal menambahkan rating: {\"CodeIgniter\\\\Database\\\\MySQLi\\\\Connection\":\"Cannot add or update a child row: a foreign key constraint fails...\"}"
}
```

---

## 3. Hasil Uji Coba

API telah diuji-coba secara *End-to-End* pada domain produksi (`https://api-service.toscaflow.id`).
1. **Pengujian Update:** Ketika `user_id = 1` dan `materi_id = 3` (yang mana data tersebut eksis), operasi pembaruan (Upsert) berhasil mengembalikan respon *"Rating berhasil diperbarui"*.
2. **Pengujian Constraint:** Ketika `user_id = 1` dan `materi_id = 1` (yang mana ID 1 sudah tidak ada di tabel `materi`), API secara jujur memblokir transaksi dan mengembalikan respon error 500 lengkap dengan deskripsi *Foreign Key*. Tidak ada lagi "kebohongan" *200 OK*.

Tim *Frontend* dapat segera menguji pengiriman *rating* secara langsung!
