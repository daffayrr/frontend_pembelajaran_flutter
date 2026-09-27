import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:frontend_pembelajaran_flutter/constants/api.dart';
import 'package:frontend_pembelajaran_flutter/screens/login_screen.dart';
import 'package:frontend_pembelajaran_flutter/constants/colors.dart';
import 'package:frontend_pembelajaran_flutter/screens/main_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/edit_profil_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/notifikasi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/keamanan_sandi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/bantuan_faq_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/tentang_aplikasi_screen.dart';
import 'package:frontend_pembelajaran_flutter/screens/admin_materi_screen.dart';

class AkunScreen extends StatefulWidget {
  const AkunScreen({super.key});

  @override
  State<AkunScreen> createState() => _AkunScreenState();
}

class _AkunScreenState extends State<AkunScreen> {
  bool isLoggedIn = false;
  String namaUser = 'Tamu';
  String roleUser = 'Pengunjung';
  int _totalPoin = 0;
  String? _fotoProfilUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final nama = prefs.getString('user_name');
    final role = prefs.getString('user_role');
    final foto = prefs.getString('user_foto');

    setState(() {
      if (token != null) {
        isLoggedIn = true;
        namaUser = nama ?? 'Pengguna';
        roleUser = role ?? 'Member';
        _fotoProfilUrl = foto;
        _fetchUserScore();
      } else {
        isLoggedIn = false;
        namaUser = 'Tamu';
        roleUser = 'Pengunjung';
        _fotoProfilUrl = null;
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    // Simpan messenger di awal sebelum semua async gap
    final messenger = ScaffoldMessenger.of(context);

    // 1. Pick image from gallery
    final XFile? pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    // 2. Crop 1:1 dengan tema Tosca
    final CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Sesuaikan Foto',
          toolbarColor: const Color(0xFF00B4C0),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF00B4C0),
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Sesuaikan Foto',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
    if (croppedFile == null) return;

    // 3. Upload via Multipart ke S3
    setState(() => _isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) throw Exception('User ID tidak ditemukan.');

      final uri = Uri.parse(
        'https://api-service.toscaflow.id/api/user/profil/foto/$userId',
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = staticAuthToken;
      request.files.add(
        await http.MultipartFile.fromPath('foto', croppedFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final newUrl = data['url'] as String?;
        if (newUrl != null && mounted) {
          await prefs.setString('user_foto', newUrl);
          setState(() => _fotoProfilUrl = newUrl);
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        final msg = data['message'] ?? 'Gagal mengupload foto.';
        messenger.showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _fetchUserScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userIdStr = prefs.getString('user_id');
      if (userIdStr == null || userIdStr.isEmpty) return;

      final response = await http.get(
        Uri.parse('$endpointQuizScore/$userIdStr'),
        headers: {
          'Authorization': staticAuthToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Safe parsing dari dynamic/float ke int
        final double parsedScore =
            double.tryParse(data['total_skor']?.toString() ?? '0') ?? 0.0;
        if (mounted) {
          setState(() {
            _totalPoin = parsedScore.round();
          });
        }
      } else {
        debugPrint('Gagal mengambil skor. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetch skor profil: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus SEMUA data sesi lokal secara menyeluruh
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    }
  }

  void _promptLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Silakan login terlebih dahulu untuk mengakses menu ini.',
        ),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Profil Saya',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 100),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Header & Foto Profil
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Avatar utama
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: warnaTosca,
                        backgroundImage: (_fotoProfilUrl != null &&
                                _fotoProfilUrl!.isNotEmpty)
                            ? NetworkImage(_fotoProfilUrl!)
                            : null,
                        child: (_fotoProfilUrl == null ||
                                _fotoProfilUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 55,
                              )
                            : null,
                      ),
                      // Loading overlay saat upload
                      if (_isUploading)
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      // Tombol kamera pojok kanan bawah
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: isLoggedIn && !_isUploading
                              ? _pickAndUploadImage
                              : null,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: warnaTosca,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isLoggedIn ? namaUser : 'Tamu',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleUser.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isLoggedIn)
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilScreen(),
                        ),
                      ),
                      icon: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Edit Profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warnaTosca,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warnaTosca,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Login Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Highlight Card (Skor Kuis)
            if (isLoggedIn)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [warnaTosca, Color(0xFF009CA6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: warnaTosca.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: Colors.amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Skor Kuis Saya',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$_totalPoin',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'Poin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
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
            const SizedBox(height: 32),

            // 3. Menu List
            _buildMenuCard([
              _buildMenuItem(
                Icons.notifications_none_rounded,
                'Notifikasi',
                isLoggedIn
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotifikasiScreen(),
                        ),
                      )
                    : _promptLogin,
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                Icons.security_rounded,
                'Keamanan & Sandi',
                isLoggedIn
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const KeamananSandiScreen(),
                        ),
                      )
                    : _promptLogin,
              ),
              if (roleUser.toLowerCase() == 'admin') ...[
                _buildMenuDivider(),
                _buildMenuItem(
                  Icons.admin_panel_settings_rounded,
                  'Kelola Materi',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminMateriScreen(),
                    ),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 20),
            _buildMenuCard([
              _buildMenuItem(
                Icons.help_outline_rounded,
                'Bantuan & FAQ',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BantuanFaqScreen()),
                ),
              ),
              _buildMenuDivider(),
              _buildMenuItem(
                Icons.info_outline_rounded,
                'Tentang Aplikasi',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TentangAplikasiScreen(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 32),

            // 4. Tombol Logout
            if (isLoggedIn)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Keluar Akun',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 15,
                    ),
                  ),
                  onTap: () => _logout(context),
                ),
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: warnaTosca.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: warnaTosca, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          fontSize: 15,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Colors.grey,
        size: 22,
      ),
      onTap: onTap,
    );
  }

  Widget _buildMenuDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
      indent: 20,
      endIndent: 20,
    );
  }
}
