import subprocess

# Get old file content from git commit 06400ab
old_content = subprocess.check_output(['git', 'show', '06400ab:lib/views/dashboards/admin_dashboard.dart'], encoding='utf-8')

idx_users_start = old_content.find("                                  ] else ...[\n                                    Builder(\n                                      builder: (ctx) {")
idx_users_end = old_content.find("                                  ],\n                                ],\n                              ),\n                            ],")

print("idx_users_start:", idx_users_start)
print("idx_users_end:", idx_users_end)

if idx_users_start != -1 and idx_users_end != -1:
    users_section = old_content[idx_users_start:idx_users_end]
    print("Found users section of length:", len(users_section))
    
    with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
        current_content = f.read()

    # Find where schools section ends in current_content
    # It ends at `                                  ],\n                                ],\n                              ),\n                            ],`
    curr_end_idx = current_content.find("                                  ],\n                                ],\n                              ),\n                            ],")
    print("curr_end_idx:", curr_end_idx)

    if curr_end_idx != -1:
        new_content = current_content[:curr_end_idx] + users_section + current_content[curr_end_idx:]
        with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("SUCCESS: RESTORED USERS TABLE SECTION")
    else:
        print("COULD NOT FIND curr_end_idx")
