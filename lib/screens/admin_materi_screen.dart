import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';
import 'package:frontend_pembelajaran_flutter/screens/form_materi_screen.dart';

class AdminMateriScreen extends StatefulWidget {
  const AdminMateriScreen({super.key});

  @override
  State<AdminMateriScreen> createState() => _AdminMateriScreenState();
}

class _AdminMateriScreenState extends State<AdminMateriScreen> {
  List listMateri = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // 🚀 TEKNIK ANTI-FREEZE: Tunda render data sampai animasi rute selesai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _fetchMateri();
      });
    });
  }

  Future<void> _fetchMateri() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(endpointMateri));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            listMateri = data['data'] ?? [];
            isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _hapusMateri(dynamic id) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Hapus Materi?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Tindakan ini juga akan menghapus file dari penyimpanan awan (S3).',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Hapus',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      final response = await http.delete(Uri.parse('$endpointMateri/$id'));
      if (response.statusCode == 200) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Materi berhasil dihapus!'),
              backgroundColor: Colors.green,
            ),
          );
        _fetchMateri();
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus materi.'),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kesalahan jaringan.'),
            backgroundColor: Colors.red,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Panel Admin Materi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: warnaTosca),
                  SizedBox(height: 15),
                  Text(
                    'Memuat data materi...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : listMateri.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    'Belum ada materi',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchMateri,
              color: warnaTosca,
              child: ListView.builder(
                // 🚀 Mencegah layout stuck saat list ditarik
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(
                  bottom: 100,
                  top: 15,
                  left: 20,
                  right: 20,
                ),
                itemCount: listMateri.length,
                itemBuilder: (context, index) {
                  final materi = listMateri[index];
                  final isCerita = materi['tipe'] == 'cerita';

                  // 🚀 OPTIMASI: Mengganti ListTile dengan Container + Row agar tidak membebani layout engine CPU
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Gambar Sampul yang Dioptimasi
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 65,
                            height: 65,
                            child:
                                (materi['url_sampul'] != null &&
                                    materi['url_sampul'].toString().isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: materi['url_sampul'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[100],
                                      child: const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(
                                          color: warnaTosca,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: Colors.grey[100],
                                          child: const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                  )
                                : Container(
                                    color: isCerita
                                        ? Colors.orange[50]
                                        : Colors.blue[50],
                                    child: Icon(
                                      isCerita
                                          ? Icons.article_rounded
                                          : Icons.menu_book_rounded,
                                      color: isCerita
                                          ? Colors.orange[300]
                                          : Colors.blue[300],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 15),

                        // Teks Judul & Tipe
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                materi['judul'] ?? 'Tanpa Judul',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Tipe: ${materi['tipe'].toString().toUpperCase()}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Aksi (Edit & Hapus) yang Terstruktur
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Colors.blueAccent,
                                size: 22,
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FormMateriScreen(materi: materi),
                                  ),
                                ).then((_) => _fetchMateri());
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              onPressed: () => _hapusMateri(materi['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FormMateriScreen()),
          ).then((_) => _fetchMateri());
        },
        backgroundColor: warnaTosca,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Materi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
