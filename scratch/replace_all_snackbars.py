with open('lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace Add School Save
old_add_school_btn = """                onPressed: () async {
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
                },"""

new_add_school_btn = """                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final div  = divisionCtrl.text.trim().toUpperCase();
                  final town = townCtrl.text.trim();
                  if (name.isEmpty) {
                    _showToast(_isEn ? "Please enter a school name" : "Veuillez saisir un nom d'établissement", isWarning: true);
                    return;
                  }
                  if (div.isEmpty) {
                    _showToast(_isEn ? "Please specify a division" : "Veuillez préciser le département", isWarning: true);
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
                    _showToast(_isEn ? "School '$name' registered successfully!" : "Établissement '$name' enregistré avec succès !");
                    _fetchAllUsersAndSchools();
                  } catch (e) {
                    _showToast(_isEn ? "Failed to register school" : "Échec de l'enregistrement de l'établissement", isError: true);
                  }
                },"""

if old_add_school_btn in code:
    code = code.replace(old_add_school_btn, new_add_school_btn)
    print("SUCCESS: Replaced Add School Save button handler")
else:
    print("WARNING: old_add_school_btn not matched exact")

# Replace Add User Save
old_add_user_btn = """                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || matCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? 'Please fill required fields.' : 'Veuillez remplir les champs requis.'), backgroundColor: Colors.red));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    final resp = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=create_user'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'full_name': nameCtrl.text.trim(),
                        'role': selectedRole,
                        'matricule': matCtrl.text.trim(),
                        'gender': selectedRole == 'student' ? selectedGender : '',
                        'birth_date': selectedRole == 'student' ? birthDateCtrl.text.trim() : '',
                        'email': '',
                        'phone': '',
                        'region': selectedRegion,
                        'division': selectedRole == 'regional_delegate' ? '' : selectedDivision,
                        'school_id': selectedSchoolId,
                        'class_name': classCtrl.text.trim(),
                        'subject': subjectCtrl.text.trim(),
                      }),
                    );
                    final data = jsonDecode(resp.body);
                    if (data['success'] == true) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_isEn ? 'User created successfully!' : 'Utilisateur créé avec succès !'), backgroundColor: _green),
                        );
                        _fetchAllUsersAndSchools();
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Error creating user'), backgroundColor: Colors.red));
                      }
                    }
                  } catch (err) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red));
                    }
                  }
                },"""

new_add_user_btn = """                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || matCtrl.text.trim().isEmpty) {
                    _showToast(_isEn ? 'Please fill required fields (Name & Matricule).' : 'Veuillez remplir les champs requis (Nom & Matricule).', isWarning: true);
                    return;
                  }
                  final userName = nameCtrl.text.trim();
                  Navigator.pop(ctx);
                  try {
                    final resp = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=create_user'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'full_name': userName,
                        'role': selectedRole,
                        'matricule': matCtrl.text.trim(),
                        'gender': selectedRole == 'student' ? selectedGender : '',
                        'birth_date': selectedRole == 'student' ? birthDateCtrl.text.trim() : '',
                        'email': '',
                        'phone': '',
                        'region': selectedRegion,
                        'division': selectedRole == 'regional_delegate' ? '' : selectedDivision,
                        'school_id': selectedSchoolId,
                        'class_name': classCtrl.text.trim(),
                        'subject': subjectCtrl.text.trim(),
                      }),
                    );
                    _showToast(_isEn ? "User '$userName' created successfully!" : "Utilisateur '$userName' créé avec succès !");
                    _fetchAllUsersAndSchools();
                  } catch (err) {
                    _showToast(_isEn ? 'Failed to create user account' : 'Échec de création du compte', isError: true);
                  }
                },"""

if old_add_user_btn in code:
    code = code.replace(old_add_user_btn, new_add_user_btn)
    print("SUCCESS: Replaced Add User Save button handler")
else:
    print("WARNING: old_add_user_btn not matched exact")

# Replace report download snackbar
old_report_snack = """              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isEn ? 'National Report Downloaded Successfully!' : 'Rapport National Téléchargé avec Succès !'), backgroundColor: _green),
              );"""

new_report_snack = """              Navigator.pop(ctx);
              _showToast(_isEn ? 'National Report Downloaded Successfully!' : 'Rapport National Téléchargé avec Succès !');"""

if old_report_snack in code:
    code = code.replace(old_report_snack, new_report_snack)
    print("SUCCESS: Replaced Report download snackbar")

with open('lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("COMPLETED!")
