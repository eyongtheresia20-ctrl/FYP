with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace Tab 3 Users Live Database List Table with the tabbed toggle (Users / Schools)
old_table_header = """                                // Users Live Database List Table
                                if (_isLoadingUsers) ...[
                                  const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
                                ] else ...[
                                  Builder(
                                    builder: (ctx) {
                                      final filteredUsers = _allUsersList.where((u) {"""

new_table_header = """                                // Toggle between Users & Schools
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        label: Text(_isEn ? 'Users (${_allUsersList.length})' : 'Utilisateurs (${_allUsersList.length})', style: TextStyle(color: !_showSchoolsSection ? Colors.white : _text, fontWeight: FontWeight.bold)),
                                        selected: !_showSchoolsSection,
                                        selectedColor: _green,
                                        backgroundColor: _card,
                                        onSelected: (val) => setState(() => _showSchoolsSection = false),
                                      ),
                                      const SizedBox(width: 10),
                                      ChoiceChip(
                                        label: Text(_isEn ? 'Schools (${_allSchoolsList.length})' : 'Établissements (${_allSchoolsList.length})', style: TextStyle(color: _showSchoolsSection ? Colors.white : _text, fontWeight: FontWeight.bold)),
                                        selected: _showSchoolsSection,
                                        selectedColor: const Color(0xFF0284C7),
                                        backgroundColor: _card,
                                        onSelected: (val) => setState(() => _showSchoolsSection = true),
                                      ),
                                    ],
                                  ),
                                ),

                                // Live Database List Table (Users or Schools)
                                if (_isLoadingUsers) ...[
                                  const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
                                ] else if (_showSchoolsSection) ...[
                                  Builder(
                                    builder: (ctx) {
                                      final filteredSchools = _allSchoolsList.where((s) {
                                        final name = (s['name'] ?? '').toString().toLowerCase();
                                        final reg  = (s['region'] ?? '').toString().toLowerCase();
                                        final div  = (s['division'] ?? '').toString().toLowerCase();
                                        final town = (s['town'] ?? '').toString().toLowerCase();
                                        final q    = _userSearchQuery.toLowerCase();
                                        return q.isEmpty || name.contains(q) || reg.contains(q) || div.contains(q) || town.contains(q);
                                      }).toList();

                                      return Container(
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
                                      );
                                    },
                                  );
                                ] else ...[
                                  Builder(
                                    builder: (ctx) {
                                      final filteredUsers = _allUsersList.where((u) {"""

text = text.replace(old_table_header, new_table_header)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('SUCCESSFULLY ADDED SCHOOLS LISTING TO ADMIN DASHBOARD')
