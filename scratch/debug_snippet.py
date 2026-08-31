with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

idx = text.find('Registered Schools Directory')
if idx != -1:
    print("FOUND at", idx)
    print(repr(text[idx-50:idx+300]))
else:
    print("NOT FOUND")
