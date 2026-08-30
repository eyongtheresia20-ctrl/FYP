with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_block = """                            LayoutBuilder(
                              builder: (ctx, constraints) {
                                final isSmall = constraints.maxWidth < 600;
                                final width = isSmall ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;
                                return Wrap(
                                  spacing: 12, runSpacing: 12,
                                  children: [
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.school_rounded, label: _isEn ? 'Total Schools' : 'Établissements', value: '$totalSchools', color: const Color(0xFF3B82F6))),
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.groups_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF10B981))),
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'VARK Assessed' : 'Élèves Évalués', value: '$assessed', color: const Color(0xFFF59E0B))),
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.person_rounded, label: _isEn ? 'Teachers' : 'Enseignants', value: '$totalTeachers', color: const Color(0xFF8B5CF6))),
                                  ],
                                );
                              },
                            ),
                          ],

                          // ── TAB 1: NATIONAL VARK ANALYTICS & POLICY ──────────────────
                          if (_currentNavIndex == 1) ...[
                            // VARK Pie Chart Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.pie_chart_rounded, color: _green, size: 24),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(_isEn ? 'National VARK Learning Styles Breakdown' : 'Répartition VARK Nationale', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 28,
                                    runSpacing: 20,
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        height: 140,
                                        child: CustomPaint(
                                          painter: _VarkPieChartPainter(
                                            visual: visSt,
                                            auditory: audSt,
                                            kinesthetic: kinesSt,
                                            readWrite: rwSt,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 230,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _pieLegendItem(_isEn ? 'Visual Learner' : 'Visuel', visSt, const Color(0xFF3B82F6)),
                                            _pieLegendItem(_isEn ? 'Auditory Learner' : 'Auditif', audSt, const Color(0xFFEC4899)),
                                            _pieLegendItem(_isEn ? 'Kinesthetic Learner' : 'Kinesthésique', kinesSt, const Color(0xFF10B981)),
                                            _pieLegendItem(_isEn ? 'Read/Write Learner' : 'Lecture/Écriture', rwSt, const Color(0xFFF59E0B)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(_isEn ? 'National Educational Policy' : 'Directives Pédagogiques Nationales', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),"""

new_block = """                            LayoutBuilder(
                              builder: (ctx, constraints) {
                                final isSmall = constraints.maxWidth < 600;
                                final width = isSmall ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;
                                return Wrap(
                                  spacing: 12, runSpacing: 12,
                                  children: [
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.school_rounded, label: _isEn ? 'Total Schools' : 'Établissements', value: '$totalSchools', color: const Color(0xFF3B82F6))),
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.groups_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF10B981))),
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'VARK Assessed' : 'Élèves Évalués', value: '$assessed', color: const Color(0xFFF59E0B))),
                                    SizedBox(width: width, child: _overviewStatCard(icon: Icons.person_rounded, label: _isEn ? 'Teachers' : 'Enseignants', value: '$totalTeachers', color: const Color(0xFF8B5CF6))),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // National VARK Learning Styles Breakdown Card (EXCLUSIVELY IN TAB 0: DASHBOARD OVERVIEW)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(20), border: Border.all(color: _border)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.pie_chart_rounded, color: _green, size: 24),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(_isEn ? 'National VARK Learning Styles Breakdown' : 'Répartition VARK Nationale', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 28,
                                    runSpacing: 20,
                                    children: [
                                      SizedBox(
                                        width: 140,
                                        height: 140,
                                        child: CustomPaint(
                                          painter: _VarkPieChartPainter(
                                            visual: visSt,
                                            auditory: audSt,
                                            kinesthetic: kinesSt,
                                            readWrite: rwSt,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 230,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _pieLegendItem(_isEn ? 'Visual Learner' : 'Visuel', visSt, const Color(0xFF3B82F6)),
                                            _pieLegendItem(_isEn ? 'Auditory Learner' : 'Auditif', audSt, const Color(0xFFEC4899)),
                                            _pieLegendItem(_isEn ? 'Kinesthetic Learner' : 'Kinesthésique', kinesSt, const Color(0xFF10B981)),
                                            _pieLegendItem(_isEn ? 'Read/Write Learner' : 'Lecture/Écriture', rwSt, const Color(0xFFF59E0B)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // ── TAB 1: NATIONAL VARK ANALYTICS & POLICY ──────────────────
                          if (_currentNavIndex == 1) ...[
                            Text(_isEn ? 'National Educational Policy' : 'Directives Pédagogiques Nationales', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),"""

if old_block in text:
    text = text.replace(old_block, new_block, 1)
    print("SUCCESS: REPLACED BLOCK EXACTLY")
else:
    print("WARNING: EXACT MATCH NOT FOUND")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)
