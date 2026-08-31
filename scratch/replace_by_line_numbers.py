with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 1. Locate start of Tab 3 Header
idx_tab3_head_start = -1
idx_tab3_head_end = -1

for i, l in enumerate(lines):
    if "if (_currentNavIndex == 3)" in l:
        idx_tab3_head_start = i + 3 # after Column and children: [
        break

for i in range(idx_tab3_head_start, len(lines)):
    if "if (_isLoadingUsers)" in lines[i]:
        idx_tab3_head_end = i
        break

print("idx_tab3_head_start:", idx_tab3_head_start, "idx_tab3_head_end:", idx_tab3_head_end)

top_action_bar_code = [
"""                                // Top Action Bar: [Users / Schools Toggle on LEFT] & [Create User / Add School on RIGHT]
                                LayoutBuilder(
                                  builder: (context, headerConstraints) {
                                    final isCompact = headerConstraints.maxWidth < 600;
                                    final toggleButtons = Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ChoiceChip(
                                          avatar: Icon(Icons.people_alt_rounded, color: !_showSchoolsSection ? Colors.white : _sub, size: 16),
                                          label: Text(_isEn ? "Users (${_allUsersList.length})" : "Utilisateurs (${_allUsersList.length})", style: TextStyle(color: !_showSchoolsSection ? Colors.white : _text, fontWeight: FontWeight.bold, fontSize: 13)),
                                          selected: !_showSchoolsSection,
                                          selectedColor: _green,
                                          backgroundColor: _card,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          onSelected: (val) => setState(() => _showSchoolsSection = false),
                                        ),
                                        const SizedBox(width: 10),
                                        ChoiceChip(
                                          avatar: Icon(Icons.school_rounded, color: _showSchoolsSection ? Colors.white : _sub, size: 16),
                                          label: Text(_isEn ? "Schools (${_allSchoolsList.length})" : "Établissements (${_allSchoolsList.length})", style: TextStyle(color: _showSchoolsSection ? Colors.white : _text, fontWeight: FontWeight.bold, fontSize: 13)),
                                          selected: _showSchoolsSection,
                                          selectedColor: const Color(0xFF0284C7),
                                          backgroundColor: _card,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          onSelected: (val) => setState(() => _showSchoolsSection = true),
                                        ),
                                      ],
                                    );

                                    final actionButton = ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: !_showSchoolsSection ? _green : const Color(0xFF0284C7),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      ),
                                      onPressed: !_showSchoolsSection ? _showAddUserDialog : _showAddSchoolDialog,
                                      icon: Icon(!_showSchoolsSection ? Icons.person_add_rounded : Icons.add_business_rounded, size: 18),
                                      label: Text(
                                        !_showSchoolsSection
                                            ? (_isEn ? "+ Create User" : "+ Créer un Utilisateur")
                                            : (_isEn ? "+ Add School" : "+ Ajouter un Établissement"),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    );

                                    if (isCompact) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          toggleButtons,
                                          const SizedBox(height: 10),
                                          Align(alignment: Alignment.centerRight, child: actionButton),
                                        ],
                                      );
                                    }

                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        toggleButtons,
                                        actionButton,
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Search & Filter Row (Role dropdown only visible for Users)
                                LayoutBuilder(
                                  builder: (context, filterConstraints) {
                                    final isMobileFilter = filterConstraints.maxWidth < 500;
                                    final searchField = TextField(
                                      onChanged: (val) => setState(() => _userSearchQuery = val),
                                      style: TextStyle(color: _text),
                                      decoration: InputDecoration(
                                        hintText: !_showSchoolsSection
                                            ? (_isEn ? "Search by name or matricule..." : "Rechercher par nom ou matricule...")
                                            : (_isEn ? "Search by school name, region, division, town..." : "Rechercher par nom d'établissement, région, département, ville..."),
                                        hintStyle: TextStyle(color: _sub, fontSize: 12.5),
                                        prefixIcon: Icon(Icons.search_rounded, color: _sub, size: 20),
                                        filled: true, fillColor: _bg,
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                      ),
                                    );

                                    if (_showSchoolsSection) {
                                      // Clean full-width search without irrelevant role dropdown
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                                        child: searchField,
                                      );
                                    }

                                    final roleDropdown = Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _userRoleFilter,
                                          isExpanded: isMobileFilter,
                                          dropdownColor: _card,
                                          style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12.5),
                                          items: [
                                            DropdownMenuItem(value: 'ALL', child: Text(_isEn ? 'All Roles' : 'Tous les Rôles')),
                                            DropdownMenuItem(value: 'regional_delegate', child: Text(_isEn ? 'Regional Delegates' : 'Délégués Régionaux')),
                                            DropdownMenuItem(value: 'divisional_delegate', child: Text(_isEn ? 'Divisional Delegates' : 'Délégués Départementaux')),
                                            DropdownMenuItem(value: 'principal', child: Text(_isEn ? 'Principals' : 'Proviseurs')),
                                            DropdownMenuItem(value: 'teacher', child: Text(_isEn ? 'Teachers' : 'Enseignants')),
                                            DropdownMenuItem(value: 'student', child: Text(_isEn ? 'Students' : 'Élèves')),
                                          ],
                                          onChanged: (val) {
                                            if (val != null) setState(() => _userRoleFilter = val);
                                          },
                                        ),
                                      ),
                                    );

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                                      child: isMobileFilter
                                          ? Column(
                                              children: [
                                                searchField,
                                                const SizedBox(height: 10),
                                                SizedBox(width: double.infinity, child: roleDropdown),
                                              ],
                                            )
                                          : Row(
                                              children: [
                                                Expanded(child: searchField),
                                                const SizedBox(width: 12),
                                                roleDropdown,
                                              ],
                                            ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
"""
]

# Apply top header replacement
lines = lines[:idx_tab3_head_start] + top_action_bar_code + lines[idx_tab3_head_end:]

# 2. In Schools Container card, remove the duplicate Row with title and duplicate + Add School button
idx_school_dup_start = -1
idx_school_dup_end = -1
for i, l in enumerate(lines):
    if "final filteredSchools =" in l:
        # find the duplicate Row inside the Container
        for j in range(i, len(lines)):
            if "children: [" in lines[j] and "Row(" in lines[j+1]:
                idx_school_dup_start = j + 1
                break
        break

if idx_school_dup_start != -1:
    for k in range(idx_school_dup_start, len(lines)):
        if "if (filteredSchools.isEmpty)" in lines[k]:
            idx_school_dup_end = k
            break

print("idx_school_dup_start:", idx_school_dup_start, "idx_school_dup_end:", idx_school_dup_end)

if idx_school_dup_start != -1 and idx_school_dup_end != -1:
    clean_school_card_title = [
"""                                            Text(
                                              _isEn ? "Registered Schools Directory (${filteredSchools.length})" : "Répertoire des Établissements Enregistrés (${filteredSchools.length})",
                                              style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16),
                                            ),
                                            const SizedBox(height: 14),
"""
    ]
    lines = lines[:idx_school_dup_start] + clean_school_card_title + lines[idx_school_dup_end:]

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("SUCCESS: CLEANED AND REORDERED GOVERNANCE TAB!")
