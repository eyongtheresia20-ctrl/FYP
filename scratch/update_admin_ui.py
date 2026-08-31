with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Update National Policy evaluate call (line ~1860)
old_nat_call = """    final educatorNationalRec = VarkAcademicEngine.evaluateForEducators(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
      contextName: 'National Territory',
    );"""

new_nat_call = """    final educatorNationalRec = VarkAcademicEngine.evaluateForEducators(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
      contextName: 'National Territory',
      isNationalLevel: true,
    );"""

if old_nat_call in code:
    code = code.replace(old_nat_call, new_nat_call)
    print("SUCCESS: UPDATED NATIONAL POLICY CALL")
else:
    print("WARNING: old_nat_call not found")

# 2. Update Header & Filter Row in User & Security Admin (Tab 3)
# Find the header row in Tab 3:
old_header_filter = """                                 // Header Row
                                 LayoutBuilder(
                                   builder: (context, headerConstraints) {
                                     final isMobileHeader = headerConstraints.maxWidth < 600;
                                     return Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               Text(_isEn ? 'User & System Governance' : 'Gestion des Utilisateurs & Sécurité', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),
                                               const SizedBox(height: 2),
                                               Text(_isEn ? 'Direct database access for account creation & role assignment' : 'Accès direct à la base de données pour la création des comptes', style: TextStyle(color: _sub, fontSize: 12.5)),
                                             ],
                                           ),
                                         ),
                                         const SizedBox(width: 12),
                                         ElevatedButton.icon(
                                           style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                           onPressed: _showAddUserDialog,
                                           icon: const Icon(Icons.person_add_rounded, size: 18),
                                           label: Text(_isEn ? '+ Create User' : '+ Créer un Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                         ),
                                       ],
                                     );
                                   },
                                 ),
                                 const SizedBox(height: 16),

                                 // Users Filter & Search Row
                                 LayoutBuilder(
                                   builder: (context, filterConstraints) {
                                     final isMobileFilter = filterConstraints.maxWidth < 500;
                                     final searchField = TextField(
                                       onChanged: (val) => setState(() => _userSearchQuery = val),
                                       style: TextStyle(color: _text),
                                       decoration: InputDecoration(
                                         hintText: _isEn ? 'Search by name or matricule...' : 'Rechercher par nom ou matricule...',
                                         hintStyle: TextStyle(color: _sub, fontSize: 12.5),
                                         prefixIcon: Icon(Icons.search_rounded, color: _sub, size: 20),
                                         filled: true, fillColor: _bg,
                                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                         contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                       ),
                                     );

                                     final roleDropdown = Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 10),
                                       decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                                       child: DropdownButtonHideUnderline(
                                         child: DropdownButton<String>(
                                           value: _userRoleFilter,
                                           isExpanded: isMobileFilter,
                                           dropdownColor: _card,
                                           style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12.5),
                                           items: [
                                             DropdownMenuItem(value: 'ALL', child: Text(_isEn ? 'All Roles' : 'Tous les Rôles')),
                                             DropdownMenuItem(value: 'regional_delegate', child: Text(_isEn ? 'Regional Delegates' : 'Délégués Régionaux')),
                                             DropdownMenuItem(value: 'divisional_delegate', child: Text(_isEn ? 'Divisional Delegates' : 'Délégués Départementaux')),
                                             DropdownMenuItem(value: 'principal', child: Text(_isEn ? 'Principals' : 'Proviseurs')),
                                             DropdownMenuItem(value: 'teacher', child: Text(_isEn ? 'Teachers' : 'Enseignants')),
                                             DropdownMenuItem(value: 'student', child: Text(_isEn ? 'Students' : 'Élèves')),
                                           ],
                                           onChanged: (val) {
                                             if (val != null) setState(() => _userRoleFilter = val);
                                           },
                                         ),
                                       ),
                                     );

                                     return Container(
                                       padding: const EdgeInsets.all(12),
                                       decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                                       child: isMobileFilter
                                           ? Column(
                                               children: [
                                                 searchField,
                                                 const SizedBox(height: 10),
                                                 SizedBox(width: double.infinity, child: roleDropdown),
                                               ],
                                             )
                                           : Row(
                                               children: [
                                                 Expanded(child: searchField),
                                                 const SizedBox(width: 12),
                                                 roleDropdown,
                                               ],
                                             ),
                                     );
                                   },
                                 ),"""

