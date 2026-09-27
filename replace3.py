with open('lib/screens/bookmark_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("const Text('4.8'", "Text(materi['rating_rata_rata'] != null ? materi['rating_rata_rata'].toString() : '0.0'")

with open('lib/screens/bookmark_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
