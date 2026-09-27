import 'package:flutter/material.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';

class QuizResultScreen extends StatelessWidget {
  final Map<String, dynamic> resultData;

  const QuizResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context) {
    // Parse sebagai double dulu untuk mengakomodasi angka desimal dari backend, lalu bulatkan.
    final double rawSkor = double.tryParse(resultData['skor_total']?.toString() ?? '0') ?? 0.0;
    final int skorTotal = rawSkor.round();
    final double rawBenar = double.tryParse(resultData['jumlah_benar']?.toString() ?? '0') ?? 0.0;
    final int jumlahBenar = rawBenar.round();
    final double rawSalah = double.tryParse(resultData['jumlah_salah']?.toString() ?? '0') ?? 0.0;
    final int jumlahSalah = rawSalah.round();

    // Pastikan koreksi berupa List. Jika null atau map, jadikan list kosong.
    final List<dynamic> koreksiList = (resultData['koreksi'] is List) ? resultData['koreksi'] : [];

    final bool isLulus = skorTotal >= 70;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Hasil Kuis'),
        automaticallyImplyLeading: false,
        backgroundColor: warnaTosca,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- SECTION SKOR ---
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isLulus ? '🎉 Luar Biasa!' : '💪 Tetap Semangat!',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
                  ),
                  const SizedBox(height: 15),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        height: 110,
                        child: CircularProgressIndicator(
                          value: skorTotal / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey[200],
                          color: isLulus ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        '$skorTotal',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: isLulus ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(Icons.check_circle_rounded, Colors.green, '$jumlahBenar Benar'),
                      const SizedBox(width: 15),
                      _buildBadge(Icons.cancel_rounded, Colors.red, '$jumlahSalah Salah'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- SECTION KOREKSI JAWABAN ---
            Expanded(
              child: koreksiList.isEmpty
                  ? const Center(
                      child: Text(
                        'Data evaluasi tidak tersedia.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: koreksiList.length,
                      itemBuilder: (context, index) {
                        final item = koreksiList[index];
                        if (item is! Map) return const SizedBox.shrink();

                        final String jawabanUser = item['jawaban_user']?.toString() ?? '-';
                        final String jawabanBenar = item['jawaban_benar']?.toString() ?? '-';
                        final String status = item['status']?.toString().toLowerCase() ?? 'salah';
                        final bool isBenar = status == 'benar';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isBenar ? Colors.green.shade200 : Colors.red.shade200),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isBenar ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              color: isBenar ? Colors.green : Colors.red,
                              size: 32,
                            ),
                            title: Text(
                              'Jawabanmu: $jawabanUser',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isBenar ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                            subtitle: isBenar
                                ? null
                                : Text(
                                    'Kunci: $jawabanBenar',
                                    style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                                  ),
                          ),
                        );
                      },
                    ),
            ),

            // --- SECTION TOMBOL KEMBALI ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaTosca,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
