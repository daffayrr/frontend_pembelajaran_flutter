with open('lib/screens/splash_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = [line for line in lines if 'final prefs = await SharedPreferences.getInstance();' not in line]

with open('lib/screens/splash_screen.dart', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
