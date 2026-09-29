import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

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

  double _ratingRataRata = 0.0;
  int _totalReviewer = 0;
  bool _isSubmittingRating = false;

  // --- STATE KOMENTAR ---
  List listKomentar = [];
  bool isLoadingKomentar = true;
  bool isKirimKomentar = false;
  final TextEditingController _komentarController = TextEditingController();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _inisialisasiData();
  }

  Future<void> _inisialisasiData() async {
    final prefs = await SharedPreferences.getInstance();
    currentUserId = prefs.getString('user_id');

    _checkFileExists();
    _checkBookmarkStatusAPI();
    _fetchKomentar();
    _fetchRating();

    int materiId = int.parse(widget.materi['id'].toString());
    if (DownloadTracker.activeDownloads.containsKey(materiId)) {
      isDownloading = true;
      downloadNotifier = DownloadTracker.activeDownloads[materiId];
    }
  }

  // ==========================================
  // FITUR KOMENTAR
  // ==========================================

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
            _ratingRataRata =
                double.tryParse(data['rating_rata_rata'].toString()) ?? 0.0;
            _totalReviewer =
                int.tryParse(data['total_reviewer'].toString()) ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetch rating: ');
    }
  }

  Future<void> _submitRating(double rating) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login untuk memberi rating')),
      );
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
          'user_id': int.parse(currentUserId.toString()),
          'materi_id': int.parse(widget.materi['id'].toString()),
          'rating': rating.toInt(),
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Terima kasih atas penilaian Anda!'),
              backgroundColor: Colors.green,
            ),
          );
          _fetchRating();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengirim rating (Kode: )'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error submit rating: ');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan koneksi: '),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingRating = false);
    }
  }

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
    if (currentUserId == null) {
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
    FocusScope.of(context).unfocus();

    try {
      final response = await http.post(
        Uri.parse(endpointKomentar),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'materi_id': widget.materi['id'],
          'user_id': currentUserId,
          'isi_komentar': _komentarController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        _komentarController.clear();
        await _fetchKomentar();
        _fetchRating();
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

  // --- FUNGSI HAPUS KOMENTAR ---
  Future<void> _hapusKomentar(int idKomentar) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Komentar?'),
            content: const Text('Komentar ini akan dihapus secara permanen.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final response = await http.delete(
        Uri.parse('$endpointKomentar/$idKomentar'),
      );
      if (response.statusCode == 200) {
        await _fetchKomentar();
        _fetchRating(); // Refresh data komentar
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Komentar berhasil dihapus')),
          );
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus komentar.'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan jaringan.'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  // ==========================================
  // FITUR BOOKMARK & DOWNLOAD
  // ==========================================
  Future<void> _checkBookmarkStatusAPI() async {
    if (currentUserId == null) {
      if (mounted) setState(() => isCheckingBookmark = false);
      return;
    }
    try {
      final response = await http.get(
        Uri.parse(
          '$endpointFavorit/cek?user_id=$currentUserId&materi_id=${widget.materi['id']}',
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
    if (currentUserId == null) {
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
          Uri.parse('$endpointFavorit/$currentUserId/${widget.materi['id']}'),
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
            'user_id': currentUserId,
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
  void dispose() {
    _komentarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPdf = widget.materi['tipe'] == 'pdf';
    final bool isCerita = widget.materi['tipe'] == 'cerita';
    final String safeHeroTag = widget.materi['id'].toString();
    final double screenHeight = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // 1. Cinematic Hero Header
              SizedBox(
                height: screenHeight * 0.45,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Hero(
                      tag: safeHeroTag,
                      child: widget.materi['url_sampul'] != null
                          ? CachedNetworkImage(
                              imageUrl: widget.materi['url_sampul'],
                              cacheKey:
                                  widget.materi['id'].toString() + '_sampul',
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(
                                isPdf
                                    ? Icons.menu_book_rounded
                                    : (isCerita
                                          ? Icons.article_rounded
                                          : Icons.play_circle_fill_rounded),
                                size: 80,
                                color: Colors.grey[500],
                              ),
                            ),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black87, Colors.transparent],
                            stops: [0.0, 0.6],
                          ),
                        ),
                      ),
                    ),
                    // App Bar Actions (Back & Bookmark)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      right: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: isCheckingBookmark
                                ? const Padding(
                                    padding: EdgeInsets.all(14.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      isBookmarked
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_outline_rounded,
                                      color: isBookmarked
                                          ? warnaTosca
                                          : Colors.white,
                                    ),
                                    onPressed: _toggleBookmarkAPI,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    // Title and Category at bottom of Hero
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.materi['judul'] ?? 'Tanpa Judul',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isCerita
                                ? 'Cerita Komunitas'
                                : (isPdf
                                      ? 'E-Book Interaktif'
                                      : 'Video Pembelajaran'),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _ratingRataRata > 0
                                    ? _ratingRataRata.toStringAsFixed(1)
                                    : '-',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '($_totalReviewer)',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Action Button and Body
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Action Button
                    if (!isCerita)
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: isDownloading
                              ? null
                              : (isDownloaded ? _bukaFile : _unduhFile),
                          icon: isDownloading
                              ? const SizedBox.shrink()
                              : Icon(
                                  isDownloaded
                                      ? (isPdf
                                            ? Icons.auto_stories_rounded
                                            : Icons.play_arrow_rounded)
                                      : Icons.download_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                          label: isDownloading && downloadNotifier != null
                              ? ValueListenableBuilder<double>(
                                  valueListenable: downloadNotifier!,
                                  builder: (context, value, child) {
                                    return Text(
                                      value < 0
                                          ? 'Mengunduh...'
                                          : 'Mengunduh ${(value * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                )
                              : Text(
                                  isDownloaded
                                      ? (isPdf
                                            ? 'Mulai Membaca'
                                            : 'Tonton Video')
                                      : 'Unduh Materi',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: warnaTosca,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    if (!isCerita) const SizedBox(height: 30),

                    // 3. Sinopsis
                    const Text(
                      'Sinopsis',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.materi['sinopsis'] ?? 'Sinopsis belum tersedia.',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: warnaTosca.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: warnaTosca.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Beri nilai cerita ini:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _isSubmittingRating
                              ? const CircularProgressIndicator(
                                  color: warnaTosca,
                                )
                              : RatingBar.builder(
                                  initialRating: 0,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemPadding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                  ),
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

                    // 4. Komentar
                    Text(
                      'Komentar (${listKomentar.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    isLoadingKomentar
                        ? const Center(
                            child: CircularProgressIndicator(color: warnaTosca),
                          )
                        : listKomentar.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'Belum ada komentar. Jadilah yang pertama!',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listKomentar.length,
                            itemBuilder: (context, index) {
                              final item = listKomentar[index];
                              final bool isMyComment =
                                  currentUserId != null &&
                                  item['user_id'].toString() == currentUserId;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: warnaTosca.withOpacity(
                                        0.15,
                                      ),
                                      backgroundImage:
                                          (item['foto_profil'] != null &&
                                              item['foto_profil']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(item['foto_profil'])
                                          : null,
                                      child:
                                          (item['foto_profil'] == null ||
                                              item['foto_profil']
                                                  .toString()
                                                  .isEmpty)
                                          ? Text(
                                              item['nama_user']
                                                      ?.substring(0, 1)
                                                      .toUpperCase() ??
                                                  'U',
                                              style: const TextStyle(
                                                color: warnaTosca,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['nama_user'] ?? 'Pengguna',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item['isi_komentar'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 13,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isMyComment)
                                      GestureDetector(
                                        onTap: () => _hapusKomentar(
                                          int.parse(item['id'].toString()),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _komentarController,
                              decoration: InputDecoration(
                                hintText: 'Tulis komentar...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              minLines: 1,
                              maxLines: 3,
                            ),
                          ),
                          isKirimKomentar
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: warnaTosca,
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.send_rounded,
                                    color: warnaTosca,
                                    size: 20,
                                  ),
                                  onPressed: _kirimKomentar,
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
