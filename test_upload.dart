import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const staticAuthToken = 'Bearer T0sc4Fl0w_S3cr3t_2026';

void main() async {
  print('--- Memulai Verifikasi Direct-to-S3 ---');
  
  try {
    await testUploadFotoProfil();
    await testUploadMateri();
    print('\n✅ SEMUA PENGUJIAN BERHASIL!');
  } catch(e) {
    print('\n❌ PENGUJIAN GAGAL: $e');
  }
}

Future<void> testUploadFotoProfil() async {
  print('\n[1] Menguji Upload Foto Profil...');
  final file = File('verify_doc/foto_profil.jpg');
  final bytes = await file.readAsBytes();
  
  final extension = 'jpg';
  final mimeType = 'image/jpeg';
  final userId = '1';

  print(' -> Minta URL Upload...');
  var genUrlResponse = await http.post(
    Uri.parse('https://api-service.toscaflow.id/api/user/profil/generate-url/$userId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': staticAuthToken,
    },
    body: jsonEncode({
      "extension": extension,
      "content_type": mimeType
    }),
  );

  if (genUrlResponse.statusCode != 200) {
    throw Exception('Gagal generate URL: ${genUrlResponse.body}');
  }
  
  var genUrlData = jsonDecode(genUrlResponse.body);
  String uploadUrl = genUrlData['data']['upload_url'];
  String fileKey = genUrlData['data']['file_key'];
  print(' -> URL didapat, melakukan PUT ke S3...');

  var s3Response = await http.put(
    Uri.parse(uploadUrl),
    headers: {'Content-Type': mimeType},
    body: bytes,
  );

  if (s3Response.statusCode != 200) {
    throw Exception('Gagal upload ke S3: ${s3Response.body}');
  }
  
  print(' -> Upload S3 berhasil, melakukan Konfirmasi...');
  var confirmResponse = await http.post(
    Uri.parse('https://api-service.toscaflow.id/api/user/profil/confirm/$userId'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': staticAuthToken,
    },
    body: jsonEncode({"file_key": fileKey}),
  );

  if (confirmResponse.statusCode != 200) {
    throw Exception('Gagal konfirmasi: ${confirmResponse.body}');
  }
  print('✅ Upload Foto Profil SUKSES!');
}

Future<void> testUploadMateri() async {
  print('\n[2] Menguji Upload Materi (PDF & Sampul)...');
  
  print(' -> Upload Sampul (S3)...');
  String sampulKey = await _uploadToS3('verify_doc/sampul_materi.jpg', 'cover');
  
  print(' -> Upload PDF (S3)...');
  String pdfKey = await _uploadToS3('verify_doc/pdf_materi.pdf', 'pdf');
  
  print(' -> Simpan Data Materi...');
  var response = await http.post(
    Uri.parse('https://api-service.toscaflow.id/api/materi'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': staticAuthToken,
    },
    body: jsonEncode({
      'judul': 'Verifikasi Flutter S3',
      'sinopsis': 'Menguji integrasi Flutter ke S3',
      'tipe': 'pdf',
      'file_sampul': sampulKey,
      'file_materi': pdfKey,
    }),
  );
  
  if (response.statusCode != 200 && response.statusCode != 201) {
    throw Exception('Gagal simpan materi: ${response.body}');
  }
  print('✅ Upload Materi SUKSES!');
}

Future<String> _uploadToS3(String path, String type) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  
  String extension = path.split('.').last.toLowerCase();
  String mimeType = 'application/octet-stream';
  if (type == 'cover') {
     mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
  } else if (type == 'pdf') {
     mimeType = 'application/pdf';
  }

  var genUrlResponse = await http.post(
    Uri.parse('https://api-service.toscaflow.id/api/materi/generate-url'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': staticAuthToken,
    },
    body: jsonEncode({
      "type": type,
      "extension": extension,
      "content_type": mimeType
    }),
  );

  if (genUrlResponse.statusCode != 200) {
    throw Exception('Gagal generate URL $type: ${genUrlResponse.body}');
  }

  var genUrlData = jsonDecode(genUrlResponse.body);
  String uploadUrl = genUrlData['data']['upload_url'];
  String fileKey = genUrlData['data']['file_key'];

  var s3Response = await http.put(
    Uri.parse(uploadUrl),
    headers: {'Content-Type': mimeType},
    body: bytes,
  );

  if (s3Response.statusCode != 200) {
    throw Exception('Gagal upload S3 $type');
  }

  return fileKey;
}
