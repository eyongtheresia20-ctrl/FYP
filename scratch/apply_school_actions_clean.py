with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add the 3 school methods before `void _showAddSchoolDialog() {`
methods_code = '''  void _showEditSchoolDialog(Map<String, dynamic> school) {
    final schoolId = _parseInt(school['id']);
    final nameCtrl = TextEditingController(text: (school['name'] ?? '').toString());
    final townCtrl = TextEditingController(text: (school['town'] ?? '').toString());

    String selectedRegion = (school['region'] ?? 'ADAMOUA').toString();
    List<String> currentDivisions = _getDivisionsForRegion(selectedRegion);
    String selectedDivision = (school['division'] ?? '').toString();
    if (!currentDivisions.contains(selectedDivision)) {
      selectedDivision = currentDivisions.isNotEmpty ? currentDivisions.first : 'DJEREM';
    }

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
                const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEn ? "Modify School Details" : "Modifier l'Établissement",
                    style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isEn ? "School Name:" : "Nom de l'Établissement :", style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: _text, fontSize: 13),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF0284C7), size: 18),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(_isEn ? "Region:" : "Région :", style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRegion,
                      isExpanded: true,
                      dropdownColor: _card,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
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

                    Text(_isEn ? "Division / Department:" : "Département :", style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDivision,
                      isExpanded: true,
                      dropdownColor: _card,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
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

                    Text(_isEn ? "Town / City:" : "Ville :", style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: townCtrl,
                      style: TextStyle(color: _text, fontSize: 13),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined, color: _green, size: 18),
                        filled: true,
                        fillColor: _bg,
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
                child: Text(_isEn ? "Cancel" : "Annuler", style: TextStyle(color: _sub)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: Text(_isEn ? "Save Changes" : "Enregistrer", style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final town = townCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? "Please enter a school name" : "Veuillez saisir un nom")));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    final resp = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=update_school'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'id': schoolId,
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: _green, content: Text(_isEn ? "School updated successfully!" : "Établissement mis à jour avec succès !")),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.redAccent, content: Text(res['message'] ?? 'Failed to update school')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleSchoolStatus(Map<String, dynamic> school, int newStatus) async {
    final schoolId = _parseInt(school['id']);
    final schoolName = (school['name'] ?? '').toString();
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=toggle_school_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': schoolId,
          'name': schoolName,
          'is_active': newStatus,
        }),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        if (mounted) {
          final msg = newStatus == 1 
              ? (_isEn ? "School unblocked / activated!" : "Établissement débloqué / activé !")
              : (_isEn ? "School blocked / suspended!" : "Établissement bloqué / suspendu !");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: newStatus == 1 ? _green : Colors.orange, content: Text(msg)));
          _fetchAllUsersAndSchools();
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteSchool(Map<String, dynamic> school) async {
    final schoolId = _parseInt(school['id']);
    final schoolName = (school['name'] ?? '').toString();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isEn ? "Delete School Record" : "Supprimer l'Établissement",
                style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          _isEn
              ? 'Are you sure you want to permanently delete "$schoolName" from the directory? This action cannot be undone.'
              : 'Êtes-vous sûr de vouloir supprimer définitivement "$schoolName" du répertoire ? Cette action est irréversible.',
          style: TextStyle(color: _sub, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isEn ? "Cancel" : "Annuler", style: TextStyle(color: _sub)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(_isEn ? "Delete Permanently" : "Supprimer Définitivement"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final resp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/admin.php?action=delete_school'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': schoolId,
            'name': schoolName,
          }),
        );
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: _green, content: Text(_isEn ? "School deleted successfully!" : "Établissement supprimé avec succès !")),
            );
            _fetchAllUsersAndSchools();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(backgroundColor: Colors.redAccent, content: Text(data['message'] ?? 'Failed to delete school')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
        }
      }
    }
  }
'''

code = code.replace("  void _showAddSchoolDialog() {", methods_code + "\n  void _showAddSchoolDialog() {")

# 2. Replace the table rows in the schools section
old_table_section = """                                               // Full-Width Structured Table Header
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
                                               ),"""

