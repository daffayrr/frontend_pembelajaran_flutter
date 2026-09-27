import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';
import 'package:frontend_pembelajaran_flutter/screens/quiz_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizPlayScreen extends StatefulWidget {
  final String level;
  final String title;

  const QuizPlayScreen({super.key, required this.level, required this.title});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  List<dynamic> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentIndex = 0;
  
  // key: soal_id, value: jawaban
  final Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    setState(() => _isLoading = true);
    try {
      final String encodedLevel = Uri.encodeComponent(widget.level);
      final response = await http.get(
        Uri.parse('$endpointQuiz?level=$encodedLevel'),
        headers: {
          'Authorization': staticAuthToken,
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        List<dynamic> soalList = [];
        
        if (decodedData is Map<String, dynamic>) {
          if (decodedData.containsKey('data') && decodedData['data'] is List) {
            soalList = decodedData['data'];
          } else {
            soalList = [decodedData];
          }
        } else if (decodedData is List) {
          soalList = decodedData;
        } else {
          throw Exception("Format JSON tidak sesuai (Bukan List)");
        }

        setState(() {
          _questions = soalList;
          _isLoading = false;
        });
      } else {
        throw Exception("Gagal mengambil data. Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error Kuis: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _selectOption(String questionId, String optionValue) {
    setState(() {
      _answers[questionId] = optionValue;
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _submitQuiz() async {
    // Tampilkan dialog konfirmasi
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kumpulkan Kuis?'),
        content: const Text('Apakah kamu yakin semua jawaban sudah benar?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: warnaTosca),
            child: const Text('Ya, Kumpulkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = int.parse(prefs.getString('user_id') ?? '0');

      Map<String, dynamic> payload = {
        "user_id": userId,
        "level": widget.level,
        "jawaban": _answers.entries.map((e) => {
          "soal_id": e.key,
          "jawaban": e.value
        }).toList()
      };

      final response = await http.post(
        Uri.parse(endpointQuizSubmit),
        headers: {
          'Authorization': staticAuthToken,
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => QuizResultScreen(resultData: data),
            ),
          );
        }
      } else {
        setState(() => _isSubmitting = false);
        _showError('Gagal mengirim jawaban');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: warnaTosca),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: warnaTosca));
    }

    if (_questions.isEmpty) {
      return const Center(
        child: Text(
          'Soal belum tersedia',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final String questionId = question['id'].toString();
    
    // Asumsi opsi dari API: opsi_a, opsi_b, opsi_c, opsi_d
    final options = {
      'A': question['opsi_a'] ?? '',
      'B': question['opsi_b'] ?? '',
      'C': question['opsi_c'] ?? '',
      'D': question['opsi_d'] ?? '',
    };

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: Colors.grey[300],
          color: warnaTosca,
          minHeight: 6,
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Soal ${_currentIndex + 1} dari ${_questions.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 15),
                
                // Question Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    question['pertanyaan'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                
                // Options
                ...options.entries.map((entry) {
                  final key = entry.key;
                  final value = entry.value;
                  if (value.toString().isEmpty) return const SizedBox.shrink();
                  
                  final isSelected = _answers[questionId] == key;
                  
                  return GestureDetector(
                    onTap: () => _selectOption(questionId, key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isSelected ? warnaTosca.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? warnaTosca : Colors.grey.withOpacity(0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: isSelected ? warnaTosca : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                key,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 15,
                                color: isSelected ? Colors.black87 : Colors.black54,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        
        // Footer Navigation
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentIndex > 0)
                OutlinedButton(
                  onPressed: _prevQuestion,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[800],
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Sebelumnya'),
                )
              else
                const SizedBox.shrink(),
                
              if (_currentIndex < _questions.length - 1)
                ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaTosca,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Selanjutnya', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                ElevatedButton(
                  onPressed: _submitQuiz,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Selesai & Kumpulkan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
