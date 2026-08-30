with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add quick shortcut '+ Add School' above the school dropdown in _showAddUserDialog
old_school_label = """                    // School Dropdown (For Principal, Teacher, Student)
                    if (selectedRole != 'admin' && selectedRole != 'regional_delegate' && selectedRole != 'divisional_delegate') ...[
                      Text(_isEn ? 'School:' : 'Établissement :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),"""

new_school_label = """                    // School Dropdown (For Principal, Teacher, Student)
                    if (selectedRole != 'admin' && selectedRole != 'regional_delegate' && selectedRole != 'divisional_delegate') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_isEn ? 'School:' : 'Établissement :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showAddSchoolDialog();
                            },
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: _green, size: 14),
                                const SizedBox(width: 4),
                                Text(_isEn ? '+ Add School' : '+ Ajouter', style: TextStyle(color: _green, fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),"""

text = text.replace(old_school_label, new_school_label)

# 2. Make the Schools Directory Table much bigger, expansive and include a prominent '+ Add School' button in header
old_schools_table_block = """                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isEn ? 'Registered Schools Directory (${filteredSchools.length})' : 'Répertoire des Établissements Enregistrés (${filteredSchools.length})',
                                              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 14),
                                            if (filteredSchools.isEmpty) ...[
                                              Text(_isEn ? 'No schools matching search.' : 'Aucun établissement correspondant.', style: TextStyle(color: _sub, fontSize: 13)),
                                            ] else ...[
                                              SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: DataTable(
                                                  headingRowColor: WidgetStateProperty.all(_bg),
                                                  dataRowMinHeight: 52,
                                                  dataRowMaxHeight: 64,
                                                  columnSpacing: 24,
                                                  columns: [
                                                    DataColumn(label: Text(_isEn ? 'School Name' : 'Nom de l\\'Établissement', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Region' : 'Région', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Division' : 'Département', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Town' : 'Ville', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                  ],
                                                  rows: filteredSchools.map<DataRow>((s) {
                                                    final scName = (s['name'] ?? '').toString();
                                                    final scReg  = (s['region'] ?? 'ADAMOUA').toString();
                                                    final scDiv  = (s['division'] ?? 'DJEREM').toString();
                                                    final scTown = (s['town'] ?? '-').toString();

                                                    return DataRow(
                                                      cells: [
                                                        DataCell(
                                                          Row(
                                                            children: [
                                                              const CircleAvatar(
                                                                radius: 14,
                                                                backgroundColor: Color(0x260284C7),
                                                                child: Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 16),
                                                              ),
                                                              const SizedBox(width: 10),
                                                              Text(scName, style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13)),
                                                            ],
                                                          ),
                                                        ),
                                                        DataCell(Text(scReg, style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 12.5))),
                                                        DataCell(Text(scDiv, style: TextStyle(color: _sub, fontSize: 12))),
                                                        DataCell(Text(scTown, style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w500))),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );"""

new_schools_table_block = """                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _border),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _isEn ? 'Registered Schools Directory (${filteredSchools.length})' : 'Répertoire des Établissements Enregistrés (${filteredSchools.length})',
                                                        style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 17),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _isEn ? 'Institutional secondary & technical schools database' : 'Base de données des établissements scolaires enregistrés',
                                                        style: TextStyle(color: _sub, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0284C7),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  onPressed: _showAddSchoolDialog,
                                                  icon: const Icon(Icons.add_business_rounded, size: 18),
                                                  label: Text(
                                                    _isEn ? '+ Add School' : '+ Ajouter un Établissement',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            if (filteredSchools.isEmpty) ...[
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(28),
                                                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14)),
                                                child: Center(
                                                  child: Text(
                                                    _isEn ? 'No schools matching search criteria.' : 'Aucun établissement correspondant.',
                                                    style: TextStyle(color: _sub, fontSize: 13.5, fontStyle: FontStyle.italic),
                                                  ),
                                                ),
                                              ),
                                            ] else ...[
                                              SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: ConstrainedBox(
                                                  constraints: BoxConstraints(
                                                    minWidth: MediaQuery.of(context).size.width >= 800 ? MediaQuery.of(context).size.width - 340 : 700,
                                                  ),
                                                  child: DataTable(
                                                    headingRowColor: WidgetStateProperty.all(_bg),
                                                    dataRowMinHeight: 60,
                                                    dataRowMaxHeight: 74,
                                                    columnSpacing: 32,
                                                    horizontalMargin: 18,
                                                    columns: [
                                                      DataColumn(label: Text(_isEn ? 'School Name' : 'Nom de l\\'Établissement', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 13))),
                                                      DataColumn(label: Text(_isEn ? 'Region' : 'Région', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 13))),
                                                      DataColumn(label: Text(_isEn ? 'Division' : 'Département', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 13))),
                                                      DataColumn(label: Text(_isEn ? 'Town / City' : 'Ville / Localité', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 13))),
                                                      DataColumn(label: Text(_isEn ? 'Actions' : 'Actions', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 13))),
                                                    ],
                                                    rows: filteredSchools.map<DataRow>((s) {
                                                      final scName = (s['name'] ?? '').toString();
                                                      final scReg  = (s['region'] ?? 'ADAMOUA').toString();
                                                      final scDiv  = (s['division'] ?? 'DJEREM').toString();
                                                      final scTown = (s['town'] ?? '-').toString();

                                                      return DataRow(
                                                        cells: [
                                                          DataCell(
                                                            Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Container(
                                                                  padding: const EdgeInsets.all(8),
                                                                  decoration: BoxDecoration(
                                                                    color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                                    shape: BoxShape.circle,
                                                                  ),
                                                                  child: const Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 18),
                                                                ),
                                                                const SizedBox(width: 12),
                                                                ConstrainedBox(
                                                                  constraints: const BoxConstraints(maxWidth: 280),
                                                                  child: Text(
                                                                    scName,
                                                                    style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14),
                                                                    overflow: TextOverflow.ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          DataCell(
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                                                              ),
                                                              child: Text(scReg, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 12)),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
                                                              ),
                                                              child: Text(scDiv, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 12)),
                                                            ),
                                                          ),
                                                          DataCell(
                                                            Row(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                Icon(Icons.location_on_rounded, color: _sub, size: 16),
                                                                const SizedBox(width: 6),
                                                                Text(scTown, style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                                                              ],
                                                            ),
                                                          ),
                                                          DataCell(
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: _green.withValues(alpha: 0.15),
                                                                foregroundColor: _green,
                                                                elevation: 0,
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                              ),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _currentNavIndex = 2;
                                                                  _fetchSchoolDetails(scName);
                                                                });
                                                              },
                                                              child: Text(_isEn ? 'View Stats' : 'Voir Stats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );"""

text = text.replace(old_schools_table_block, new_schools_table_block)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('SUCCESSFULLY ENLARGED SCHOOLS TABLE AND ADDED ACTION BUTTONS')
