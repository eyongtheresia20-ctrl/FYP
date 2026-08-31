with open('lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    code = f.read()

# 1. Add _showToast helper method in _AdminDashboardState
toast_helper = """  void _showToast(String message, {bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, right: 24, left: 260),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : (isWarning ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : (isWarning ? Icons.warning_amber_rounded : Icons.check_circle_rounded),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
"""

# Insert _showToast right before _toggleSchoolStatus
if "_toggleSchoolStatus" in code:
    code = code.replace("Future<void> _toggleSchoolStatus", toast_helper + "\n  Future<void> _toggleSchoolStatus")
    print("SUCCESS: Added _showToast helper method")

# 2. Update _toggleSchoolStatus
old_toggle_school = """  Future<void> _toggleSchoolStatus(Map<String, dynamic> school, int newStatus) async {
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
  }"""

new_toggle_school = """  Future<void> _toggleSchoolStatus(Map<String, dynamic> school, int newStatus) async {
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
      final msg = newStatus == 1
          ? (_isEn ? "School '$schoolName' unblocked and activated!" : "Établissement '$schoolName' débloqué et activé !")
          : (_isEn ? "School '$schoolName' blocked and suspended!" : "Établissement '$schoolName' bloqué et suspendu !");
      _showToast(msg, isWarning: newStatus == 0);
      _fetchAllUsersAndSchools();
    } catch (e) {
      _showToast(_isEn ? "Failed to update school status" : "Échec de mise à jour du statut", isError: true);
    }
  }"""

if old_toggle_school in code:
    code = code.replace(old_toggle_school, new_toggle_school)
    print("SUCCESS: Updated _toggleSchoolStatus")
else:
    print("WARNING: old_toggle_school not matched exact")

# 3. Update _deleteSchool
old_delete_school = """    if (confirm == true) {
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
    }"""

new_delete_school = """    if (confirm == true) {
      try {
        final resp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/admin.php?action=delete_school'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': schoolId,
            'name': schoolName,
          }),
        );
        _showToast(_isEn ? "School '$schoolName' deleted successfully!" : "Établissement '$schoolName' supprimé avec succès !");
        _fetchAllUsersAndSchools();
      } catch (e) {
        _showToast(_isEn ? "Failed to delete school" : "Échec de suppression de l'établissement", isError: true);
      }
    }"""

if old_delete_school in code:
    code = code.replace(old_delete_school, new_delete_school)
    print("SUCCESS: Updated _deleteSchool")
else:
    print("WARNING: old_delete_school not matched exact")

# 4. Update Edit School Dialog Save
old_edit_save = """                  if (name.isEmpty) {
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
                  }"""

new_edit_save = """                  if (name.isEmpty) {
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
                    _showToast(_isEn ? "School details updated successfully!" : "Informations de l'établissement mises à jour avec succès !");
                    _fetchAllUsersAndSchools();
                  } catch (e) {
                    _showToast(_isEn ? "Failed to save school changes" : "Échec de l'enregistrement des modifications", isError: true);
                  }"""

if old_edit_save in code:
    code = code.replace(old_edit_save, new_edit_save)
    print("SUCCESS: Updated Edit School Dialog Save")
else:
    print("WARNING: old_edit_save not matched exact")

# 5. Update Add School Dialog Save
old_add_save = """                  if (name.isEmpty) {
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
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=add_school'),
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
                          SnackBar(backgroundColor: _green, content: Text(_isEn ? "School registered successfully!" : "Établissement enregistré avec succès !")),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(backgroundColor: Colors.redAccent, content: Text(res['message'] ?? 'Failed to add school')),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')));
                    }
                  }"""

new_add_save = """                  if (name.isEmpty) {
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
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=add_school'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'name': name,
                        'region': selectedRegion,
                        'division': div,
                        'town': town,
                      }),
                    );
                    _showToast(_isEn ? "New school '$name' registered successfully!" : "Nouvel établissement '$name' enregistré avec succès !");
                    _fetchAllUsersAndSchools();
                  } catch (e) {
                    _showToast(_isEn ? "Failed to register new school" : "Échec de l'enregistrement de l'établissement", isError: true);
                  }"""

if old_add_save in code:
    code = code.replace(old_add_save, new_add_save)
    print("SUCCESS: Updated Add School Dialog Save")
else:
    print("WARNING: old_add_save not matched exact")

# 6. Update Add User Save
old_user_save = """                    if (name.isEmpty || (isStudent && (mat.isEmpty || cls.isEmpty))) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? 'Please fill required fields.' : 'Veuillez remplir les champs requis.'), backgroundColor: Colors.red));
                      return;
                    }

                    setModalState(() => isSubmitting = true);

                    try {
                      final body = {
                        'full_name': name,
                        'role': selectedRole,
                        'matricule': mat,
                        'gender': selectedGender,
                        'birth_date': birthDate,
                        'email': email,
                        'phone': phone,
                        'region': selectedRegion,
                        'division': selectedDivision,
                        'school_id': selectedSchoolId,
                        'class_name': cls,
                        'subject': subj,
                      };

                      final resp = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=create_user'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(body),
                      );

                      final data = jsonDecode(resp.body);
                      if (data['success'] == true) {
                        Navigator.pop(ctx);
                        _fetchAllUsersAndSchools();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: _green,
                              content: Text(_isEn ? 'Account created successfully!' : 'Compte créé avec succès !'),
                            ),
                          );
                        }
                      } else {
                        setModalState(() => isSubmitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'Error creating user'), backgroundColor: Colors.red));
                        }
                      }
                    } catch (err) {
                      setModalState(() => isSubmitting = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $err'), backgroundColor: Colors.red));
                      }
                    }"""

new_user_save = """                    if (name.isEmpty || (isStudent && (mat.isEmpty || cls.isEmpty))) {
                      _showToast(_isEn ? 'Please fill required fields.' : 'Veuillez remplir les champs requis.', isWarning: true);
                      return;
                    }

                    setModalState(() => isSubmitting = true);

                    try {
                      final body = {
                        'full_name': name,
                        'role': selectedRole,
                        'matricule': mat,
                        'gender': selectedGender,
                        'birth_date': birthDate,
                        'email': email,
                        'phone': phone,
                        'region': selectedRegion,
                        'division': selectedDivision,
                        'school_id': selectedSchoolId,
                        'class_name': cls,
                        'subject': subj,
                      };

                      final resp = await http.post(
                        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=create_user'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(body),
                      );

                      Navigator.pop(ctx);
                      _showToast(_isEn ? 'User account created successfully!' : 'Compte utilisateur créé avec succès !');
                      _fetchAllUsersAndSchools();
                    } catch (err) {
                      setModalState(() => isSubmitting = false);
                      _showToast(_isEn ? 'Failed to create user account' : 'Échec de la création du compte', isError: true);
                    }"""

if old_user_save in code:
    code = code.replace(old_user_save, new_user_save)
    print("SUCCESS: Updated Add User Save")
else:
    print("WARNING: old_user_save not matched exact")

# Also update user toggle status and delete user
old_user_toggle = """        final resp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/admin.php?action=toggle_user_status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': uId, 'is_activated': newStatus}),
        );
        _fetchAllUsersAndSchools();"""

new_user_toggle = """        final resp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/admin.php?action=toggle_user_status'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': uId, 'is_activated': newStatus}),
        );
        _showToast(newStatus == 1 ? (_isEn ? "User activated successfully" : "Utilisateur activé avec succès") : (_isEn ? "User blocked successfully" : "Utilisateur bloqué avec succès"), isWarning: newStatus == 0);
        _fetchAllUsersAndSchools();"""

if old_user_toggle in code:
    code = code.replace(old_user_toggle, new_user_toggle)
    print("SUCCESS: Updated User Toggle Status Toast")

with open('lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(code)

print("COMPLETED REFACTORING ADMIN TOASTS!")
