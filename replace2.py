import re

for filename in ['lib/screens/dashboard_screen.dart', 'lib/screens/daftar_cerita_screen.dart']:
    with open(filename, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find const Text( materi['rating_rata_rata']... )
    content = content.replace("const Text(\n                            materi['rating_rata_rata']", "Text(\n                            materi['rating_rata_rata']")
    
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(content)
