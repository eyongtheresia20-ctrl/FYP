with open(r'lib/views/dashboards/delegate_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

old_delegate_school_breakdown = """                                          // School VARK Percentages Breakdown
                                          Text(
                                            _isEn ? 'School-Wide VARK Learning Styles & Percentages:' : 'Répartition & Pourcentages VARK de l\\'Établissement :',
                                            style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                                          ),
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 10, runSpacing: 8,
                                            children: [
                                              _varkBadge(_isEn ? 'Visual' : 'Visuel', scVisTotal, const Color(0xFF3B82F6)),
                                              _varkBadge(_isEn ? 'Auditory' : 'Auditif', scAudTotal, const Color(0xFFEC4899)),
                                              _varkBadge(_isEn ? 'Kinesthetic' : 'Kinesthésique', scKinTotal, const Color(0xFF10B981)),
                                              _varkBadge(_isEn ? 'Read/Write' : 'Lecture/Écriture', scRwTotal, const Color(0xFFF59E0B)),
                                            ],
                                          ),"""

new_delegate_school_breakdown = """                                          // School-Wide VARK Pie Chart & Legend
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
                                                    visual: scVisTotal,
                                                    auditory: scAudTotal,
                                                    kinesthetic: scKinTotal,
                                                    readWrite: scRwTotal,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: 240,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    _pieLegendItem(_isEn ? 'Visual Learner' : 'Visuel', scVisTotal, const Color(0xFF3B82F6)),
                                                    _pieLegendItem(_isEn ? 'Auditory Learner' : 'Auditif', scAudTotal, const Color(0xFFEC4899)),
                                                    _pieLegendItem(_isEn ? 'Kinesthetic Learner' : 'Kinesthésique', scKinTotal, const Color(0xFF10B981)),
                                                    _pieLegendItem(_isEn ? 'Read/Write Learner' : 'Lecture/Écriture', scRwTotal, const Color(0xFFF59E0B)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),"""

if old_delegate_school_breakdown in text:
    text = text.replace(old_delegate_school_breakdown, new_delegate_school_breakdown)
    print("SUCCESS: REPLACED DELEGATE BREAKDOWN WITH PIE CHART & LEGEND")
else:
    print("WARNING: TARGET BREAKDOWN NOT FOUND")

# Also add Region and Division subtitle to the school header in Tab 2
old_header_sub = """                                                    Text(
                                                      _isEn ? 'Global School Statistics' : 'Statistiques Globales de l\\'Établissement',
                                                      style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      scName,
                                                      style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 17),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),"""

new_header_sub = """                                                    Text(
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
                                                      '${_isEn ? "Region" : "Région"}: ${_currentUser.region ?? "ADAMOUA"} • ${_isEn ? "Division" : "Département"}: ${activeDivisionName.isNotEmpty ? activeDivisionName : (_currentUser.division ?? "DJEREM")}',
                                                      style: TextStyle(color: _sub, fontSize: 12),
                                                    ),"""

if old_header_sub in text:
    text = text.replace(old_header_sub, new_header_sub)
    print("SUCCESS: UPDATED HEADER SUBTITLE")

with open(r'lib/views/dashboards/delegate_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)
