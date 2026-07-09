import 'package:flutter/material.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy notifikasi
    final List notifikasi = [
      {
        'judul': 'Selamat Datang!',
        'pesan': 'Terima kasih telah bergabung di aplikasi kami.',
        'waktu': 'Baru saja',
        'ikon': Icons.celebration_rounded,
        'warna': Colors.orange,
      },
      {
        'judul': 'Materi Baru Tersedia',
        'pesan': 'Buku panduan terbaru sudah bisa kamu unduh.',
        'waktu': '2 jam yang lalu',
        'ikon': Icons.menu_book_rounded,
        'warna': Colors.blue,
      },
      {
        'judul': 'Pembaruan Sistem',
        'pesan': 'Kami telah meningkatkan kecepatan aplikasi.',
        'waktu': '1 hari yang lalu',
        'ikon': Icons.system_update_rounded,
        'warna': warnaTosca,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifikasi.length,
        itemBuilder: (context, index) {
          final item = notifikasi[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item['warna'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['ikon'], color: item['warna']),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['judul'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item['pesan'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['waktu'],
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
