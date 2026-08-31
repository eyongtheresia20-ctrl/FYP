with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if ").toList()," in line and "),\\n" in lines[i+1] and "),\\n" in lines[i+2]:
        print(f"Found at line {i+1}: {repr(lines[i+1])}, {repr(lines[i+2])}")
        del lines[i+2]
        break

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("SUCCESS")
