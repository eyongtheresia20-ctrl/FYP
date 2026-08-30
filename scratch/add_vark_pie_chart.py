with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Insert into Tab 0 under the 4 metric cards
old_tab0 = """                                  return Wrap(
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
                            ],"""

new_tab0 = """                                  return Wrap(
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

                              // National VARK Learning Styles Breakdown Card
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
                            ],"""

if old_tab0 in text:
    text = text.replace(old_tab0, new_tab0, 1)

# 2. Insert into Tab 1 (National VARK Overview) above the strategy card
old_tab1 = """                          // ── TAB 1: NATIONAL VARK ANALYTICS & POLICY ──────────────────
                          if (_currentNavIndex == 1) ...[
                            Text(_isEn ? 'National Educational Policy' : 'Directives Pédagogiques Nationales', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 16),"""

new_tab1 = """                          // ── TAB 1: NATIONAL VARK ANALYTICS & POLICY ──────────────────
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
                            Text(_isEn ? 'National Educational Policy' : 'Directives Pédagogiques Nationales', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),
                            const SizedBox(height: 16),"""

if old_tab1 in text:
    text = text.replace(old_tab1, new_tab1, 1)

# 3. Insert into Tab 2 (School Overview)
old_tab2_badges = """                                            // School VARK Percentages Breakdown
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
                                            ),"""

new_tab2_badges = """                                            // School VARK Pie Chart & Legend
                                            Text(
                                              _isEn ? 'School-Wide VARK Learning Styles Breakdown:' : 'Répartition VARK de l\\'Établissement :',
                                              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            const SizedBox(height: 16),
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
                                                      visual: vis,
                                                      auditory: aud,
                                                      kinesthetic: kin,
                                                      readWrite: rw,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 230,
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
                                            ),"""

if old_tab2_badges in text:
    text = text.replace(old_tab2_badges, new_tab2_badges, 1)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('VARK PIE CHART SUCCESSFULLY ADDED TO TAB 0, TAB 1, AND TAB 2 OF ADMIN DASHBOARD')
