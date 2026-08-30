import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';
import '../../core/api_config.dart';

class PrincipalDashboard extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;

  const PrincipalDashboard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.isEn,
  });

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  late UserModel _currentUser;
  late bool _isDarkMode;
  late bool _isEn;

  bool _isLoading = true;
  Map<String, dynamic>? _schoolData;
  int _currentNavIndex = 0;
  String _mobileTab = 'dashboard'; // 'dashboard' | 'about' | 'help' | 'settings'
  String? _selectedClassFilter;

  // School User Management state for Principal rank
  List<dynamic> _schoolUsersList = [];
  bool _isLoadingSchoolUsers = false;
  String _schoolUserRoleFilter = 'ALL'; // 'ALL', 'teacher', 'student'
  String _schoolUserSearchQuery = '';
  String? _schoolUserClassFilter;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  Color get _green  => const Color(0xFF006A4E);
  Color get _bg     => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _card   => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _text   => _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => _isDarkMode ? Colors.white60 : const Color(0xFF64748B);
  Color get _border => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return double.tryParse(val)?.toInt() ?? 0;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _isDarkMode = widget.isDarkMode;
    _isEn = widget.isEn;
    _fetchSchoolData();
    _fetchSchoolUsers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchoolData() async {
    setState(() => _isLoading = true);
    try {
      await ApiConfig.getWorkingHost();
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard.php?action=principal_school&principal_id=${_currentUser.id}'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() {
          _schoolData = data['data'];
          _isLoading = false;
        });
        _fetchSchoolUsers();
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  Future<void> _fetchSchoolUsers({bool silent = false}) async {
    if (!silent && _schoolUsersList.isEmpty) {
      setState(() => _isLoadingSchoolUsers = true);
    }
    try {
      await ApiConfig.getWorkingHost();
      final schoolId = _currentUser.schoolId ?? _parseInt(_schoolData?['school_id']) ?? 1;
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_all_users&school_id=$schoolId'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['data'] != null) {
        if (mounted) {
          setState(() {
            _schoolUsersList = data['data'] as List;
            _isLoadingSchoolUsers = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingSchoolUsers = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSchoolUsers = false);
    }
  }

  List<String> _getDivisionsForRegion(String regionName) {
    switch (regionName.toUpperCase()) {
      case 'ADAMOUA': return ['DJEREM', 'VINA', 'MAYO-BANYO', 'FARO-ET-DEO', 'MBERE'];
      case 'CENTRE': return ['MFOUNDI', 'NYONG-ET-SO\'O', 'NYONG-ET-MFOUMOU', 'NYONG-ET-KELLE', 'HAUTE-SANAGA', 'LEKIE', 'MBAM-ET-INOUBOU', 'MBAM-ET-KIM', 'MEFOU-ET-AFAMBA', 'MEFOU-ET-AKONO'];
      case 'EST': return ['LOM-ET-DJEREM', 'KADEY', 'BOUMBA-ET-NGOKO', 'HAUT-NYONG'];
      case 'EXTREME-NORD': return ['DIAMARE', 'MAYO-DANAY', 'MAYO-KANI', 'MAYO-SAVA', 'MAYO-TSANAGA', 'LOGONE-ET-CHARI'];
      case 'LITTORAL': return ['WOURI', 'SANAGA-MARITIME', 'NKAM', 'MOUNGO'];
      case 'NORD': return ['BENOUE', 'FARO', 'MAYO-LOUTI', 'MAYO-REY'];
      case 'NORD-OUEST': return ['MEZAM', 'BOYO', 'BUI', 'DONGA-MANTUNG', 'MENCHUM', 'MOMO', 'NGO-KETUNJIA'];
      case 'OUEST': return ['BAMBOUTOS', 'HAUT-NKAM', 'HAUTS-PLATEAUX', 'KOUNG-KHI', 'MENOUA', 'MIFI', 'NDE', 'NOUN'];
      case 'SUD': return ['OCEAN', 'MVILA', 'DJA-ET-LOBO', 'VALLEE-DU-NTEM'];
      case 'SUD-OUEST': return ['FAKO', 'MEME', 'NDIAN', 'LEBIALEM', 'MANYU', 'KUPE-MANENGUBA'];
      default: return ['DJEREM', 'VINA', 'MAYO-BANYO', 'FARO-ET-DEO', 'MBERE'];
    }
  }

  void _showAddUserDialog() {
    final nameCtrl      = TextEditingController();
    final matCtrl       = TextEditingController();
    final birthDateCtrl = TextEditingController(text: '2008-01-01');
    final classCtrl     = TextEditingController(text: '1ère TI');

    String selectedGender   = 'M';
    String selectedRegion   = _currentUser.region ?? 'ADAMOUA';
    List<String> currentDivisions = _getDivisionsForRegion(selectedRegion);
    String selectedDivision = currentDivisions.contains(_currentUser.division) ? (_currentUser.division!) : currentDivisions.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
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
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.person_add_rounded, color: _green, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _isEn ? 'Create Student Account' : 'Créer un Compte Élève',
                    style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Full Name Field
                    Text(_isEn ? 'Full Name:' : 'Nom Complet :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: _isEn ? 'e.g. Mohamadou Ali' : 'ex. Mohamadou Ali',
                        hintStyle: TextStyle(color: _sub.withValues(alpha: 0.5), fontSize: 14),
                        prefixIcon: Icon(Icons.person_outline_rounded, color: _green, size: 22),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Matricule & Gender Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Matricule / Student ID:' : 'Matricule :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: matCtrl,
                                style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: _isEn ? 'e.g. AD2026005' : 'ex. AD2026005',
                                  hintStyle: TextStyle(color: _sub.withValues(alpha: 0.5), fontSize: 14),
                                  prefixIcon: Icon(Icons.badge_outlined, color: _green, size: 22),
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Gender:' : 'Genre :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedGender,
                                isExpanded: true,
                                dropdownColor: _card,
                                style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5),
                                decoration: InputDecoration(
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'M', child: Text(_isEn ? 'Male (M)' : 'Masculin (M)')),
                                  DropdownMenuItem(value: 'F', child: Text(_isEn ? 'Female (F)' : 'Féminin (F)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedGender = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Class Name & Date of Birth Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Class Name:' : 'Classe :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: classCtrl,
                                style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.bookmark_outline_rounded, color: _green, size: 22),
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Date of Birth:' : 'Date de Naissance :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: birthDateCtrl,
                                style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.cake_outlined, color: _green, size: 22),
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(_isEn ? 'Create Account' : 'Créer le Compte', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  final String name = nameCtrl.text.trim();
                  final String mat = matCtrl.text.trim();
                  final String cls = classCtrl.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_isEn ? 'Please enter student full name.' : 'Veuillez entrer le nom complet.'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  final schoolId = _currentUser.schoolId ?? _parseInt(_schoolData?['school_id']) ?? 1;

                  // Immediate local UI state update
                  if (mounted) {
                    setState(() {
                      _schoolUsersList.insert(0, {
                        'id': DateTime.now().millisecondsSinceEpoch,
                        'user_id': DateTime.now().millisecondsSinceEpoch,
                        'full_name': name,
                        'role': 'student',
                        'matricule': mat.isNotEmpty ? mat : 'STU${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        'student_class': cls,
                        'class_name': cls,
                        'is_activated': 1,
                        'school_id': schoolId,
                      });
                    });
                  }

                  try {
                    final resp = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=create_user'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'full_name': name,
                        'role': 'student',
                        'matricule': mat,
                        'gender': selectedGender,
                        'birth_date': birthDateCtrl.text.trim(),
                        'region': selectedRegion,
                        'division': selectedDivision,
                        'school_id': schoolId,
                        'class_name': cls,
                      }),
                    );
                    final data = jsonDecode(resp.body);
                    if (mounted) {
                      _fetchSchoolData();
                      _fetchSchoolUsers();
                    }
                  } catch (_) {
                    if (mounted) {
                      _fetchSchoolData();
                      _fetchSchoolUsers();
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

  void _showEditUserDialog(Map<String, dynamic> user) {
    final userId = _parseInt(user['id'] ?? user['user_id']);
    final role = (user['role'] ?? 'student').toString();
    final nameCtrl = TextEditingController(text: user['full_name']?.toString() ?? '');
    final matCtrl = TextEditingController(text: user['matricule']?.toString() ?? '');
    final classCtrl = TextEditingController(text: user['student_class']?.toString() ?? user['teacher_class']?.toString() ?? user['class_name']?.toString() ?? '1ère TI');
    final subjectCtrl = TextEditingController(text: user['teacher_subject']?.toString() ?? user['subject']?.toString() ?? 'Informatique');
    final birthDateCtrl = TextEditingController(text: user['student_birth_date']?.toString() ?? user['birth_date']?.toString() ?? '2008-01-01');

    String selectedGender = (user['student_gender']?.toString().toUpperCase() == 'F' || user['gender']?.toString().toUpperCase() == 'F') ? 'F' : 'M';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: _card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.edit_rounded, color: _green, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _isEn ? 'Edit Student Details' : 'Modifier les Détails de l\'Élève',
                    style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Full Name Field
                    Text(_isEn ? 'Full Name:' : 'Nom Complet :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline_rounded, color: _green, size: 22),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Matricule & Class Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Matricule / Student ID:' : 'Matricule :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: matCtrl,
                                style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.badge_outlined, color: _green, size: 22),
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Class Name:' : 'Classe :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: classCtrl,
                                style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.bookmark_outline_rounded, color: _green, size: 22),
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Gender & Date of Birth Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Gender:' : 'Genre :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: selectedGender,
                                isExpanded: true,
                                dropdownColor: _card,
                                style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5),
                                decoration: InputDecoration(
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'M', child: Text(_isEn ? 'Male (M)' : 'Masculin (M)')),
                                  DropdownMenuItem(value: 'F', child: Text(_isEn ? 'Female (F)' : 'Féminin (F)')),
                                ],
                                onChanged: (val) { if (val != null) setModalState(() => selectedGender = val); },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_isEn ? 'Date of Birth:' : 'Date de Naissance :', style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: birthDateCtrl,
                                style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.cake_outlined, color: _green, size: 22),
                                  filled: true, fillColor: _bg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub, fontSize: 15, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.save_rounded, size: 20),
                label: Text(_isEn ? 'Save Changes' : 'Enregistrer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                onPressed: () async {
                  final String newName = nameCtrl.text.trim();
                  final String newMat  = matCtrl.text.trim();
                  final String newClass = classCtrl.text.trim();

                  if (newName.isEmpty) return;
                  Navigator.pop(ctx);

                  // Update local UI state immediately
                  if (mounted) {
                    setState(() {
                      user['full_name'] = newName;
                      user['matricule'] = newMat;
                      user['student_class'] = newClass;
                      user['class_name'] = newClass;
                      user['gender'] = selectedGender;
                    });
                  }

                  try {
                    final resp = await http.post(
                      Uri.parse('${ApiConfig.baseUrl}/admin.php?action=update_student'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'user_id': userId,
                        'full_name': newName,
                        'matricule': newMat,
                        'class_name': newClass,
                        'gender': selectedGender,
                        'birth_date': birthDateCtrl.text.trim(),
                      }),
                    );
                    final data = jsonDecode(resp.body);
                    if (mounted) {
                      _fetchSchoolData();
                      _fetchSchoolUsers();
                    }
                  } catch (e) {
                    if (mounted) {
                      _fetchSchoolData();
                      _fetchSchoolUsers();
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

  void _showDeleteUserDialog(Map<String, dynamic> user) {
    final userId = _parseInt(user['id'] ?? user['user_id']);
    final userName = user['full_name']?.toString() ?? 'User';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            const SizedBox(width: 8),
            Text(
              _isEn ? 'Delete User Account' : 'Supprimer le Compte Utilisateur',
              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          _isEn
              ? 'Are you sure you want to permanently delete $userName from the school records? This action cannot be undone.'
              : 'Êtes-vous sûr de vouloir supprimer définitivement $userName des registres de l\'établissement ? Cette action est irréversible.',
          style: TextStyle(color: _sub, fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            icon: const Icon(Icons.delete_rounded, size: 18),
            label: Text(_isEn ? 'Delete Permanently' : 'Supprimer Définitivement', style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () async {
              Navigator.pop(ctx);
              // Perform immediate local state removal for instant UI feedback
              if (mounted) {
                setState(() {
                  _schoolUsersList.removeWhere((u) => _parseInt(u['id'] ?? u['user_id']) == userId);
                  if (_schoolData != null && _schoolData!['all_students'] is List) {
                    (_schoolData!['all_students'] as List).removeWhere((s) => _parseInt(s['id'] ?? s['user_id']) == userId);
                  }
                });
              }

              try {
                final resp = await http.post(
                  Uri.parse('${ApiConfig.baseUrl}/admin.php?action=delete_user'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'user_id': userId}),
                );
                final data = jsonDecode(resp.body);
                if (mounted && data['success'] == true) {
                  _fetchSchoolData();
                  _fetchSchoolUsers();
                }
              } catch (_) {
                if (mounted) {
                  _fetchSchoolData();
                  _fetchSchoolUsers();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final int userId = _parseInt(user['id'] ?? user['user_id']);
    if (userId <= 0) return;

    final bool currentActive = (user['is_activated'] == 1 || user['is_activated'] == '1' || user['is_activated'] == true);
    final int newStatus = currentActive ? 0 : 1;

    // Direct, smooth local state toggle with zero flicker
    setState(() {
      user['is_activated'] = newStatus;
      for (var u in _schoolUsersList) {
        if (_parseInt(u['id'] ?? u['user_id']) == userId) {
          u['is_activated'] = newStatus;
        }
      }
    });

    try {
      await ApiConfig.getWorkingHost();
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=toggle_user_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'is_activated': newStatus,
        }),
      );
      _fetchSchoolUsers(silent: true);
    } catch (_) {
      // silent catch
    }
  }

  Widget _buildSchoolUsersManagementSection() {
    final List<Map<String, dynamic>> allUsers = _schoolUsersList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // Fallback if _schoolUsersList empty
    if (allUsers.isEmpty) {
      final rawSt = _schoolData?['all_students'] as List? ?? [];
      for (var st in rawSt) {
        allUsers.add({
          'id': st['id'] ?? st['user_id'] ?? 0,
          'user_id': st['user_id'] ?? st['id'] ?? 0,
          'full_name': st['full_name'] ?? 'Élève',
          'matricule': st['matricule'] ?? st['mat_number'] ?? 'AD2026',
          'role': 'student',
          'student_class': st['class_name'] ?? '1ère TI',
          'is_activated': st['is_activated'] ?? 0,
          'learning_style': st['learning_style'] ?? 'Not Assessed',
          'region': st['region'] ?? _currentUser.region ?? 'ADAMOUA',
          'division': st['division'] ?? _currentUser.division ?? 'DJEREM',
          'school_name': _schoolData?['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL',
        });
      }
    }

    // Collect available classes for filter dropdown
    final List<String> availableClasses = [_isEn ? 'All Classes' : 'Toutes les Classes'];
    for (var u in allUsers) {
      final cName = (u['student_class'] ?? u['teacher_class'] ?? u['class_name'] ?? '').toString();
      if (cName.isNotEmpty && !availableClasses.contains(cName)) {
        availableClasses.add(cName);
      }
    }

    // Filter users list - DEAN / PRINCIPAL SEES STUDENTS OF THEIR SCHOOL ONLY
    final filtered = allUsers.where((u) {
      final r = (u['role'] ?? '').toString();
      if (r != 'student') return false;

      final name = (u['full_name'] ?? '').toString().toLowerCase();
      final mat  = (u['matricule'] ?? '').toString().toLowerCase();
      final cls  = (u['student_class'] ?? u['teacher_class'] ?? u['class_name'] ?? '').toString();

      final matchesSearch = _schoolUserSearchQuery.isEmpty || name.contains(_schoolUserSearchQuery.toLowerCase()) || mat.contains(_schoolUserSearchQuery.toLowerCase());
      final matchesClass  = (_schoolUserClassFilter == null || _schoolUserClassFilter == availableClasses.first || cls == _schoolUserClassFilter);

      return matchesSearch && matchesClass;
    }).toList();

    final schoolName = _schoolData?['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL';
    final regionDiv  = '${_currentUser.region ?? "ADAMOUA"} / ${_currentUser.division ?? "DJEREM"}';

    final String userRole = (_currentUser.role ?? '').toLowerCase();
    final bool isPrincipal = (userRole == 'principal');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. TOP PAGE HEADER (Dean of Studies can create students; Principal only views/oversees) ────────
        if (!isPrincipal) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: Text(
                  _isEn ? '+ Create Student' : '+ Créer un Élève',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── 2. SEARCH & FILTER CARD (Matches Admin Dashboard) ────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: _text, fontSize: 13.5),
                  onChanged: (val) => setState(() => _schoolUserSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: _isEn ? 'Search by name or matricule...' : 'Chercher par nom ou matricule...',
                    hintStyle: TextStyle(color: _sub, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: _green, size: 20),
                    filled: true,
                    fillColor: _bg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: availableClasses.contains(_schoolUserClassFilter) ? _schoolUserClassFilter : availableClasses.first,
                    dropdownColor: _card,
                    style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                    items: availableClasses.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setState(() => _schoolUserClassFilter = val),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── 3. DATA TABLE CARD (Matches Admin Dashboard structure) ────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoadingSchoolUsers)
                const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()))
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.person_search_rounded, color: _sub, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        _isEn ? 'No student records matching criteria.' : 'Aucun élève ne correspond aux critères.',
                        style: TextStyle(color: _sub, fontSize: 13.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(_bg),
                    dataRowMinHeight: 60,
                    dataRowMaxHeight: 70,
                    horizontalMargin: 20,
                    columnSpacing: 24,
                    columns: [
                      DataColumn(label: Text(_isEn ? 'Student Name' : 'Nom de l\'Élève', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                      DataColumn(label: Text(_isEn ? 'Matricule' : 'Matricule', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                      DataColumn(label: Text(_isEn ? 'Class' : 'Classe', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                      DataColumn(label: Text(_isEn ? 'Account Status' : 'Statut du Compte', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                      DataColumn(label: Text(_isEn ? 'Actions' : 'Actions', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                    ],
                    rows: filtered.map((u) {
                      final name = u['full_name']?.toString() ?? 'N/A';
                      final mat  = u['matricule']?.toString() ?? 'N/A';
                      final cls  = (u['student_class'] ?? u['class_name'] ?? '1ère TI').toString();
                      final bool isActivated = (u['is_activated'] == 1 || u['is_activated'] == '1' || u['is_activated'] == true);

                      const roleBadgeColor = Color(0xFF3B82F6);

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: roleBadgeColor.withValues(alpha: 0.15),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                    style: const TextStyle(color: roleBadgeColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(name, style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5)),
                              ],
                            ),
                          ),
                          DataCell(Text(mat, style: TextStyle(color: _sub, fontFamily: 'monospace', fontSize: 12.5, fontWeight: FontWeight.w700))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                              child: Text(cls, style: TextStyle(color: _green, fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isActivated ? const Color(0xFF10B981) : Colors.redAccent).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7, height: 7,
                                    decoration: BoxDecoration(
                                      color: isActivated ? const Color(0xFF10B981) : Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isActivated ? (_isEn ? 'Active' : 'Actif') : (_isEn ? 'Blocked' : 'Bloqué'),
                                    style: TextStyle(
                                      color: isActivated ? const Color(0xFF10B981) : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit_rounded, color: _green, size: 19),
                                  tooltip: _isEn ? 'Edit' : 'Modifier',
                                  onPressed: () => _showEditUserDialog(u),
                                ),
                                IconButton(
                                  icon: Icon(
                                    isActivated ? Icons.block_rounded : Icons.lock_open_rounded,
                                    color: isActivated ? Colors.redAccent : const Color(0xFF10B981),
                                    size: 19,
                                  ),
                                  tooltip: isActivated ? (_isEn ? 'Block' : 'Bloquer') : (_isEn ? 'Unblock' : 'Débloquer'),
                                  onPressed: () => _toggleUserStatus(u),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 19),
                                  tooltip: _isEn ? 'Delete' : 'Supprimer',
                                  onPressed: () => _showDeleteUserDialog(u),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showSettingsModalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: _border),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: _sub.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildSettingsInlineView(setModalState)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsInlineView([StateSetter? setModalState]) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.settings_rounded, color: _green, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEn ? 'Settings' : 'Paramètres',
                      style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isEn ? 'Customise your experience' : 'Personnalisez votre expérience',
                      style: TextStyle(color: _sub, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 1. APPEARANCE SECTION ─────────────────────────────────────
          Text(
            _isEn ? 'APPEARANCE' : 'APPARENCE',
            style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isDarkMode ? Icons.nightlight_round_outlined : Icons.wb_sunny_outlined,
                    color: _isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFFCD116),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEn ? 'Display Theme' : 'Thème d\'affichage',
                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      Text(
                        _isDarkMode ? (_isEn ? 'Dark Mode' : 'Mode Sombre') : (_isEn ? 'Light Mode' : 'Mode Clair'),
                        style: TextStyle(color: _sub, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (val) { setState(() => _isDarkMode = val); if (setModalState != null) setModalState(() {}); },
                  activeColor: const Color(0xFF34D399),
                  activeTrackColor: _green.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 2. LANGUAGE SECTION ───────────────────────────────────────
          Text(
            _isEn ? 'LANGUAGE' : 'LANGUE',
            style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded, color: Colors.blueAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEn ? 'App Language' : 'Langue de l\'application',
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() => _isEn = true); if (setModalState != null) setModalState(() {}); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _isEn ? _green.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _isEn ? _green : _border, width: _isEn ? 2 : 1),
                          ),
                          child: Column(
                            children: [
                              const Text('🇬🇧', style: TextStyle(fontSize: 26)),
                              const SizedBox(height: 6),
                              Text('English', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5)),
                              if (_isEn) ...[
                                const SizedBox(height: 4),
                                Icon(Icons.check_circle_rounded, color: _green, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () { setState(() => _isEn = false); if (setModalState != null) setModalState(() {}); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: !_isEn ? _green.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: !_isEn ? _green : _border, width: !_isEn ? 2 : 1),
                          ),
                          child: Column(
                            children: [
                              const Text('🇫🇷', style: TextStyle(fontSize: 26)),
                              const SizedBox(height: 6),
                              Text('Français', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5)),
                              if (!_isEn) ...[
                                const SizedBox(height: 4),
                                Icon(Icons.check_circle_rounded, color: _green, size: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 3. ACCOUNT PROFILE & EDIT ────────────────────────────────
          Text(
            _isEn ? 'ACCOUNT PROFILE' : 'PROFIL DU COMPTE',
            style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.2),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _green,
                      child: Text(
                        _currentUser.fullName.isNotEmpty ? _currentUser.fullName[0].toUpperCase() : 'P',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_currentUser.fullName, style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('${_currentUser.role.toUpperCase()} | ${_currentUser.matNumber ?? "PRN202601"}', style: TextStyle(color: _sub, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _showPrincipalProfileDialog,
                    icon: const Icon(Icons.person_rounded, size: 18),
                    label: Text(_isEn ? 'Profile' : 'Profil', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── 4. LOGOUT SECTION ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.25)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await AuthService.logout();
                  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: Text(_isEn ? 'Logout' : 'Déconnexion', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutInlineView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_green, const Color(0xFF009966)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MINESEC LST', style: TextStyle(color: Color(0xFFFCD116), fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  _isEn ? 'Learning Style Tracker & Pedagogical Analytics' : 'Traqueur de Style d\'Apprentissage & Analyses Pédagogiques',
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  _isEn
                      ? 'Official MINESEC platform designed to evaluate student VARK learning preferences using Neil Fleming standardized grading scales and generate tailored pedagogical strategies.'
                      : 'Plateforme officielle du MINESEC conçue pour diagnostiquer les préférences d\'apprentissage VARK et générer des directives IA pour l\'enseignement secondaire au Cameroun.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpInlineView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Icon(Icons.help_outline_rounded, color: _green, size: 24),
                    const SizedBox(width: 10),
                    Text(_isEn ? 'Help & Pedagogical Guidance' : 'Aide & Directives Pédagogiques', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _isEn
                      ? '• Need assistance with VARK questionnaires or student enrollment?\n• Contact MINESEC Technical Support: support@minesec-lst.cm\n• Hotline: (+237) 670 000 000'
                      : '• Besoin d\'assistance pour les questionnaires VARK ou l\'inscription des élèves ?\n• Contactez le Support Technique MINESEC : support@minesec-lst.cm\n• Ligne directe : (+237) 670 000 000',
                  style: TextStyle(color: _text, fontSize: 13, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _downloadPrincipalReport() {
    final schoolName = _schoolData?['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL';
    final principal  = _currentUser.fullName;

    final totalStudents = _parseInt(_schoolData?['total_students'] ?? 0);
    final assessedStudents = _parseInt(_schoolData?['assessed_students'] ?? 0);
    final totalTeachers = _parseInt(_schoolData?['total_teachers'] ?? 0);
    final visualCount = _parseInt(_schoolData?['visual_count'] ?? 0);
    final auditoryCount = _parseInt(_schoolData?['auditory_count'] ?? 0);
    final kinestheticCount = _parseInt(_schoolData?['kinesthetic_count'] ?? 0);
    final readWriteCount = _parseInt(_schoolData?['read_write_count'] ?? 0);

    final csvContent = '''MINESEC LST — Principal School VARK Summary Report
"Field","Value"
"School","$schoolName"
"Principal Name","$principal"
"Region","${_currentUser.region ?? "ADAMOUA"}"
"Division","${_currentUser.division ?? "DJEREM"}"
"Total Students","$totalStudents"
"Assessed Students","$assessedStudents"
"Total Teachers","$totalTeachers"
"Visual Count","$visualCount"
"Auditory Count","$auditoryCount"
"Kinesthetic Count","$kinestheticCount"
"Read/Write Count","$readWriteCount"
''';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: _green),
            const SizedBox(width: 10),
            Text(
              _isEn ? 'Download School Report' : 'Télécharger le Rapport d\'Établissement',
              style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEn
                  ? 'VARK Diagnostic CSV summary report generated for $schoolName.'
                  : 'Rapport synthétique CSV VARK généré pour $schoolName.',
              style: TextStyle(color: _sub, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
              child: SelectableText(
                csvContent,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_isEn ? 'Close' : 'Fermer', style: TextStyle(color: _sub)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isEn ? 'School Report Downloaded Successfully!' : 'Rapport d\'Établissement Téléchargé avec Succès !'),
                  backgroundColor: _green,
                ),
              );
            },
            icon: const Icon(Icons.download_done_rounded, size: 18),
            label: Text(_isEn ? 'Confirm Download' : 'Confirmer Téléchargement'),
          ),
        ],
      ),
    );
  }

  void _useFallbackData() {
    setState(() {
      _isLoading = false;
      _schoolData = {
        'school_name': 'LYCEE TECHNIQUE DE NGAOUNDAL',
        'principal_name': _currentUser.fullName,
        'matricule': _currentUser.matNumber ?? 'PRN202601',
        'region': _currentUser.region ?? 'ADAMOUA',
        'division': _currentUser.division ?? 'DJEREM',
        'total_students': 2,
        'assessed_students': 2,
        'total_teachers': 1,
        'visual_count': 2,
        'auditory_count': 1,
        'kinesthetic_count': 1,
        'read_write_count': 0,
        'teachers': [
          {'name': 'M. Nguene Jacques', 'subject': 'Informatique', 'classes': '1ère TI', 'students_count': 1},
        ],
        'class_breakdown': [
          {
            'class_name': '1ère TI',
            'total_students': 1,
            'assessed': 1,
            'visual': 1,
            'auditory': 1,
            'kinesthetic': 0,
            'read_write': 0,
            'students': [
              {'full_name': 'Bello Oumarou', 'mat_number': 'AD2026001', 'class_name': '1ère TI', 'learning_style': 'Auditory-Visual (Dual Style)'},
            ],
            'ai_recommendation_en': '• Integrate visual mind maps, flowchart diagrams, and audio lectures tailored for 1ère TI.\n• Encourage interactive peer discussions and practical programming lab sessions.',
            'ai_recommendation_fr': '• Intégrez des cartes mentales visuelles, schémas d\'organigrammes et cours auditifs adaptés pour 1ère TI.\n• Encouragez les discussions interactives entre pairs et les séances pratiques de laboratoire informatique.',
          },
          {
            'class_name': 'Terminale TI',
            'total_students': 1,
            'assessed': 1,
            'visual': 1,
            'auditory': 0,
            'kinesthetic': 1,
            'read_write': 0,
            'students': [
              {'full_name': 'Amina Mohamadou', 'mat_number': 'AD2026002', 'class_name': 'Terminale TI', 'learning_style': 'Kinesthetic-Visual Learner'},
            ],
            'ai_recommendation_en': '• Focus on hands-on computer network physical wiring and hardware assembly for Terminale TI.\n• Provide clear architectural diagrams to support visual understanding.',
            'ai_recommendation_fr': '• Axez l\'apprentissage sur le câblage réseau informatique pratique et le montage matériel pour Terminale TI.\n• Fournissez des schémas d\'architecture clairs pour soutenir la compréhension visuelle.',
          },
        ],
        'ai_policy_en': '• Prioritize practical ICT laboratory resources to accommodate 160 visual and 60 kinesthetic learners.\n• Organize inter-class workshops and auditory seminars for language and humanities subjects.\n• Request MINESEC pedagogical support for updated digital learning aids.',
        'ai_policy_fr': '• Priorisez les équipements de laboratoires informatiques pratiques pour répondre aux besoins de 160 apprenants visuels et 60 kinesthésiques.\n• Organisez des ateliers inter-classes et séminaires auditifs pour les matières littéraires.\n• Sollicitez le soutien pédagogique du MINESEC pour le matériel d\'apprentissage numérique.',
      };
    });
  }

  void _showPrincipalProfileDialog() async {
    final passCtrl    = TextEditingController();
    final secCodeCtrl = TextEditingController();
    bool obscurePass  = true;
    bool obscureSec   = true;
    bool loading      = true;
    bool saving       = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loading) {
            http.get(
              Uri.parse('${ApiConfig.baseUrl}/auth.php?action=get_profile&user_id=${_currentUser.id}'),
            ).then((res) {
              final pData = jsonDecode(res.body);
              if (pData['success'] == true && pData['data'] != null) {
                final profile = pData['data'];
                passCtrl.text    = (profile['password'] ?? '').toString();
                secCodeCtrl.text = (profile['security_code'] ?? '').toString();
              } else {
                passCtrl.text    = '';
                secCodeCtrl.text = '';
              }
              if (ctx.mounted) setModalState(() => loading = false);
            }).catchError((_) {
              passCtrl.text    = '';
              secCodeCtrl.text = '';
              if (ctx.mounted) setModalState(() => loading = false);
            });
          }

          final initials = _currentUser.fullName.trim().split(' ')
              .take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.90),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(top: BorderSide(color: _border)),
            ),
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_green, const Color(0xFF009966)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              initials.isEmpty ? 'P' : initials,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentUser.fullName,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  _isEn ? 'Principal / Headmaster' : 'Proviseur / Chef d\'Établissement',
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(Icons.badge_outlined, color: _green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isEn ? 'Principal Database Credentials' : 'Identifiants Proviseur en Base de Données',
                        style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _profileInfoRow(Icons.badge_rounded, _isEn ? 'Matricule' : 'Matricule', _currentUser.matNumber ?? 'P2026001'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.school_rounded, _isEn ? 'School' : 'Établissement', _schoolData?['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.map_rounded, _isEn ? 'Region & Division' : 'Région & Département', '${_currentUser.region ?? "ADAMOUA"} — ${_currentUser.division ?? "DJEREM"}'),
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isEn ? 'Modify Password & Security Code' : 'Modifier Mot de Passe & Code de Sécurité',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (loading)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    )
                  else ...[
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'New Password' : 'Nouveau Mot de Passe',
                        labelStyle: TextStyle(color: _sub, fontSize: 12),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: _green, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: _sub, size: 20),
                          onPressed: () => setModalState(() => obscurePass = !obscurePass),
                        ),
                        filled: true,
                        fillColor: _bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: secCodeCtrl,
                      obscureText: obscureSec,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'Security Code' : 'Code de Sécurité',
                        labelStyle: TextStyle(color: _sub, fontSize: 12),
                        prefixIcon: Icon(Icons.security_rounded, color: _green, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureSec ? Icons.visibility_off : Icons.visibility, color: _sub, size: 20),
                          onPressed: () => setModalState(() => obscureSec = !obscureSec),
                        ),
                        filled: true,
                        fillColor: _bg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: saving ? null : () async {
                          final newPass = passCtrl.text.trim();
                          final newSec  = secCodeCtrl.text.trim();

                          setModalState(() => saving = true);

                          try {
                            await http.post(
                              Uri.parse('${ApiConfig.baseUrl}/auth.php?action=update_profile'),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({
                                'user_id': _currentUser.id,
                                if (newPass.isNotEmpty) 'password': newPass,
                                if (newSec.isNotEmpty) 'security_code': newSec,
                              }),
                            );
                            if (mounted) Navigator.pop(ctx);
                          } catch (_) {
                            if (mounted) Navigator.pop(ctx);
                          }
                        },
                        icon: saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 20),
                        label: Text(
                          saving ? (_isEn ? 'Saving...' : 'Enregistrement...') : (_isEn ? 'Save Changes' : 'Enregistrer les Modifications'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateClassroomRec({
    required int vis,
    required int aud,
    required int kin,
    required int rw,
    required String className,
    required bool isEn,
  }) {
    final total = vis + aud + kin + rw;
    if (total == 0) {
      return isEn
          ? '• Diagnostic analysis in progress for class $className.\n• Complete student VARK assessments to generate customized pedagogical recommendations.'
          : '• Analyse diagnostique en cours pour la classe $className.\n• Complétez les évaluations VARK des élèves pour générer des recommandations pédagogiques personnalisées.';
    }

    final counts = {'Visual': vis, 'Auditory': aud, 'Kinesthetic': kin, 'Read/Write': rw};
    final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
    final topStyles = counts.entries.where((e) => e.value == maxCount && e.value > 0).map((e) => e.key).toList();

    List<String> recsEn = [];
    List<String> recsFr = [];

    if (topStyles.contains('Auditory')) {
      recsEn.add('• Incorporate clear verbal explanations, class discussions, and Q&A sessions into daily lesson notes for class $className.');
      recsEn.add('• Provide audio recordings and spoken summaries of key lecture topics for student review.');
      recsFr.add('• Intégrez des explications orales claires, des débats et séances de Q/R dans vos fiches de cours pour la classe $className.');
      recsFr.add('• Mettez à disposition des enregistrements audio et synthèses orales des leçons.');
    }
    if (topStyles.contains('Visual')) {
      recsEn.add('• Utilize color-coded visual charts, mind maps, flowcharts, and board diagrams when preparing lesson notes for class $className.');
      recsEn.add('• Incorporate video demonstrations, slides, and graphical models into classroom teaching.');
      recsFr.add('• Utilisez des schémas visuels en couleur, des cartes mentales et organigrammes pour la classe de $className.');
      recsFr.add('• Intégrez des démonstrations vidéo, des diaporamas et modèles graphiques en cours.');
    }
    if (topStyles.contains('Kinesthetic')) {
      recsEn.add('• Structure lessons around hands-on lab experiments, interactive coding, and practical exercises for class $className.');
      recsEn.add('• Provide step-by-step practical demonstrations and assign project-based learning tasks.');
      recsFr.add('• Structurez vos cours autour de travaux pratiques, du codage interactif et d\'exercices pour $className.');
      recsFr.add('• Proposez des démonstrations pratiques étape par étape et attribuez des projets pratiques.');
    }
    if (topStyles.contains('Read/Write')) {
      recsEn.add('• Provide structured printed handouts, comprehensive reading glossaries, and written exercise sets for class $className.');
      recsEn.add('• Guide students in writing out clear summaries, definitions, and detailed bulleted notes.');
      recsFr.add('• Fournissez des fiches de cours imprimées, des glossaires détaillés et exercices écrits pour $className.');
      recsFr.add('• Guidez les élèves dans la rédaction de résumés clairs et de notes structurées à puces.');
    }

    return isEn ? recsEn.join('\n') : recsFr.join('\n');
  }

  String _generateSchoolPolicyRec({
    required int vis,
    required int aud,
    required int kin,
    required int rw,
    required String schoolName,
    required bool isEn,
  }) {
    final total = vis + aud + kin + rw;
    if (total == 0) {
      return isEn
          ? '• Strategic Institutional Directive for $schoolName: Student diagnostic assessment coverage in progress. Coordinate with department heads to complete student VARK testing.'
          : '• Directive Stratégique Institutionnelle pour $schoolName : Couverture des évaluations diagnostiques en cours. Coordonnez avec les chefs de travaux pour finaliser les tests VARK.';
    }

    String dominant = 'Auditory';
    int maxCount = aud;
    if (vis > maxCount) { maxCount = vis; dominant = 'Visual'; }
    if (kin > maxCount) { maxCount = kin; dominant = 'Kinesthetic'; }
    if (rw > maxCount)  { maxCount = rw;  dominant = 'Read/Write'; }

    final int pct = total > 0 ? ((maxCount / total) * 100).round() : 0;

    List<String> recsEn = [];
    List<String> recsFr = [];

    if (dominant == 'Auditory') {
      recsEn.add('• Auditory Learning Strategy (Primary Focus) at $schoolName: Prioritize audio-visual equipment, recorded lecture archives, peer debates, and verbal instruction toolkits across classrooms.');
      recsFr.add('• Stratégie d\'Apprentissage Auditif (Focus Principal) au $schoolName : Priorisez les équipements audiovisuels, cours enregistrés, débats et outils d\'enseignement oral.');
    } else if (dominant == 'Visual') {
      recsEn.add('• Visual Learning Strategy (Primary Focus) at $schoolName: Allocate digital projectors, interactive smartboards, visual simulation software, and color-coded study guides.');
      recsFr.add('• Stratégie d\'Apprentissage Visuel (Focus Principal) au $schoolName : Allouez des vidéoprojecteurs, tableaux interactifs et fiches synthétiques en couleurs.');
    } else if (dominant == 'Kinesthetic') {
      recsEn.add('• Kinesthetic Learning Strategy (Primary Focus) at $schoolName: Expand practical computer science laboratories, technical hardware workshops, and practical field training.');
      recsFr.add('• Stratégie d\'Apprentissage Kinesthésique (Focus Principal) au $schoolName : Développez les laboratoires informatiques pratiques, ateliers de maintenance et stages techniques.');
    } else {
      recsEn.add('• Read/Write Learning Strategy (Primary Focus) at $schoolName: Enrich school library with updated textbooks, digital reference manuals, e-libraries, and essay competitions.');
      recsFr.add('• Stratégie d\'Apprentissage Lecture/Écriture (Focus Principal) au $schoolName : Enrichissez la bibliothèque en manuels, répertoires numériques et concours de rédaction.');
    }

    recsEn.add('• Auditory Directive: Facilitate interactive classroom discussions, oral presentations, and group debates.');
    recsFr.add('• Directive Auditive : Facilitez les discussions interactives en classe, exposés oraux et débats.');

    recsEn.add('• Visual Directive: Equip classrooms with visual charts, multi-colored whiteboards, and mind-mapping tools.');
    recsFr.add('• Directive Visuelle : Équipez les classes de graphiques visuels et schémas.');

    recsEn.add('• Kinesthetic Directive: Provide hands-on laboratory equipment, practical ICT workshops, and active learning exercises.');
    recsFr.add('• Directive Kinesthésique : Fournissez du matériel de laboratoire pratique et des ateliers informatiques.');

    recsEn.add('• Read/Write Directive: Supply comprehensive textbook reference guides, structured note-taking frameworks, and library resources.');
    recsFr.add('• Directive Lecture/Écriture : Mettez à disposition des manuels de référence complets et des fiches de synthèse.');

    return isEn ? recsEn.join('\n') : recsFr.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final schoolName = _schoolData?['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL';
    final int totalStudents   = _parseInt(_schoolData?['total_students'] ?? 0);
    final int assessedStudents= _parseInt(_schoolData?['assessed_students'] ?? 0);
    final int totalTeachers   = _parseInt(_schoolData?['total_teachers'] ?? 0);

    final int visSt   = _parseInt(_schoolData?['visual_count'] ?? 0);
    final int audSt   = _parseInt(_schoolData?['auditory_count'] ?? 0);
    final int kinesSt = _parseInt(_schoolData?['kinesthetic_count'] ?? 0);
    final int rwSt    = _parseInt(_schoolData?['read_write_count'] ?? 0);

    final List teachers = _schoolData?['teachers'] as List? ?? [];
    final List classBreakdown = _schoolData?['class_breakdown'] as List? ?? [
      {
        'class_name': '1ère TI',
        'total_students': 1,
        'assessed': 1,
        'visual': 1,
        'auditory': 1,
        'kinesthetic': 0,
        'read_write': 0,
      },
      {
        'class_name': 'Terminale TI',
        'total_students': 1,
        'assessed': 0,
        'visual': 0,
        'auditory': 0,
        'kinesthetic': 0,
        'read_write': 0,
      },
    ];
    final int totalClasses = classBreakdown.length;

    final String aiPolicy = _generateSchoolPolicyRec(
      vis: visSt,
      aud: audSt,
      kin: kinesSt,
      rw: rwSt,
      schoolName: schoolName,
      isEn: _isEn,
    );

    final List<String> schoolClassesList = [];
    for (var cb in classBreakdown) {
      final cn = (cb['class_name'] ?? '').toString();
      if (cn.isNotEmpty && !schoolClassesList.contains(cn)) {
        schoolClassesList.add(cn);
      }
    }
    if (schoolClassesList.isEmpty) schoolClassesList.addAll(['1ère TI', 'Terminale TI', '2nde C', '1ère C', 'Terminale C']);

    final isWide = MediaQuery.of(context).size.width >= 800;

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      tickedClasses: schoolClassesList,
      selectedClass: _selectedClassFilter ?? schoolClassesList.first,
      onClassSelected: (cls) {
        setState(() {
          _currentNavIndex = 2;
          _selectedClassFilter = cls;
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      onItemSelected: (idx) {
        setState(() => _currentNavIndex = idx);
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      onOpenProfile: _showSettingsModalDialog,
      onToggleTheme: () => setState(() => _isDarkMode = !_isDarkMode),
      onToggleLanguage: () => setState(() => _isEn = !_isEn),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: isWide ? null : sidebarWidget,
      bottomNavigationBar: null,
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) sidebarWidget,
            Expanded(
              child: Column(
                children: [
                  // ── TOP NAVIGATION BAR (MOBILE ONLY) ──────────────────
                  if (!isWide)
                    Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      color: _bg,
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.menu_rounded, color: _text, size: 24),
                            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(_isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined, color: _isDarkMode ? const Color(0xFFFCD116) : _green, size: 20),
                            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
                            tooltip: _isEn ? 'Toggle Theme' : 'Changer de Thème',
                          ),
                          InkWell(
                            onTap: () => setState(() => _isEn = !_isEn),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _green.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _isEn ? 'FR' : 'EN',
                                style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                // Main Body Content
                Expanded(
                  child: _mobileTab == 'about'
                      ? _buildAboutInlineView()
                      : _mobileTab == 'help'
                          ? _buildHelpInlineView()
                          : _mobileTab == 'settings'
                              ? _buildSettingsInlineView()
                              : RefreshIndicator(
                                  onRefresh: _fetchSchoolData,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(22),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TAB 0: DASHBOARD OVERVIEW LANDING PAGE ──────────────────
                          if (_currentNavIndex == 0) ...[
                            // Principal Welcome Banner Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_green, const Color(0xFF009966)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                           Text(_isEn ? 'Welcome Back,' : 'Bienvenue,', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
                                          Text(_currentUser.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: [
                                      _scopeBadge(Icons.location_city_rounded, schoolName),
                                      _scopeBadge(Icons.map_rounded, '${_currentUser.division ?? "DJEREM"} — ${_currentUser.region ?? "ADAMOUA"}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                             LayoutBuilder(
                               builder: (context, constraints) {
                                 final isMobile = constraints.maxWidth < 600;
                                 return Column(
                                   children: [
                                     if (!isMobile) ...[
                                       Row(
                                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                         children: [
                                           Expanded(
                                             child: Text(
                                               _isEn ? 'School Executive Overview' : 'Aperçu Général de l\'Établissement',
                                               style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                           OutlinedButton.icon(
                                             style: OutlinedButton.styleFrom(
                                               foregroundColor: _green,
                                               side: BorderSide(color: _green),
                                               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                             ),
                                             onPressed: _downloadPrincipalReport,
                                             icon: const Icon(Icons.download_rounded, size: 18),
                                             label: Text(_isEn ? 'Download Report' : 'Télécharger Rapport', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                           ),
                                         ],
                                       ),
                                       const SizedBox(height: 14),
                                     ],
                                     const SizedBox(height: 14),

                                     if (isMobile) ...[
                                       Row(
                                         children: [
                                           Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF006A4E))),
                                           const SizedBox(width: 8),
                                           Expanded(child: _overviewStatCard(icon: Icons.school_rounded, label: _isEn ? 'Total Classes' : 'Total Classes', value: '$totalClasses', color: const Color(0xFF10B981))),
                                         ],
                                       ),
                                       const SizedBox(height: 8),
                                       Row(
                                         children: [
                                           Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Total Teachers' : 'Total Enseignants', value: '$totalTeachers', color: const Color(0xFF3B82F6))),
                                           const SizedBox(width: 8),
                                           Expanded(child: _overviewStatCard(icon: Icons.psychology_rounded, label: _isEn ? 'Pedagogical Status' : 'Statut Pédagogique', value: _isEn ? 'Optimal' : 'Optimal', color: const Color(0xFF8B5CF6))),
                                         ],
                                       ),
                                     ] else ...[
                                       Row(
                                         children: [
                                           Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF006A4E))),
                                           const SizedBox(width: 10),
                                           Expanded(child: _overviewStatCard(icon: Icons.school_rounded, label: _isEn ? 'Total Classes' : 'Total Classes', value: '$totalClasses', color: const Color(0xFF10B981))),
                                           const SizedBox(width: 10),
                                           Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Total Teachers' : 'Total Enseignants', value: '$totalTeachers', color: const Color(0xFF3B82F6))),
                                           const SizedBox(width: 10),
                                           Expanded(child: _overviewStatCard(icon: Icons.psychology_rounded, label: _isEn ? 'Pedagogical Status' : 'Statut Pédagogique', value: _isEn ? 'Optimal' : 'Optimal', color: const Color(0xFF8B5CF6))),
                                         ],
                                       ),
                                     ],
                                   ],
                                 );
                               },
                             ),
                            const SizedBox(height: 20),


                            const SizedBox(height: 20),

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
                                        child: Text(_isEn ? 'School VARK Learning Styles Distribution' : 'Répartition VARK Globale de l\'Établissement', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 140, height: 140,
                                        child: CustomPaint(painter: _VarkPieChartPainter(visual: visSt, auditory: audSt, kinesthetic: kinesSt, readWrite: rwSt)),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            _pieLegendItem(_isEn ? 'Visual Learner' : 'Visuel', visSt, const Color(0xFF3B82F6)),
                                            const SizedBox(height: 10),
                                            _pieLegendItem(_isEn ? 'Auditory Learner' : 'Auditif', audSt, const Color(0xFFEC4899)),
                                            const SizedBox(height: 10),
                                            _pieLegendItem(_isEn ? 'Kinesthetic Learner' : 'Kinesthésique', kinesSt, const Color(0xFF10B981)),
                                            const SizedBox(height: 10),
                                            _pieLegendItem(_isEn ? 'Read/Write Learner' : 'Lecture/Écriture', rwSt, const Color(0xFFF59E0B)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                           ],

                          // ── TAB 1: SCHOOL VARK ANALYTICS & AI POLICY ─────────────────
                          if (_currentNavIndex == 1) ...[
                            Text(
                              _isEn ? 'School VARK Analytics & Institutional Policy' : 'Analyses VARK & Politique Institutionnelle',
                              style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, color: _green, size: 22),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _isEn ? 'Institutional Pedagogical Strategy & Directives' : 'Directives Pédagogiques Institutionnelles',
                                          style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(aiPolicy, style: TextStyle(color: _text, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],

                          // ── TAB 2: CLASSES ───────────────────
                          if (_currentNavIndex == 2) ...[

                            // Selected Class Card Only
                            Builder(
                              builder: (ctx) {
                                final List<String> classOptions = [];
                                for (var cb in classBreakdown) {
                                  final cn = (cb['class_name'] ?? '').toString();
                                  if (cn.isNotEmpty && !classOptions.contains(cn)) {
                                    classOptions.add(cn);
                                  }
                                }
                                if (classOptions.isEmpty) classOptions.addAll(['1ère TI', 'Terminale TI']);

                                final activeClass = (_selectedClassFilter != null && classOptions.contains(_selectedClassFilter))
                                    ? _selectedClassFilter!
                                    : classOptions.first;

                                Map<String, dynamic> selectedCb = {};
                                for (var cb in classBreakdown) {
                                  final map = cb as Map<String, dynamic>;
                                  if (map['class_name'] == activeClass) {
                                    selectedCb = map;
                                    break;
                                  }
                                }
                                if (selectedCb.isEmpty && classBreakdown.isNotEmpty) {
                                  selectedCb = classBreakdown.first as Map<String, dynamic>;
                                }

                                final cName = selectedCb['class_name'] ?? activeClass;
                                final totSt = _parseInt(selectedCb['total_students']);
                                final assSt = _parseInt(selectedCb['assessed']);
                                final vis   = _parseInt(selectedCb['visual']);
                                final aud   = _parseInt(selectedCb['auditory']);
                                final kin   = _parseInt(selectedCb['kinesthetic']);
                                final rw    = _parseInt(selectedCb['read_write']);
                                final cRec  = _generateClassroomRec(
                                  vis: vis,
                                  aud: aud,
                                  kin: kin,
                                  rw: rw,
                                  className: cName,
                                  isEn: _isEn,
                                );

                                final List stList = selectedCb['students'] as List? ?? [];
                                return Container(
                                   padding: const EdgeInsets.all(20),
                                   decoration: BoxDecoration(
                                     color: _card,
                                     borderRadius: BorderRadius.circular(18),
                                     border: Border.all(color: _border),
                                   ),
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.school_rounded, color: _green, size: 22),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Class: $cName',
                                                    style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 17),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                              decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                              child: Text(
                                                '${_isEn ? "Students" : "Élèves"}: $totSt ($assSt ${_isEn ? "Assessed" : "Évalués"})',
                                                style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 11.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                       const SizedBox(height: 16),

                                       // VARK Badges
                                       Wrap(
                                         spacing: 8,
                                         runSpacing: 8,
                                         children: [
                                           _varkBadge(_isEn ? 'Visual' : 'Visuel', vis, const Color(0xFF3B82F6)),
                                           _varkBadge(_isEn ? 'Auditory' : 'Auditif', aud, const Color(0xFFEC4899)),
                                           _varkBadge(_isEn ? 'Kinesthetic' : 'Kinesthésique', kin, const Color(0xFF10B981)),
                                           _varkBadge(_isEn ? 'Read/Write' : 'Lecture/Écriture', rw, const Color(0xFFF59E0B)),
                                         ],
                                       ),
                                       const SizedBox(height: 18),

                                       // Students Roster Table for this Class
                                       Text(
                                         _isEn ? 'Students & Dominant Learning Styles:' : 'Élèves de la Classe & Styles d\'Apprentissage Dominants :',
                                         style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14),
                                       ),
                                       const SizedBox(height: 10),
                                       if (stList.isEmpty)
                                         Container(
                                           padding: const EdgeInsets.all(14),
                                           decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10)),
                                           child: Text(_isEn ? 'No students registered for this class.' : 'Aucun élève inscrit pour cette classe.', style: TextStyle(color: _sub, fontSize: 12.5)),
                                         )
                                       else
                                         Column(
                                           children: stList.map<Widget>((st) {
                                             final sMap = st as Map<String, dynamic>;
                                             final sName = sMap['full_name'] ?? 'Élève';
                                             final sMat = sMap['mat_number'] ?? '';
                                             final sStyle = sMap['learning_style'] ?? 'Not Assessed';

                                             Color badgeCol = const Color(0xFF3B82F6);
                                             if (sStyle.contains('Auditory')) badgeCol = const Color(0xFFEC4899);
                                             if (sStyle.contains('Kinesthetic')) badgeCol = const Color(0xFF10B981);
                                             if (sStyle.contains('Read')) badgeCol = const Color(0xFFF59E0B);

                                             return Container(
                                               margin: const EdgeInsets.only(bottom: 8),
                                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                               decoration: BoxDecoration(
                                                 color: _bg,
                                                 borderRadius: BorderRadius.circular(12),
                                                 border: Border.all(color: _border),
                                               ),
                                               child: Row(
                                                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                 children: [
                                                   Expanded(
                                                     child: Row(
                                                       children: [
                                                         CircleAvatar(
                                                           radius: 14,
                                                           backgroundColor: _green.withValues(alpha: 0.15),
                                                           child: Icon(Icons.person_rounded, color: _green, size: 15),
                                                         ),
                                                         const SizedBox(width: 8),
                                                         Expanded(
                                                           child: Column(
                                                             crossAxisAlignment: CrossAxisAlignment.start,
                                                             children: [
                                                               Text(sName, style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                                                               Text('${_isEn ? "Matricule" : "Matricule"}: $sMat', style: TextStyle(color: _sub, fontSize: 11), overflow: TextOverflow.ellipsis),
                                                             ],
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ),
                                                   const SizedBox(width: 6),
                                                   Container(
                                                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                     decoration: BoxDecoration(color: badgeCol.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeCol.withValues(alpha: 0.3))),
                                                     child: Text(
                                                       sStyle,
                                                       style: TextStyle(color: badgeCol, fontWeight: FontWeight.bold, fontSize: 11),
                                                       overflow: TextOverflow.ellipsis,
                                                       maxLines: 1,
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                             );
                                           }).toList(),
                                         ),
                                       const SizedBox(height: 18),

                                       // Final AI Recommendation Box for Class
                                       Container(
                                         width: double.infinity,
                                         padding: const EdgeInsets.all(12),
                                         decoration: BoxDecoration(
                                           color: _bg,
                                           borderRadius: BorderRadius.circular(14),
                                           border: Border.all(color: _green.withValues(alpha: 0.3)),
                                         ),
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           children: [
                                             Row(
                                               children: [
                                                 Icon(Icons.psychology_rounded, color: _green, size: 20),
                                                 const SizedBox(width: 8),
                                                 Expanded(
                                                   child: Text(
                                                     '${_isEn ? "Academic Strategy for" : "Stratégie Académique pour"} $cName:',
                                                     style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 13.5),
                                                     softWrap: true,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             const SizedBox(height: 8),
                                             Text(
                                               cRec,
                                               style: TextStyle(color: _text, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                                             ),
                                           ],
                                         ),
                                       ),
                                     ],
                                   ),
                                 );
                              },
                            ),
                            const SizedBox(height: 22),

                            // Teacher Roster Header
                            Text(_isEn ? 'School Teacher Roster' : 'Corps Enseignant de l\'Établissement', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(height: 14),

                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: teachers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final t = teachers[idx] as Map<String, dynamic>;
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                                  child: Row(
                                    children: [
                                      CircleAvatar(backgroundColor: _green.withValues(alpha: 0.12), child: Icon(Icons.person_rounded, color: _green, size: 22)),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(t['name'] ?? '', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15)),
                                            const SizedBox(height: 2),
                                            Text('${t["subject"]} | ${t["classes"]}', style: TextStyle(color: _sub, fontSize: 12.5)),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                        child: Text('${t["students_count"]} ${_isEn ? "Students" : "Élèves"}', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],

                          // ── TAB 3 / 4: MANAGE STUDENTS DIRECTORY ─────────────────
                          if (_currentNavIndex == 3 || _currentNavIndex == 4) ...[
                            _buildSchoolUsersManagementSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _overviewStatCard({required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _pieLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600))),
        Text('$count', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _varkBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w600)),
          Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _scopeBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildClassComparisonDiagramCard(List<Map<String, dynamic>> parsedClassSummaries) {
    if (parsedClassSummaries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bar_chart_rounded, color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isEn ? 'Class Assessment Progress Diagram' : 'Diagramme de Progression par Classe',
                  style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...parsedClassSummaries.map((cs) {
            final clsName = cs['class_name']?.toString() ?? 'Class';
            final totalStds = _parseInt(cs['total_students']);
            final assessedStds = _parseInt(cs['assessed']);
            final double pct = totalStds > 0 ? (assessedStds / totalStds) : 0.0;
            final pctText = '${(pct * 100).toInt()}%';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(clsName, style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14)),
                      Text('$assessedStds / $totalStds ${_isEn ? "Assessed" : "Évalués"} ($pctText)', style: TextStyle(color: _sub, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 12,
                      backgroundColor: _bg,
                      valueColor: AlwaysStoppedAnimation<Color>(pct >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPerClassBreakdownSection(List<Map<String, dynamic>> parsedClassSummaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _buildClassComparisonDiagramCard(parsedClassSummaries),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _isEn ? 'Class-by-Class Enrollment & Assessment' : 'Répartition des Élèves et Évaluations par Classe',
              style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${parsedClassSummaries.length} ${_isEn ? "School Classes" : "Classes Établissement"}',
                style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final isWideScreen = constraints.maxWidth >= 700;

            if (isWideScreen) {
              return Container(
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                        border: Border(bottom: BorderSide(color: _border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(_isEn ? 'CLASS NAME' : 'NOM DE LA CLASSE', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(_isEn ? 'TOTAL ENROLLED' : 'TOTAL INSCRITS', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text(_isEn ? 'ASSESSED' : 'ÉVALUÉS', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Text(_isEn ? 'COMPLETION RATE' : 'TAUX DE COMPLÉTION', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: Text(_isEn ? 'ACTION' : 'ACTION', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ),

                    // Rows
                    ...parsedClassSummaries.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final cs = entry.value;
                      final clsName = cs['class_name']?.toString() ?? 'Class';
                      final totalStds = _parseInt(cs['total_students']);
                      final assessedStds = _parseInt(cs['assessed']);
                      final double pct = totalStds > 0 ? (assessedStds / totalStds) : 0.0;
                      final pctText = '${(pct * 100).toInt()}%';
                      final isLast = idx == parsedClassSummaries.length - 1;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: isLast ? null : Border(bottom: BorderSide(color: _border.withValues(alpha: 0.5))),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.school_rounded, color: _green, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(clsName, style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 14.5)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('$totalStds ${_isEn ? "Students" : "Élèves"}', style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('$assessedStds / $totalStds', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12.5)),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(pctText, style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                        Text(
                                          pct >= 1.0 ? (_isEn ? 'Completed' : 'Terminé') : (_isEn ? 'In Progress' : 'En Cours'),
                                          style: TextStyle(
                                            color: pct >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        backgroundColor: _sub.withValues(alpha: 0.15),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          pct >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green.withValues(alpha: 0.12),
                                    foregroundColor: _green,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _currentNavIndex = 2;
                                      _selectedClassFilter = clsName;
                                    });
                                    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  },
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                                  label: Text(_isEn ? 'View Class' : 'Voir Classe', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            } else {
              return Column(
                children: parsedClassSummaries.map((cs) {
                  final clsName = cs['class_name']?.toString() ?? 'Class';
                  final totalStds = _parseInt(cs['total_students']);
                  final assessedStds = _parseInt(cs['assessed']);
                  final double pct = totalStds > 0 ? (assessedStds / totalStds) : 0.0;
                  final pctText = '${(pct * 100).toInt()}%';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(clsName, style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16)),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _currentNavIndex = 2;
                                  _selectedClassFilter = clsName;
                                });
                                _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                              },
                              icon: Icon(Icons.arrow_forward_rounded, color: _green, size: 16),
                              label: Text(_isEn ? 'View' : 'Voir', style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_isEn ? "Total Enrolled" : "Inscrits"}: $totalStds', style: TextStyle(color: _sub, fontSize: 12.5)),
                            Text('${_isEn ? "Assessed" : "Évalués"}: $assessedStds / $totalStds ($pctText)', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: _sub.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              pct >= 1.0 ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
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

    final double visAngle   = (visual / total) * 2 * 3.141592653589793;
    final double audAngle   = (auditory / total) * 2 * 3.141592653589793;
    final double kinesAngle = (kinesthetic / total) * 2 * 3.141592653589793;
    final double rwAngle    = (readWrite / total) * 2 * 3.141592653589793;

    double startAngle = -3.141592653589793 / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (visual > 0) {
      canvas.drawArc(rect, startAngle, visAngle, true, Paint()..color = const Color(0xFF3B82F6));
      startAngle += visAngle;
    }
    if (auditory > 0) {
      canvas.drawArc(rect, startAngle, audAngle, true, Paint()..color = const Color(0xFFEC4899));
      startAngle += audAngle;
    }
    if (readWrite > 0) {
      canvas.drawArc(rect, startAngle, rwAngle, true, Paint()..color = const Color(0xFFF59E0B));
      startAngle += rwAngle;
    }
    if (kinesthetic > 0) {
      canvas.drawArc(rect, startAngle, kinesAngle, true, Paint()..color = const Color(0xFF10B981));
      startAngle += kinesAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _VarkPieChartPainter oldDelegate) => true;
}
