import subprocess

old_content = subprocess.check_output(['git', 'show', '06400ab:lib/views/dashboards/admin_dashboard.dart'], encoding='utf-8')

idx = old_content.find("filteredUsers")
print("filteredUsers index:", idx)
if idx != -1:
    start_pos = old_content.rfind("] else ...[", 0, idx)
    print("start_pos:", start_pos)
    # find where this else ends
    end_pos = old_content.find("                                  ],\n                                ],\n                              ),", start_pos)
    print("end_pos:", end_pos)
    
    users_code = old_content[start_pos:end_pos]
    print("Extracted users code length:", len(users_code))

    with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
        curr_code = f.read()

    target_pos = curr_code.find("                                  ],\n                                ],\n                              ),")
    print("target_pos in current:", target_pos)

    if target_pos != -1:
        updated = curr_code[:target_pos] + users_code + curr_code[target_pos:]
        with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
            f.write(updated)
        print("SUCCESSFULLY RESTORED USERS TABLE!")
