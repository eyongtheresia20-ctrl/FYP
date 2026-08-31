with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. New _showEditSchoolDialog
new_edit_dialog = '''  void _showEditSchoolDialog(Map<String, dynamic> school) {
    final schoolId = _parseInt(school['id']);
    final nameCtrl = TextEditingController(text: (school['name'] ?? '').toString());
    final townCtrl = TextEditingController(text: (school['town'] ?? '').toString());
    final divisionCtrl = TextEditingController(text: (school['division'] ?? '').toString());
    String selectedRegion = (school['region'] ?? 'ADAMOUA').toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: Color(0xFF0284C7), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEn ? "Modify School Record" : "Modifier l'Établissement",
                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEn ? "Update institutional details & administrative location" : "Mettre à jour les informations et l'emplacement administratif",
                        style: TextStyle(color: _sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: 580,
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // School Name
                    Row(
                      children: [
                        const Icon(Icons.school_rounded, color: Color(0xFF0284C7), size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "School Name *" : "Nom de l'Établissement *", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _isEn ? "e.g. LYCEE CLASSIQUE DE BAFOUSSAM" : "ex: LYCEE CLASSIQUE DE BAFOUSSAM",
                        prefixIcon: const Icon(Icons.business_rounded, color: Color(0xFF0284C7), size: 18),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Region Dropdown
                    Row(
                      children: [
                        const Icon(Icons.map_rounded, color: Color(0xFF3B82F6), size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "Region *" : "Région *", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRegion,
                      isExpanded: true,
                      dropdownColor: _card,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      items: ['ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST'].map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRegion = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Division / Department (Open Text Input)
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: Color(0xFF8B5CF6), size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "Division / Department *" : "Département *", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: divisionCtrl,
                      style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _isEn ? "e.g. MEZAM, MIFI, FAKO, WOURI, DJEREM" : "ex: MEZAM, MIFI, FAKO, WOURI, DJEREM",
                        helperText: _isEn ? "Type any division name. New divisions are automatically registered." : "Saisissez le département. Tout nouveau département est enregistré.",
                        helperStyle: TextStyle(color: _sub, fontSize: 11),
                        prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF8B5CF6), size: 18),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Town / City
                    Row(
                      children: [
                        Icon(Icons.location_city_rounded, color: _green, size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "Town / City :" : "Ville / Localité :", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: townCtrl,
                      style: TextStyle(color: _text, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: _isEn ? "e.g. Bafoussam, Bamenda, Buea, Yaounde" : "ex: Bafoussam, Bamenda, Buea, Yaoundé",
                        prefixIcon: Icon(Icons.location_on_outlined, color: _green, size: 18),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_isEn ? "Cancel" : "Annuler", style: TextStyle(color: _sub, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(_isEn ? "Save Changes" : "Enregistrer", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final div  = divisionCtrl.text.trim().toUpperCase();
                  final town = townCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? "Please enter a school name" : "Veuillez saisir un nom")));
                    return;
                  }
                  if (div.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? "Please specify a division" : "Veuillez préciser le département")));
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
                        'division': div,
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
  }'''

