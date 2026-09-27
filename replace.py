with open('lib/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'4.8'", "materi['rating_rata_rata'] != null ? materi['rating_rata_rata'].toString() : '0.0'")

with open('lib/screens/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

with open('lib/screens/daftar_cerita_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("'4.8'", "materi['rating_rata_rata'] != null ? materi['rating_rata_rata'].toString() : '0.0'")

with open('lib/screens/daftar_cerita_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
