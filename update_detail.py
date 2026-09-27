import re

with open('lib/screens/detail_materi_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import 'package:flutter_rating_bar/flutter_rating_bar.dart';\n"
if import_stmt not in content:
    content = content.replace("import 'package:http/http.dart' as http;", "import 'package:http/http.dart' as http;\n" + import_stmt)

state_vars = '''  double _ratingRataRata = 0.0;
  int _totalReviewer = 0;
  bool _isSubmittingRating = false;

'''
content = content.replace('  // --- STATE KOMENTAR ---', state_vars + '  // --- STATE KOMENTAR ---')

content = content.replace('_fetchKomentar();', '_fetchKomentar();\n    _fetchRating();')

methods = '''
  Future<void> _fetchRating() async {
    try {
      final response = await http.get(
        Uri.parse('https://api-service.toscaflow.id/api/materi/rating/'),
        headers: {'Authorization': staticAuthToken},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _ratingRataRata = double.tryParse(data["rating_rata_rata"].toString()) ?? 0.0;
            _totalReviewer = int.tryParse(data["total_reviewer"].toString()) ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch rating: ');
    }
  }

  Future<void> _submitRating(double rating) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login untuk memberi rating')));
      return;
    }
    setState(() => _isSubmittingRating = true);
    try {
      final response = await http.post(
        Uri.parse('https://api-service.toscaflow.id/api/materi/rating'),
        headers: {
          'Authorization': staticAuthToken,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': currentUserId,
          'materi_id': widget.materi["id"],
          'rating': rating,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terima kasih atas penilaian Anda!'), backgroundColor: Colors.green));
          _fetchRating();
        }
      }
    } catch (e) {
      debugPrint('Error submit rating: ');
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }
'''
content = content.replace('  Future<void> _fetchKomentar() async {', methods.replace('\"', '\\\'') + '\n  Future<void> _fetchKomentar() async {')

hero_target = '''                          Text(
                            widget.materi['kategori_nama'] ?? 'Kategori',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),'''

rating_display_ui = '''                          Text(
                            widget.materi['kategori_nama'] ?? 'Kategori',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                _ratingRataRata > 0 ? _ratingRataRata.toStringAsFixed(1) : '-',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '()',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                              ),
                            ],
                          ),'''
content = content.replace(hero_target, rating_display_ui)

sinopsis_target = '''                    const SizedBox(height: 30),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 20),

                    // 4. Komentar'''

submit_rating_ui = '''                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: warnaTosca.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: warnaTosca.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          const Text('Beri nilai cerita ini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 12),
                          _isSubmittingRating
                              ? const CircularProgressIndicator(color: warnaTosca)
                              : RatingBar.builder(
                                  initialRating: 0,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                                  onRatingUpdate: (rating) {
                                    _submitRating(rating);
                                  },
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade200, thickness: 1),
                    const SizedBox(height: 20),

                    // 4. Komentar'''
content = content.replace(sinopsis_target, submit_rating_ui)

with open('lib/screens/detail_materi_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
