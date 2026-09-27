import 'package:flutter/material.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/screens/quiz_play_screen.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Tantangan Kuis',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [warnaTosca, warnaTosca.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: warnaTosca.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Uji Pengetahuanmu!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Pilih level kuis di bawah ini dan buktikan seberapa jauh kamu mengingat cerita yang sudah kamu baca.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 60,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            const Text(
              'Pilih Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 15),

            // Level Cards
            _buildLevelCard(
              context,
              title: 'Asal Cerita',
              subtitle: 'Tebak dari mana cerita dongeng berasal.',
              icon: Icons.map_rounded,
              color: Colors.blue,
              level: 'Asal cerita',
            ),
            _buildLevelCard(
              context,
              title: 'Nama Tokoh',
              subtitle: 'Uji ingatanmu tentang tokoh-tokoh penting.',
              icon: Icons.people_alt_rounded,
              color: Colors.purple,
              level: 'Nama tokoh',
            ),
            _buildLevelCard(
              context,
              title: 'Makna Cerita',
              subtitle: 'Apa pesan moral dari cerita-cerita tersebut?',
              icon: Icons.lightbulb_rounded,
              color: Colors.orange,
              level: 'Makna cerita',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String level,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPlayScreen(level: level, title: title),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: warnaTosca,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              ),
              child: const Text('Mulai', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
