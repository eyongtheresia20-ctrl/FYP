with open('lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if 'showSnackBar' in line:
        print(f"Line {i+1}: {line.strip()}")