# 2. New _showAddSchoolDialog
new_add_dialog = '''  void _showAddSchoolDialog() {
    final nameCtrl = TextEditingController();
    final townCtrl = TextEditingController();
    final divisionCtrl = TextEditingController();
    String selectedRegion = 'ADAMOUA';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            title: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: _sub,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: _isEn ? "Back" : "Retour",
                  onPressed: () => Navigator.pop(ctx),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_business_rounded, color: _green, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEn ? "Register New School" : "Ajouter un Établissement",
                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEn ? "Enroll a new secondary or technical school into the national system" : "Enregistrer un établissement secondaire ou technique",
                        style: TextStyle(color: _sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: 580,
                constraints: const BoxConstraints(maxWidth: 580),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // School Name
                    Row(
                      children: [
                        Icon(Icons.school_rounded, color: _green, size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "School Name *" : "Nom de l'Établissement *", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _isEn ? "e.g. LYCEE BILINGUE DE BAFOUSSAM" : "ex: LYCEE BILINGUE DE BAFOUSSAM",
                        prefixIcon: Icon(Icons.business_rounded, color: _green, size: 18),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Region Dropdown
                    Row(
                      children: [
                        const Icon(Icons.map_rounded, color: Color(0xFF3B82F6), size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "Region *" : "Région *", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRegion,
                      isExpanded: true,
                      dropdownColor: _card,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      items: ['ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST'].map((r) {
                        return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRegion = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Division / Department (Open Text Input)
                    Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, color: Color(0xFF8B5CF6), size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "Division / Department *" : "Département *", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: divisionCtrl,
                      style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: _isEn ? "e.g. MEZAM, MIFI, FAKO, WOURI, DJEREM" : "ex: MEZAM, MIFI, FAKO, WOURI, DJEREM",
                        helperText: _isEn ? "Type any division name. New divisions are automatically registered." : "Saisissez le département. Tout nouveau département est enregistré.",
                        helperStyle: TextStyle(color: _sub, fontSize: 11),
                        prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF8B5CF6), size: 18),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Town / City
                    Row(
                      children: [
                        Icon(Icons.location_city_rounded, color: _green, size: 16),
                        const SizedBox(width: 6),
                        Text(_isEn ? "Town / City :" : "Ville / Localité :", style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: townCtrl,
                      style: TextStyle(color: _text, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: _isEn ? "e.g. Ngaoundal, Bafoussam, Yaounde" : "ex: Ngaoundal, Bafoussam, Yaoundé",
                        prefixIcon: Icon(Icons.location_on_outlined, color: _green, size: 18),
                        filled: true,
                        fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_isEn ? "Cancel" : "Annuler", style: TextStyle(color: _sub, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_business_rounded, size: 18),
                label: Text(_isEn ? "Create School" : "Créer l'Établissement", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final div  = divisionCtrl.text.trim().toUpperCase();
                  final town = townCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? "Please enter a school name" : "Veuillez saisir un nom")));
                    return;
                  }
                  if (div.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? "Please specify a division" : "Veuillez préciser le département")));
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
                        'division': div,
                        'town': town,
                      }),
                    );
                    final res = jsonDecode(resp.body);
                    if (res['success'] == true) {
                      _fetchAllUsersAndSchools();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: _green, content: Text(_isEn ? "School created successfully!" : "Établissement créé avec succès !")),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.redAccent, content: Text(res['message'] ?? 'Failed to create school')),
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
  }'''

# Replace in code
# Find start of _showEditSchoolDialog
idx_edit_start = code.find("  void _showEditSchoolDialog(Map<String, dynamic> school) {")
idx_edit_end = code.find("  Future<void> _toggleSchoolStatus", idx_edit_start)

# Find start of _showAddSchoolDialog
idx_add_start = code.find("  void _showAddSchoolDialog() {")
idx_add_end = code.find("  void _showAddUserDialog() {", idx_add_start)

print("idx_edit_start:", idx_edit_start, "idx_edit_end:", idx_edit_end)
print("idx_add_start:", idx_add_start, "idx_add_end:", idx_add_end)

if idx_edit_start != -1 and idx_edit_end != -1 and idx_add_start != -1 and idx_add_end != -1:
    # First replace add dialog (later in file)
    code = code[:idx_add_start] + new_add_dialog + "\n\n" + code[idx_add_end:]
    # Then replace edit dialog
    # Re-find idx_edit_start
    idx_edit_start = code.find("  void _showEditSchoolDialog(Map<String, dynamic> school) {")
    idx_edit_end = code.find("  Future<void> _toggleSchoolStatus", idx_edit_start)
    code = code[:idx_edit_start] + new_edit_dialog + "\n\n" + code[idx_edit_end:]
    
    with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("SUCCESS: REPLACED BOTH DIALOGS WITH BIGGER CUSTOM DIVISION FORMS")
else:
    print("FAILED TO LOCATE DIALOG POSITIONS")
