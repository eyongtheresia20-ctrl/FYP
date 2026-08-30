with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Place National VARK Breakdown in Tab 0 and remove it from Tab 1
old_tab0_and_1 = """                                  return Wrap(
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

new_tab0_and_1 = """                                  return Wrap(
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

                              // National VARK Learning Styles Breakdown Card in Dashboard Overview
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

text = text.replace(old_tab0_and_1, new_tab0_and_1)

# 2. Remove Institutional Policy Directive Card from Tab 2
old_tab2_directive = """                                      // Institutional Policy Directive Card
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
                                      ),"""

text = text.replace(old_tab2_directive, "")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('SUCCESSFULLY UPDATED TAB 0, TAB 1, AND REMOVED TAB 2 DIRECTIVE CARD')
