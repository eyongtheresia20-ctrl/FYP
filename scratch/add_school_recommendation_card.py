with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

target = """                                            Wrap(
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


                                    ],
                                  );"""

replacement = """                                            Wrap(
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

                                      // Institutional Policy Recommendation for School
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
                                                    _isEn ? 'Institutional Policy Recommendation for School' : 'Recommandation Pédagogique pour l\\'Établissement',
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
                                  );"""

if target in text:
    text = text.replace(target, replacement)
    print("SUCCESSFULLY INSERTED RECOMMENDATION CARD IN TAB 2")
else:
    print("WARNING: TARGET NOT FOUND")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)