new_table_section = """                                               // Full-Width Structured Table Header
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
                                                     Expanded(flex: 4, child: Text(_isEn ? "School Name" : "Nom de l'Établissement", style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Text(_isEn ? "Region" : "Région", style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Text(_isEn ? "Division" : "Département", style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Text(_isEn ? "Town / City" : "Ville", style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(_isEn ? "Status" : "Statut", style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5)))),
                                                     Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: Text(_isEn ? "Actions" : "Actions", style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5)))),
                                                   ],
                                                 ),
                                               ),
                                               const SizedBox(height: 8),

                                               // Full-Width Rows with Modify, Block/Unblock, Delete & View Stats
                                               Column(
                                                 children: filteredSchools.map<Widget>((s) {
                                                   final scName   = (s['name'] ?? '').toString();
                                                   final scReg    = (s['region'] ?? 'ADAMOUA').toString();
                                                   final scDiv    = (s['division'] ?? 'DJEREM').toString();
                                                   final scTown   = (s['town'] ?? '-').toString();
                                                   final int isAct= _parseInt(s['is_active'] ?? 1);
                                                   final bool isActive = isAct == 1;

                                                   return Container(
                                                     width: double.infinity,
                                                     margin: const EdgeInsets.only(bottom: 8),
                                                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                     decoration: BoxDecoration(
                                                       color: _bg,
                                                       borderRadius: BorderRadius.circular(12),
                                                       border: Border.all(color: isActive ? _border.withValues(alpha: 0.7) : Colors.redAccent.withValues(alpha: 0.3)),
                                                     ),
                                                     child: Row(
                                                       children: [
                                                         // School Name
                                                         Expanded(
                                                           flex: 4,
                                                           child: Row(
                                                             children: [
                                                               Container(
                                                                 padding: const EdgeInsets.all(8),
                                                                 decoration: BoxDecoration(
                                                                   color: (isActive ? const Color(0xFF0284C7) : Colors.redAccent).withValues(alpha: 0.14),
                                                                   shape: BoxShape.circle,
                                                                 ),
                                                                 child: Icon(
                                                                   isActive ? Icons.school_rounded : Icons.block_rounded,
                                                                   color: isActive ? const Color(0xFF0284C7) : Colors.redAccent,
                                                                   size: 18,
                                                                 ),
                                                               ),
                                                               const SizedBox(width: 10),
                                                               Expanded(
                                                                 child: Text(
                                                                   scName,
                                                                   style: TextStyle(
                                                                     color: isActive ? _text : _sub,
                                                                     fontWeight: FontWeight.w800,
                                                                     fontSize: 13,
                                                                     decoration: isActive ? null : TextDecoration.lineThrough,
                                                                   ),
                                                                   overflow: TextOverflow.ellipsis,
                                                                 ),
                                                               ),
                                                             ],
                                                           ),
                                                         ),

                                                         // Region Badge
                                                         Expanded(
                                                           flex: 2,
                                                           child: Align(
                                                             alignment: Alignment.centerLeft,
                                                             child: Container(
                                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                               decoration: BoxDecoration(
                                                                 color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                                                 borderRadius: BorderRadius.circular(8),
                                                                 border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.25)),
                                                               ),
                                                               child: Text(scReg, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                                                             ),
                                                           ),
                                                         ),

                                                         // Division Badge
                                                         Expanded(
                                                           flex: 2,
                                                           child: Align(
                                                             alignment: Alignment.centerLeft,
                                                             child: Container(
                                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                               decoration: BoxDecoration(
                                                                 color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                                                 borderRadius: BorderRadius.circular(8),
                                                                 border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
                                                               ),
                                                               child: Text(scDiv, style: const TextStyle(color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                                                             ),
                                                           ),
                                                         ),

                                                         // Town
                                                         Expanded(
                                                           flex: 2,
                                                           child: Row(
                                                             children: [
                                                               Icon(Icons.location_on_rounded, color: _sub, size: 15),
                                                               const SizedBox(width: 4),
                                                               Expanded(
                                                                 child: Text(
                                                                   scTown,
                                                                   style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600),
                                                                   overflow: TextOverflow.ellipsis,
                                                                 ),
                                                               ),
                                                             ],
                                                           ),
                                                         ),

                                                         // Status Badge (Active vs Blocked)
                                                         Expanded(
                                                           flex: 2,
                                                           child: Align(
                                                             alignment: Alignment.centerLeft,
                                                             child: Container(
                                                               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                               decoration: BoxDecoration(
                                                                 color: (isActive ? _green : Colors.redAccent).withValues(alpha: 0.14),
                                                                 borderRadius: BorderRadius.circular(8),
                                                                 border: Border.all(color: (isActive ? _green : Colors.redAccent).withValues(alpha: 0.35)),
                                                               ),
                                                               child: Row(
                                                                 mainAxisSize: MainAxisSize.min,
                                                                 children: [
                                                                   Icon(isActive ? Icons.check_circle_rounded : Icons.cancel_rounded, color: isActive ? _green : Colors.redAccent, size: 13),
                                                                   const SizedBox(width: 4),
                                                                   Text(
                                                                     isActive ? (_isEn ? "Active" : "Actif") : (_isEn ? "Blocked" : "Bloqué"),
                                                                     style: TextStyle(color: isActive ? _green : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11),
                                                                   ),
                                                                 ],
                                                               ),
                                                             ),
                                                           ),
                                                         ),

                                                         // Actions Row (View Stats, Modify, Block/Unblock, Delete)
                                                         Expanded(
                                                           flex: 4,
                                                           child: Row(
                                                             mainAxisAlignment: MainAxisAlignment.end,
                                                             children: [
                                                               // View Stats
                                                               ElevatedButton(
                                                                 style: ElevatedButton.styleFrom(
                                                                   backgroundColor: _green,
                                                                   foregroundColor: Colors.white,
                                                                   elevation: 0,
                                                                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                                 ),
                                                                 onPressed: () {
                                                                   setState(() {
                                                                     _currentNavIndex = 2;
                                                                     _fetchSchoolDetails(scName);
                                                                   });
                                                                 },
                                                                 child: Text(_isEn ? "View Stats" : "Stats", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                                               ),
                                                               const SizedBox(width: 6),

                                                               // Modify (Edit)
                                                               Container(
                                                                 decoration: BoxDecoration(
                                                                   color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                                                   borderRadius: BorderRadius.circular(8),
                                                                 ),
                                                                 child: IconButton(
                                                                   constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                                   padding: const EdgeInsets.all(6),
                                                                   icon: const Icon(Icons.edit_rounded, color: Color(0xFF0284C7), size: 16),
                                                                   tooltip: _isEn ? "Modify School" : "Modifier l'Établissement",
                                                                   onPressed: () => _showEditSchoolDialog(s),
                                                                 ),
                                                               ),
                                                               const SizedBox(width: 6),

                                                               // Block / Unblock Toggle
                                                               Container(
                                                                 decoration: BoxDecoration(
                                                                   color: (isActive ? Colors.orange : _green).withValues(alpha: 0.12),
                                                                   borderRadius: BorderRadius.circular(8),
                                                                 ),
                                                                 child: IconButton(
                                                                   constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                                   padding: const EdgeInsets.all(6),
                                                                   icon: Icon(isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded, color: isActive ? Colors.orange : _green, size: 16),
                                                                   tooltip: isActive ? (_isEn ? "Block School" : "Bloquer l'Établissement") : (_isEn ? "Unblock School" : "Débloquer l'Établissement"),
                                                                   onPressed: () => _toggleSchoolStatus(s, isActive ? 0 : 1),
                                                                 ),
                                                               ),
                                                               const SizedBox(width: 6),

                                                               // Delete
                                                               Container(
                                                                 decoration: BoxDecoration(
                                                                   color: Colors.redAccent.withValues(alpha: 0.12),
                                                                   borderRadius: BorderRadius.circular(8),
                                                                 ),
                                                                 child: IconButton(
                                                                   constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                                                   padding: const EdgeInsets.all(6),
                                                                   icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                                                   tooltip: _isEn ? "Delete School" : "Supprimer l'Établissement",
                                                                   onPressed: () => _deleteSchool(s),
                                                                 ),
                                                               ),
                                                             ],
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   );
                                                 }).toList(),
                                               ),"""

if old_table_section in code:
    code = code.replace(old_table_section, new_table_section)
    print("SUCCESS: REPLACED TABLE SECTION EXACTLY")
else:
    print("WARNING: old_table_section NOT EXACT MATCH")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(code)