new_header_filter = """                                 // Header Row (Dynamic for Users vs Schools)
                                 LayoutBuilder(
                                   builder: (context, headerConstraints) {
                                     return Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Expanded(
                                           child: Column(
                                             crossAxisAlignment: CrossAxisAlignment.start,
                                             children: [
                                               Text(
                                                 !_showSchoolsSection
                                                     ? (_isEn ? "User & System Governance" : "Gestion des Utilisateurs & Sécurité")
                                                     : (_isEn ? "Schools & Institutions Directory" : "Répertoire des Établissements"),
                                                 style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18),
                                               ),
                                               const SizedBox(height: 2),
                                               Text(
                                                 !_showSchoolsSection
                                                     ? (_isEn ? "Direct database access for account creation & role assignment" : "Accès direct à la base de données pour la création des comptes")
                                                     : (_isEn ? "Institutional secondary & technical schools database" : "Base de données des établissements scolaires enregistrés"),
                                                 style: TextStyle(color: _sub, fontSize: 12.5),
                                               ),
                                             ],
                                           ),
                                         ),
                                         const SizedBox(width: 12),
                                         ElevatedButton.icon(
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: !_showSchoolsSection ? _green : const Color(0xFF0284C7),
                                             foregroundColor: Colors.white,
                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                           ),
                                           onPressed: !_showSchoolsSection ? _showAddUserDialog : _showAddSchoolDialog,
                                           icon: Icon(!_showSchoolsSection ? Icons.person_add_rounded : Icons.add_business_rounded, size: 18),
                                           label: Text(
                                             !_showSchoolsSection
                                                 ? (_isEn ? "+ Create User" : "+ Créer un Utilisateur")
                                                 : (_isEn ? "+ Add School" : "+ Ajouter un Établissement"),
                                             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                           ),
                                         ),
                                       ],
                                     );
                                   },
                                 ),
                                 const SizedBox(height: 16),

                                 // Search & Filter Row (Role dropdown only visible for Users)
                                 LayoutBuilder(
                                   builder: (context, filterConstraints) {
                                     final isMobileFilter = filterConstraints.maxWidth < 500;
                                     final searchField = TextField(
                                       onChanged: (val) => setState(() => _userSearchQuery = val),
                                       style: TextStyle(color: _text),
                                       decoration: InputDecoration(
                                         hintText: !_showSchoolsSection
                                             ? (_isEn ? "Search by name or matricule..." : "Rechercher par nom ou matricule...")
                                             : (_isEn ? "Search by school name, region, division, town..." : "Rechercher par nom d'établissement, région, département, ville..."),
                                         hintStyle: TextStyle(color: _sub, fontSize: 12.5),
                                         prefixIcon: Icon(Icons.search_rounded, color: _sub, size: 20),
                                         filled: true, fillColor: _bg,
                                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                         contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                       ),
                                     );

                                     if (_showSchoolsSection) {
                                       // Full-width search bar for schools without irrelevant user-role dropdown
                                       return Container(
                                         padding: const EdgeInsets.all(12),
                                         decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                                         child: searchField,
                                       );
                                     }

                                     final roleDropdown = Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 10),
                                       decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                                       child: DropdownButtonHideUnderline(
                                         child: DropdownButton<String>(
                                           value: _userRoleFilter,
                                           isExpanded: isMobileFilter,
                                           dropdownColor: _card,
                                           style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12.5),
                                           items: [
                                             DropdownMenuItem(value: 'ALL', child: Text(_isEn ? 'All Roles' : 'Tous les Rôles')),
                                             DropdownMenuItem(value: 'regional_delegate', child: Text(_isEn ? 'Regional Delegates' : 'Délégués Régionaux')),
                                             DropdownMenuItem(value: 'divisional_delegate', child: Text(_isEn ? 'Divisional Delegates' : 'Délégués Départementaux')),
                                             DropdownMenuItem(value: 'principal', child: Text(_isEn ? 'Principals' : 'Proviseurs')),
                                             DropdownMenuItem(value: 'teacher', child: Text(_isEn ? 'Teachers' : 'Enseignants')),
                                             DropdownMenuItem(value: 'student', child: Text(_isEn ? 'Students' : 'Élèves')),
                                           ],
                                           onChanged: (val) {
                                             if (val != null) setState(() => _userRoleFilter = val);
                                           },
                                         ),
                                       ),
                                     );

                                     return Container(
                                       padding: const EdgeInsets.all(12),
                                       decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(14), border: Border.all(color: _border)),
                                       child: isMobileFilter
                                           ? Column(
                                               children: [
                                                 searchField,
                                                 const SizedBox(height: 10),
                                                 SizedBox(width: double.infinity, child: roleDropdown),
                                               ],
                                             )
                                           : Row(
                                               children: [
                                                 Expanded(child: searchField),
                                                 const SizedBox(width: 12),
                                                 roleDropdown,
                                               ],
                                             ),
                                     );
                                   },
                                 ),"""

if old_header_filter in code:
    code = code.replace(old_header_filter, new_header_filter)
    print("SUCCESS: REPLACED HEADER AND FILTER ROW EXACTLY")
else:
    print("WARNING: old_header_filter not found exact match")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(code)
