import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_pembelajaran_flutter/screens/pdf_viewer_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/video_player_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/login_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';

class DownloadTracker {
  static final Map<int, ValueNotifier<double>> activeDownloads = {};
}

class DetailMateriScreen extends StatefulWidget {
  final dynamic materi;
  const DetailMateriScreen({super.key, required this.materi});

  @override
  State<DetailMateriScreen> createState() => _DetailMateriScreenState();
}

class _DetailMateriScreenState extends State<DetailMateriScreen> {
  bool isDownloaded = false;
  bool isDownloading = false;
  bool isBookmarked = false;
  bool isCheckingBookmark = true;
  String filePath = '';
  ValueNotifier<double>? downloadNotifier;

  // --- TAMBAHAN STATE KOMENTAR ---
  List listKomentar = [];
  bool isLoadingKomentar = true;
  bool isKirimKomentar = false;
  final TextEditingController _komentarController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkFileExists();
    _checkBookmarkStatusAPI();
    _fetchKomentar(); // Memicu pemuatan komentar

    int materiId = int.parse(widget.materi['id'].toString());
    if (DownloadTracker.activeDownloads.containsKey(materiId)) {
      isDownloading = true;
      downloadNotifier = DownloadTracker.activeDownloads[materiId];
    }
  }

  // ==========================================
  // TAMBAHAN METHOD KOMENTAR
  // ==========================================
  Future<void> _fetchKomentar() async {
    try {
      final response = await http.get(
        Uri.parse('$endpointKomentar/${widget.materi['id']}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            listKomentar = data['data'] ?? [];
            isLoadingKomentar = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoadingKomentar = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingKomentar = false);
    }
  }

  Future<void> _kirimKomentar() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login untuk berkomentar.'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    if (_komentarController.text.trim().isEmpty) return;

    setState(() => isKirimKomentar = true);
    FocusScope.of(context).unfocus(); // Menutup keyboard

    try {
      final response = await http.post(
        Uri.parse(endpointKomentar),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'materi_id': widget.materi['id'],
          'user_id': userId,
          'isi_komentar': _komentarController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _komentarController.clear();
        await _fetchKomentar(); // Muat ulang daftar komentar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim komentar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan jaringan.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isKirimKomentar = false);
    }
  }

  @override
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }
  // ==========================================

  Future<void> _checkBookmarkStatusAPI() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      if (mounted) setState(() => isCheckingBookmark = false);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
          '$endpointFavorit/cek?user_id=$userId&materi_id=${widget.materi['id']}',
        ),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => isBookmarked = data['is_bookmarked']);
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => isCheckingBookmark = false);
    }
  }

  Future<void> _toggleBookmarkAPI() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan login terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }
    setState(() => isCheckingBookmark = true);
    try {
      if (isBookmarked) {
        final response = await http.delete(
          Uri.parse('$endpointFavorit/$userId/${widget.materi['id']}'),
        );
        if (response.statusCode == 200) {
          setState(() => isBookmarked = false);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Dihapus dari Favorit')),
            );
        }
      } else {
        final response = await http.post(
          Uri.parse(endpointFavorit),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'materi_id': widget.materi['id'],
          }),
        );
        if (response.statusCode == 201) {
          setState(() => isBookmarked = true);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ditambahkan ke Favorit!'),
                backgroundColor: Colors.green,
              ),
            );
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => isCheckingBookmark = false);
    }
  }

  Future<void> _checkFileExists() async {
    Directory direktori = await getApplicationDocumentsDirectory();
    String path = '${direktori.path}/${widget.materi['nama_file']}';
    if (await File(path).exists()) {
      setState(() {
        isDownloaded = true;
        filePath = path;
      });
    }
  }

  Future<void> _unduhFile() async {
    int materiId = int.parse(widget.materi['id'].toString());
    downloadNotifier = ValueNotifier(0.0);
    DownloadTracker.activeDownloads[materiId] = downloadNotifier!;

    setState(() => isDownloading = true);

    try {
      final String apiDownload =
          '$endpointMateri/../download-url?file=${widget.materi['nama_file']}';
      final responseUrl = await http.get(Uri.parse(apiDownload));

      if (responseUrl.statusCode != 200) {
        throw Exception(
          'Gagal mendapatkan URL akses dari server (Kode: ${responseUrl.statusCode})',
        );
      }

      final dataUrl = json.decode(responseUrl.body);
      final String presignedUrl = dataUrl['download_url'] ?? '';

      if (presignedUrl.isEmpty) {
        throw Exception('URL S3 kosong atau tidak valid dari server');
      }

      var request = http.Request('GET', Uri.parse(presignedUrl));
      var response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Gagal menarik file dari server S3');
      }

      var totalBytes = response.contentLength ?? -1;
      var receivedBytes = 0;

      if (totalBytes <= 0 &&
          DownloadTracker.activeDownloads.containsKey(materiId)) {
        DownloadTracker.activeDownloads[materiId]!.value = -1.0;
      }

      Directory direktori = await getApplicationDocumentsDirectory();
      File tmpFile = File(
        '${direktori.path}/${widget.materi['nama_file']}.tmp',
      );
      var sink = tmpFile.openWrite();

      response.stream.listen(
        (List<int> chunk) {
          receivedBytes += chunk.length;
          sink.add(chunk);
          if (totalBytes > 0 &&
              DownloadTracker.activeDownloads.containsKey(materiId)) {
            DownloadTracker.activeDownloads[materiId]!.value =
                (receivedBytes.toDouble() / totalBytes.toDouble());
          }
        },
        onDone: () async {
          await sink.close();
          File finalFile = File(
            '${direktori.path}/${widget.materi['nama_file']}',
          );
          await tmpFile.rename(finalFile.path);

          DownloadTracker.activeDownloads.remove(materiId);

          if (mounted) {
            setState(() {
              isDownloaded = true;
              isDownloading = false;
              filePath = finalFile.path;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Berhasil diunduh!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onError: (e) async {
          await sink.close();
          if (await tmpFile.exists()) await tmpFile.delete();
          DownloadTracker.activeDownloads.remove(materiId);
          if (mounted) {
            setState(() => isDownloading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Koneksi terputus: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        cancelOnError: true,
      );
    } catch (e) {
      DownloadTracker.activeDownloads.remove(materiId);
      if (mounted) {
        setState(() => isDownloading = false);
        String errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _bukaFile() {
    if (widget.materi['tipe'] == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            filePath: filePath,
            judul: widget.materi['judul'],
          ),
        ),
      );
    } else if (widget.materi['tipe'] == 'video' ||
        widget.materi['tipe'] == 'mp4') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(
            filePath: filePath,
            judul: widget.materi['judul'],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Format tidak didukung.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPdf = widget.materi['tipe'] == 'pdf';
    final bool isCerita = widget.materi['tipe'] == 'cerita';
    final String safeHeroTag = widget.materi['id'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Detail Materi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          isCheckingBookmark
              ? const Padding(
                  padding: EdgeInsets.only(right: 20),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: warnaTosca,
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                    color: isBookmarked ? warnaTosca : Colors.grey,
                    size: 28,
                  ),
                  onPressed: _toggleBookmarkAPI,
                ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            Hero(
              tag: safeHeroTag,
              child: Container(
                height: 250,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: widget.materi['url_sampul'] != null
                      ? CachedNetworkImage(
                          imageUrl: widget.materi['url_sampul'],
                          cacheKey: widget.materi['id'].toString() + '_sampul',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: warnaTosca),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.broken_image_rounded,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )
                      : Icon(
                          isPdf
                              ? Icons.menu_book_rounded
                              : (isCerita
                                    ? Icons.article_rounded
                                    : Icons.play_circle_fill_rounded),
                          size: 80,
                          color: isPdf
                              ? Colors.blue[300]
                              : (isCerita
                                    ? Colors.orange[300]
                                    : Colors.purple[300]),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              widget.materi['judul'],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: warnaTosca.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isCerita
                    ? 'Cerita Komunitas'
                    : (isPdf ? 'E-Book PDF' : 'Video Interaktif'),
                style: const TextStyle(
                  color: warnaTosca,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isCerita ? 'Isi Cerita' : 'Sinopsis',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.materi['sinopsis'] ?? 'Sinopsis belum tersedia.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 40),

            // ==========================================
            // TAMBAHAN UI KOMENTAR DI SINI
            // ==========================================
            const Divider(color: Colors.black12, thickness: 1),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Komentar (${listKomentar.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 1. List Komentar
            isLoadingKomentar
                ? const Center(
                    child: CircularProgressIndicator(color: warnaTosca),
                  )
                : listKomentar.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Belum ada komentar. Jadilah yang pertama!',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: listKomentar.length,
                    itemBuilder: (context, index) {
                      final item = listKomentar[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: warnaTosca.withOpacity(0.2),
                              child: Text(
                                item['nama_user']
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    'U',
                                style: const TextStyle(
                                  color: warnaTosca,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama_user'] ?? 'Pengguna',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['isi_komentar'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                      height: 1.4,
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

            const SizedBox(height: 15),

            // 2. Input Komentar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _komentarController,
                      decoration: const InputDecoration(
                        hintText: 'Tulis komentar Anda...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(fontSize: 14),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  isKirimKomentar
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: warnaTosca,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: warnaTosca,
                          ),
                          onPressed: _kirimKomentar,
                        ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // ==========================================
          ],
        ),
      ),
      bottomNavigationBar: isCerita
          ? const SizedBox.shrink()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isDownloading
                        ? () {}
                        : (isDownloaded ? _bukaFile : _unduhFile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDownloaded
                          ? warnaTosca
                          : Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: isDownloading && downloadNotifier != null
                        ? ValueListenableBuilder<double>(
                            valueListenable: downloadNotifier!,
                            builder: (context, value, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: value < 0
                                          ? const LinearProgressIndicator(
                                              backgroundColor: Colors.white30,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                              minHeight: 8,
                                            )
                                          : LinearProgressIndicator(
                                              value: value,
                                              backgroundColor: Colors.white30,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Colors.white),
                                              minHeight: 8,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    value < 0
                                        ? 'Loading...'
                                        : '${(value * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          )
                        : Text(
                            isDownloaded
                                ? (isPdf ? 'Lanjut Baca' : 'Tonton Video')
                                : 'Unduh Materi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
