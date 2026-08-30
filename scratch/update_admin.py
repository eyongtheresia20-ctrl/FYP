import re

with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update initState initial call
text = re.sub(r"_fetchClassDetails\([^)]*\);", "_fetchSchoolDetails('LYCEE TECHNIQUE DE NGAOUNDAL');", text)

# 2. Replace _fetchClassDetails definition with _fetchSchoolDetails
old_fetch_pattern = r"Future<void> _fetchClassDetails\(String schoolName, String className\) async \{[\s\S]*?setState\(\(\) => _isLoadingClassDetails = false\);\s*\}\s*\}"
new_fetch = """Future<void> _fetchSchoolDetails(String schoolName) async {
    setState(() {
      _selectedSchoolFilter = schoolName;
      _isLoadingClassDetails = true;
    });
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_school_details&school_name=${Uri.encodeComponent(schoolName)}'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['data'] != null) {
        setState(() {
          _classDetailsData = data['data'];
          _isLoadingClassDetails = false;
        });
      } else {
        setState(() => _isLoadingClassDetails = false);
      }
    } catch (_) {
      setState(() => _isLoadingClassDetails = false);
    }
  }"""
text = re.sub(old_fetch_pattern, new_fetch, text)

# 3. Replace onClassSelected handling
old_on_class = """          if (selection.contains('::')) {
            final parts = selection.split('::');
            final scName = parts[parts.length - 2];
            final clsName = parts[parts.length - 1];
            _fetchClassDetails(scName, clsName);
          } else {
            _selectedRegionFilter = selection;
          }"""

new_on_class = """          if (selection.contains('::')) {
            final parts = selection.split('::');
            final scName = parts.last;
            _fetchSchoolDetails(scName);
          } else {
            _selectedRegionFilter = selection;
          }"""
text = text.replace(old_on_class, new_on_class)

# 4. Replace Tab 2 with Global School Statistics & Institutional Policy View
old_tab2_pattern = r"\/\/ ── TAB 2: SCHOOL & CLASS BREAKDOWN VIEW ──────────────────────[\s\S]*?if \(_currentNavIndex == 2\) \.\.\.\[[\s\S]*?\/\/ ── TAB 3: USER & SECURITY ADMINISTRATION"

new_tab2 = """// ── TAB 2: GLOBAL SCHOOL OVERVIEW & POLICY DIRECTIVES ──────────────
                          if (_currentNavIndex == 2) ...[
                            if (_isLoadingClassDetails) ...[
                              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                            ] else if (_classDetailsData != null) ...[
                              Builder(
                                builder: (ctx) {
                                  final scName  = _classDetailsData!['school_name'] ?? '';
                                  final regName = _classDetailsData!['region'] ?? 'ADAMOUA';
                                  final divName = _classDetailsData!['division'] ?? 'DJEREM';
                                  final totSt   = _parseInt(_classDetailsData!['total_students']);
                                  final totCls  = _parseInt(_classDetailsData!['total_classes'] ?? 2);
                                  final totTch  = _parseInt(_classDetailsData!['total_teachers'] ?? 1);
                                  final assSt   = _parseInt(_classDetailsData!['assessed_students']);

                                  final vis = _parseInt(_classDetailsData!['visual_count']);
                                  final aud = _parseInt(_classDetailsData!['auditory_count']);
                                  final kin = _parseInt(_classDetailsData!['kinesthetic_count']);
                                  final rw  = _parseInt(_classDetailsData!['read_write_count']);

                                  final aiRec = _isEn
                                      ? (_classDetailsData!['ai_recommendation_en'] ?? '• Institutional Policy Directive: Complete student assessments and equip classrooms with multimodal tools.')
                                      : (_classDetailsData!['ai_recommendation_fr'] ?? '• Directive Institutionnelle : Finalisez les évaluations et équipez les classes d\\'outils multimodaux.');

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Global School Statistics Card
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _green.withValues(alpha: 0.35), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _green.withValues(alpha: 0.08),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: _green.withValues(alpha: 0.14),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.account_balance_rounded, color: _green, size: 24),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _isEn ? 'Global School Statistics' : 'Statistiques Globales de l\\'Établissement',
                                                        style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w600),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        scName,
                                                        style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 17),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${_isEn ? "Region" : "Région"}: $regName • ${_isEn ? "Division" : "Département"}: $divName',
                                                        style: TextStyle(color: _sub, fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),

                                            // School Key Metrics Grid
                                            Row(
                                              children: [
                                                Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Élèves', value: '$totSt', color: const Color(0xFF3B82F6))),
                                                const SizedBox(width: 10),
                                                Expanded(child: _overviewStatCard(icon: Icons.meeting_room_rounded, label: _isEn ? 'Classes' : 'Classes', value: '$totCls', color: const Color(0xFF006A4E))),
                                                const SizedBox(width: 10),
                                                Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Teachers' : 'Enseignants', value: '$totTch', color: const Color(0xFF8B5CF6))),
                                                const SizedBox(width: 10),
                                                Expanded(child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'Assessed' : 'Évalués', value: '$assSt', color: const Color(0xFF10B981))),
                                              ],
                                            ),
                                            const SizedBox(height: 18),

                                            // School VARK Percentages Breakdown
                                            Text(
                                              _isEn ? 'School-Wide VARK Learning Styles & Percentages:' : 'Répartition & Pourcentages VARK de l\\'Établissement :',
                                              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                                            ),
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 10, runSpacing: 8,
                                              children: [
                                                _varkBadge(_isEn ? 'Visual' : 'Visuel', vis, const Color(0xFF3B82F6)),
                                                _varkBadge(_isEn ? 'Auditory' : 'Auditif', aud, const Color(0xFFEC4899)),
                                                _varkBadge(_isEn ? 'Kinesthetic' : 'Kinesthésique', kin, const Color(0xFF10B981)),
                                                _varkBadge(_isEn ? 'Read/Write' : 'Lecture/Écriture', rw, const Color(0xFFF59E0B)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Institutional Policy Directive Card
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(color: _border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.auto_awesome_rounded, color: _green, size: 20),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _isEn ? 'Institutional Policy Directive for School' : 'Recommandation Pédagogique pour l\\'Établissement',
                                                    style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: _bg,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: _border),
                                              ),
                                              child: Text(
                                                aiRec,
                                                style: TextStyle(color: _text, fontSize: 13, height: 1.6, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ],

                          // ── TAB 3: USER & SECURITY ADMINISTRATION"""

text = re.sub(old_tab2_pattern, new_tab2, text)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('SUCCESSFULLY UPDATED ADMIN DASHBOARD')
