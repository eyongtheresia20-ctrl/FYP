import subprocess

old_content = subprocess.check_output(['git', 'show', '06400ab:lib/views/dashboards/admin_dashboard.dart'], encoding='utf-8').replace('\r\n', '\n')

with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    curr_content = f.read().replace('\r\n', '\n')

# In old_content, find from `                                  ] else ...[` before filteredUsers to the end of that widget
idx_filtered = old_content.find("filteredUsers =")
idx_else_users = old_content.rfind("] else ...[", 0, idx_filtered)

# Find the end of Tab 3 (User & Security Admin)
# In old_content, Tab 3 starts at `if (_currentNavIndex == 3) ...[` and ends before `Widget _overviewStatCard`
idx_tab3_old_end = old_content.find("  Widget _overviewStatCard", idx_else_users)
# find the closing of `] else ...[` before `_overviewStatCard`
# Let's inspect the lines around idx_tab3_old_end
print("old_content length:", len(old_content), "idx_else_users:", idx_else_users, "idx_tab3_old_end:", idx_tab3_old_end)

# Let's extract the users table widget
users_table_code = old_content[idx_else_users:idx_tab3_old_end]
# Remove trailing container closings that belong to Tab 3 wrapper
# Find `                                      },` and `                                    ),`
idx_last_builder_close = users_table_code.rfind("                                    ),")
users_table_clean = users_table_code[:idx_last_builder_close + len("                                    ),")]

print("users_table_clean ends with:\n", users_table_clean[-200:])

# Now in curr_content, find where `_showSchoolsSection` ends (line before `Widget _overviewStatCard`)
idx_tab3_curr_end = curr_content.find("  Widget _overviewStatCard")
# In curr_content, schools section ends with `                                    ),`
idx_schools_builder_close = curr_content.rfind("                                    ),", 0, idx_tab3_curr_end)

print("idx_schools_builder_close in curr:", idx_schools_builder_close)

# Insert users_table_clean right after schools builder close
curr_updated = curr_content[:idx_schools_builder_close + len("                                    ),")] + "\n" + users_table_clean + curr_content[idx_schools_builder_close + len("                                    ),"):]

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(curr_updated)

print("SUCCESSFULLY INSERTED USERS TABLE!")
