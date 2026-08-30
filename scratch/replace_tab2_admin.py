with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find start of Tab 2
start_idx = None
end_idx = None

for i, l in enumerate(lines):
    if '// ── TAB 2: SCHOOL & CLASS BREAKDOWN VIEW ──────────────────────' in l:
        start_idx = i
        break

for i in range(start_idx, len(lines)):
    if '// ── TAB 3: SYSTEM USER & GOVERNANCE DIRECTORY ───────────────' in lines[i]:
        end_idx = i
        break

print(f'Replacing Tab 2 from line {start_idx} to {end_idx}')

new_tab2_lines = [
"""                          // ── TAB 2: GLOBAL SCHOOL OVERVIEW & VARK ANALYTICS ──────────
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

                                  final aiRec = (totSt == 0 || assSt == 0)
                                      ? (_isEn
                                          ? '• Multimodal Teaching Strategy (Diagnostic Phase): Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                          : '• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                      : (_isEn
                                          ? (_classDetailsData!['ai_recommendation_en'] ?? '• Institutional Policy Directive: Coordinate with head teachers to complete VARK diagnostics and allocate audio-visual tools.')
                                          : (_classDetailsData!['ai_recommendation_fr'] ?? '• Directive Institutionnelle : Coordonnez avec les proviseurs pour finaliser les tests VARK et allouer du matériel audio-visuel.'));

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Global School Statistics & Header Card
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _green.withValues(alpha: 0.35), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _green.withValues(alpha: 0.08),
                                              blurRadius: 12,
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
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: _green.withValues(alpha: 0.14),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.account_balance_rounded, color: _green, size: 26),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _isEn ? 'Global School Overview' : 'Aperçu Global de l\\'Établissement',
                                                        style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w700),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        scName,
                                                        style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        '${_isEn ? "Region" : "Région"}: $regName • ${_isEn ? "Division" : "Département"}: $divName',
                                                        style: TextStyle(color: _sub, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            // Key Metric Cards
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
                                            const SizedBox(height: 24),

                                            // Big VARK Pie Chart & Legend for School
                                            Text(
                                              _isEn ? 'School-Wide VARK Learning Styles Breakdown:' : 'Répartition VARK de l\\'Établissement :',
                                              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 18),
                                            Wrap(
                                              alignment: WrapAlignment.center,
                                              crossAxisAlignment: WrapCrossAlignment.center,
                                              spacing: 32,
                                              runSpacing: 20,
                                              children: [
                                                SizedBox(
                                                  width: 150,
                                                  height: 150,
                                                  child: CustomPaint(
                                                    painter: _VarkPieChartPainter(
                                                      visual: vis,
                                                      auditory: aud,
                                                      kinesthetic: kin,
                                                      readWrite: rw,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 240,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      _pieLegendItem(_isEn ? 'Visual Learner' : 'Visuel', vis, const Color(0xFF3B82F6)),
                                                      _pieLegendItem(_isEn ? 'Auditory Learner' : 'Auditif', aud, const Color(0xFFEC4899)),
                                                      _pieLegendItem(_isEn ? 'Kinesthetic Learner' : 'Kinesthésique', kin, const Color(0xFF10B981)),
                                                      _pieLegendItem(_isEn ? 'Read/Write Learner' : 'Lecture/Écriture', rw, const Color(0xFFF59E0B)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Institutional Policy Directive Card
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
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
                                                Icon(Icons.auto_awesome_rounded, color: _green, size: 22),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    _isEn ? 'Institutional Policy Directive for School' : 'Directives Pédagogiques pour l\\'Établissement',
                                                    style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: _bg,
                                                borderRadius: BorderRadius.circular(14),
                                                border: Border.all(color: _border),
                                              ),
                                              child: Text(
                                                aiRec,
                                                style: TextStyle(color: _text, fontSize: 13.5, height: 1.6, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(36),
                                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
                                child: Column(
                                  children: [
                                    Icon(Icons.touch_app_rounded, color: _green, size: 40),
                                    const SizedBox(height: 12),
                                    Text(
                                      _isEn ? 'Select a School from the Left Sidebar' : 'Sélectionnez un Établissement dans le Menu de Gauche',
                                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isEn
                                          ? 'Expand Region ➔ Division ➔ School to view live statistics and institutional VARK AI policy.'
                                          : 'Déroulez Région ➔ Département ➔ Établissement pour afficher les statistiques et directives IA.',
                                      style: TextStyle(color: _sub, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
\n"""
]

lines[start_idx:end_idx] = new_tab2_lines

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print('SUCCESSFULLY REPLACED TAB 2 WITH SCHOOL OVERVIEW & BIG VARK PIE CHART')
