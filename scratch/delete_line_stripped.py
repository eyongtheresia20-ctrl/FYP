with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if ").toList()," in line:
        print(f"Index {i}: {repr(lines[i])}")
        print(f"Index {i+1}: {repr(lines[i+1])}")
        print(f"Index {i+2}: {repr(lines[i+2])}")
        if lines[i+1].strip() == '),' and lines[i+2].strip() == '),':
            print("DELETING LINE", i+2)
            del lines[i+2]
            break

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("DONE")
