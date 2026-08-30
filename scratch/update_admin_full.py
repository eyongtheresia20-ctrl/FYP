import re

with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add _showSchoolsSection state variable if not present
if 'bool _showSchoolsSection = false;' not in text:
    text = text.replace(
        '  String _userRoleFilter = \'ALL\';',
        '  String _userRoleFilter = \'ALL\';\n  bool _showSchoolsSection = false;'
    )

# 2. Add National VARK Breakdown Card to Tab 0 under National System Metrics grid
old_tab0_end = """                                  return Wrap(
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

new_tab0_end = """                                  return Wrap(
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

text = text.replace(old_tab0_end, new_tab0_end)

# 3. Add _showAddSchoolDialog method
add_school_code = """  void _showAddSchoolDialog() {
    final nameCtrl = TextEditingController();
    final townCtrl = TextEditingController();
    String selectedRegion = 'ADAMOUA';
    List<String> currentDivisions = _getDivisionsForRegion(selectedRegion);
    String selectedDivision = currentDivisions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: _sub,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _isEn ? 'Back' : 'Retour',
                  onPressed: () => Navigator.pop(ctx),
                ),
                const SizedBox(width: 8),
                Icon(Icons.add_business_rounded, color: _green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEn ? 'Register New School' : 'Ajouter un Établissement',
                    style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // School Name
                    Text(_isEn ? 'School Name:' : 'Nom de l\\'Établissement :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: _text, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. LYCEE BILINGUE DE BAFOUSSAM',
                        prefixIcon: Icon(Icons.school_outlined, color: _green, size: 18),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Region Dropdown
                    Text(_isEn ? 'Region:' : 'Région :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedRegion,
                      isExpanded: true,
                      dropdownColor: _card,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: ['ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST'].map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedRegion = val;
                            currentDivisions = _getDivisionsForRegion(selectedRegion);
                            selectedDivision = currentDivisions.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Division Dropdown
                    Text(_isEn ? 'Division / Department:' : 'Département :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedDivision,
                      isExpanded: true,
                      dropdownColor: _card,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: currentDivisions.map((d) {
                        return DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedDivision = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Town
                    Text(_isEn ? 'Town / City:' : 'Ville :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: townCtrl,
                      style: TextStyle(color: _text, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Ngaoundal',
                        prefixIcon: Icon(Icons.location_on_outlined, color: _green, size: 18),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final town = townCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? 'Please enter a school name' : 'Veuillez saisir un nom d\\'établissement')));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    final resp = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=create_school'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'name': name,
                        'region': selectedRegion,
                        'division': selectedDivision,
                        'town': town,
                      }),
                    );
                    final res = jsonDecode(resp.body);
                    if (res['success'] == true) {
                      _fetchAllUsersAndSchools();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: _green, content: Text(_isEn ? 'School created successfully!' : 'Établissement créé avec succès !')));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text(res['message'] ?? 'Failed to create school')));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                    }
                  }
                },
                child: Text(_isEn ? 'Create School' : 'Créer Établissement', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }
"""

if 'void _showAddSchoolDialog()' not in text:
    text = text.replace('  void _showAddUserDialog() {', add_school_code + '\n  void _showAddUserDialog() {')

# 4. Add _pieLegendItem and _VarkPieChartPainter at the bottom
bottom_helpers = """  Widget _pieLegendItem(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$count',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _VarkPieChartPainter extends CustomPainter {
  final int visual;
  final int auditory;
  final int kinesthetic;
  final int readWrite;

  _VarkPieChartPainter({required this.visual, required this.auditory, required this.kinesthetic, required this.readWrite});

  @override
  void paint(Canvas canvas, Size size) {
    final int total = visual + auditory + kinesthetic + readWrite;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (total == 0) {
      final paint = Paint()..color = Colors.grey.withValues(alpha: 0.3);
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final double visAngle = (visual / total) * 2 * 3.141592653589793;
    final double audAngle = (auditory / total) * 2 * 3.141592653589793;
    final double kinAngle = (kinesthetic / total) * 2 * 3.141592653589793;
    final double rwAngle  = (readWrite / total) * 2 * 3.141592653589793;

    double startAngle = -3.141592653589793 / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    void drawSlice(double sweepAngle, Color color) {
      if (sweepAngle <= 0) return;
      final paint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);
      startAngle += sweepAngle;
    }

    drawSlice(visAngle, const Color(0xFF3B82F6));
    drawSlice(audAngle, const Color(0xFFEC4899));
    drawSlice(kinAngle, const Color(0xFF10B981));
    drawSlice(rwAngle,  const Color(0xFFF59E0B));
  }

  @override
  bool shouldRepaint(covariant _VarkPieChartPainter oldDelegate) =>
      oldDelegate.visual != visual || oldDelegate.auditory != auditory || oldDelegate.kinesthetic != kinesthetic || oldDelegate.readWrite != readWrite;
}
"""

if 'class _VarkPieChartPainter' not in text:
    # Replace the last closing brace of _AdminDashboardState
    last_idx = text.rfind('}')
    text = text[:last_idx] + bottom_helpers

# 5. In Tab 3 Header: Add '+ Add School' button and segmented tab between Users and Schools
old_tab3_header = """                                         ElevatedButton.icon(
                                           style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                           onPressed: _showAddUserDialog,
                                           icon: const Icon(Icons.person_add_rounded, size: 18),
                                           label: Text(_isEn ? '+ Create User' : '+ Créer un Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                         ),"""

new_tab3_header = """                                         Row(
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
                                         ),"""

text = text.replace(old_tab3_header, new_tab3_header)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print('ADMIN DASHBOARD FULLY UPDATED WITH VARK CHART AND SCHOOL CREATION')
