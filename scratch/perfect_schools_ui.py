with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace the top action bar in Tab 3 to always show BOTH '+ Add School' AND '+ Create User' prominently
old_action_bar = """                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_isEn ? 'User & System Governance' : 'Gestion des Utilisateurs & Sécurité', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),
                                              const SizedBox(height: 2),
                                              Text(_isEn ? 'Direct database access for account creation & role assignment' : 'Accès direct à la base de données pour la création des comptes', style: TextStyle(color: _sub, fontSize: 12.5)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                              onPressed: _showAddSchoolDialog,
                                              icon: const Icon(Icons.add_business_rounded, size: 16),
                                              label: Text(_isEn ? '+ Add School' : '+ Ajouter Établissement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                              onPressed: _showAddUserDialog,
                                              icon: const Icon(Icons.person_add_rounded, size: 16),
                                              label: Text(_isEn ? '+ Create User' : '+ Créer Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );"""

new_action_bar = """                                    return Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(_isEn ? 'User & School Governance' : 'Gestion des Utilisateurs & Établissements', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),
                                              const SizedBox(height: 2),
                                              Text(_isEn ? 'Database administration for schools, delegates, teachers, and students' : 'Administration de la base de données des établissements, délégués, enseignants et élèves', style: TextStyle(color: _sub, fontSize: 12.5)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF0284C7),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              onPressed: _showAddSchoolDialog,
                                              icon: const Icon(Icons.add_business_rounded, size: 18),
                                              label: Text(_isEn ? '+ Add School' : '+ Ajouter un Établissement', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                            ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              onPressed: _showAddUserDialog,
                                              icon: const Icon(Icons.person_add_rounded, size: 18),
                                              label: Text(_isEn ? '+ Create User' : '+ Créer un Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );"""

if old_action_bar in text:
    text = text.replace(old_action_bar, new_action_bar)

# Replace the Schools Directory UI inside Tab 3 with a responsive, wide, beautiful full-width table
old_schools_block = """                                            if (filteredSchools.isEmpty) ...[
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
                                            ]"""

new_schools_block = """                                            if (filteredSchools.isEmpty) ...[
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(36),
                                                decoration: BoxDecoration(
                                                  color: _bg,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: _border),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.school_outlined, color: _sub, size: 42),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      _isEn ? 'No schools registered or matching search.' : 'Aucun établissement trouvé.',
                                                      style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 14),
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                                                      onPressed: _showAddSchoolDialog,
                                                      icon: const Icon(Icons.add_business_rounded, size: 16),
                                                      label: Text(_isEn ? '+ Register First School' : '+ Ajouter un Établissement'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                              // Full-Width Structured Table Header
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: _bg,
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: _border),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(flex: 5, child: Text(_isEn ? 'School Name' : 'Nom de l\\'Établissement', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                    Expanded(flex: 3, child: Text(_isEn ? 'Region' : 'Région', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                    Expanded(flex: 3, child: Text(_isEn ? 'Division' : 'Département', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                    Expanded(flex: 3, child: Text(_isEn ? 'Town / City' : 'Ville', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                    Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(_isEn ? 'Action' : 'Action', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5)))),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),

                                              // Full-Width Rows
                                              Column(
                                                children: filteredSchools.map<Widget>((s) {
                                                  final scName = (s['name'] ?? '').toString();
                                                  final scReg  = (s['region'] ?? 'ADAMOUA').toString();
                                                  final scDiv  = (s['division'] ?? 'DJEREM').toString();
                                                  final scTown = (s['town'] ?? '-').toString();

                                                  return Container(
                                                    width: double.infinity,
                                                    margin: const EdgeInsets.only(bottom: 8),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                                    decoration: BoxDecoration(
                                                      color: _bg,
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: _border.withValues(alpha: 0.7)),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // School Name
                                                        Expanded(
                                                          flex: 5,
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                padding: const EdgeInsets.all(8),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFF0284C7).withValues(alpha: 0.14),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: const Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 18),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Text(
                                                                  scName,
                                                                  style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 13.5),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // Region Badge
                                                        Expanded(
                                                          flex: 3,
                                                          child: Align(
                                                            alignment: Alignment.centerLeft,
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                                                              ),
                                                              child: Text(scReg, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11.5), overflow: TextOverflow.ellipsis),
                                                            ),
                                                          ),
                                                        ),

                                                        // Division Badge
                                                        Expanded(
                                                          flex: 3,
                                                          child: Align(
                                                            alignment: Alignment.centerLeft,
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
                                                              ),
                                                              child: Text(scDiv, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 11.5), overflow: TextOverflow.ellipsis),
                                                            ),
                                                          ),
                                                        ),

                                                        // Town
                                                        Expanded(
                                                          flex: 3,
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.location_on_rounded, color: _sub, size: 16),
                                                              const SizedBox(width: 5),
                                                              Expanded(
                                                                child: Text(
                                                                  scTown,
                                                                  style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),

                                                        // Action Button
                                                        Expanded(
                                                          flex: 2,
                                                          child: Align(
                                                            alignment: Alignment.centerRight,
                                                            child: ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: _green,
                                                                foregroundColor: Colors.white,
                                                                elevation: 0,
                                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ]"""

if old_schools_block in text:
    text = text.replace(old_schools_block, new_schools_block)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('SUCCESSFULLY REPLACED TABLE WITH FULL-WIDTH ROW LAYOUT')
