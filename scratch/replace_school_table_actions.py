with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read().replace('\r\n', '\n')

old_block_start = """                                               // Full-Width Structured Table Header
                                               Container(
                                                 width: double.infinity,
                                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),"""

old_block_end = """                                                 }).toList(),
                                               ),
                                             ],"""

new_block = """                                               // Full-Width Structured Table Header
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
                                                     Expanded(flex: 4, child: Text(_isEn ? 'School Name' : 'Nom de l\\'Établissement', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Text(_isEn ? 'Region' : 'Région', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Text(_isEn ? 'Division' : 'Département', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Text(_isEn ? 'Town / City' : 'Ville', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5))),
                                                     Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Text(_isEn ? 'Status' : 'Statut', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5)))),
                                                     Expanded(flex: 4, child: Align(alignment: Alignment.centerRight, child: Text(_isEn ? 'Actions' : 'Actions', style: TextStyle(color: _sub, fontWeight: FontWeight.w800, fontSize: 12.5)))),
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
                                                                 child: Column(
                                                                   crossAxisAlignment: CrossAxisAlignment.start,
                                                                   children: [
                                                                     Text(
                                                                       scName,
                                                                       style: TextStyle(
                                                                         color: isActive ? _text : _sub,
                                                                         fontWeight: FontWeight.w800,
                                                                         fontSize: 13,
                                                                         decoration: isActive ? null : TextDecoration.lineThrough,
                                                                       ),
                                                                       overflow: TextOverflow.ellipsis,
                                                                     ),
                                                                   ],
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
                                                                     isActive ? (_isEn ? 'Active' : 'Actif') : (_isEn ? 'Blocked' : 'Bloqué'),
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
                                                                 child: Text(_isEn ? 'View Stats' : 'Stats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
                                                                   tooltip: _isEn ? 'Modify School' : 'Modifier l\\'Établissement',
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
                                                                   tooltip: isActive ? (_isEn ? 'Block School' : 'Bloquer l\\'Établissement') : (_isEn ? 'Unblock School' : 'Débloquer l\\'Établissement'),
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
                                                                   tooltip: _isEn ? 'Delete School' : 'Supprimer l\\'Établissement',
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
                                               ),
                                             ],"""

idx_s = text.find(old_block_start)
idx_e = text.find(old_block_end, idx_s) + len(old_block_end) if idx_s != -1 else -1

if idx_s != -1 and idx_e != -1:
    text = text[:idx_s] + new_block + text[idx_e:]
    print("SUCCESS: REPLACED SCHOOL DIRECTORY TABLE ACTIONS IN ADMIN DASHBOARD")
else:
    print(f"FAILED: idx_s={idx_s}, idx_e={idx_e}")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)
