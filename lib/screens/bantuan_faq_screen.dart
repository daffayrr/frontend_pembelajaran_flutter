import 'package:flutter/material.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class BantuanFaqScreen extends StatelessWidget {
  const BantuanFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List faqs = [
      {
        'tanya': 'Bagaimana cara menyimpan materi ke favorit?',
        'jawab':
            'Buka detail materi yang kamu inginkan, lalu klik ikon pita (bookmark) di pojok kanan atas layar.',
      },
      {
        'tanya': 'Di mana letak file PDF yang sudah diunduh?',
        'jawab':
            'File PDF akan tersimpan secara otomatis di dalam folder Download pada penyimpanan internal HP kamu.',
      },
      {
        'tanya': 'Mengapa saya tidak bisa menulis cerita?',
        'jawab':
            'Fitur menulis cerita eksklusif untuk member terdaftar. Silakan buat akun dan login terlebih dahulu.',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Bantuan & FAQ',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFF8F9FA),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Topik Populer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          ...faqs.map(
            (faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.black12),
              ),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  iconColor: warnaTosca,
                  collapsedIconColor: Colors.grey,
                  title: Text(
                    faq['tanya'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                      child: Text(
                        faq['jawab'],
                        style: TextStyle(color: Colors.grey[700], height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: warnaTosca.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.support_agent_rounded,
                  size: 50,
                  color: warnaTosca,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Butuh Bantuan Lain?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Tim kami siap membantu Anda kapan saja.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaTosca,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Hubungi Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
