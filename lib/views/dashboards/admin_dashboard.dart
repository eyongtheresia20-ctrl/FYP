import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/vark_academic_engine.dart';
import '../../widgets/app_sidebar.dart';
import '../../core/api_config.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;

  const AdminDashboard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.isEn,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late UserModel _currentUser;
  late bool _isDarkMode;
  late bool _isEn;

  bool _isLoading = true;
  Map<String, dynamic>? _adminData;
  String? _selectedRegionFilter;
  int _currentNavIndex = 0;

  // Selected Class details state
  String? _selectedSchoolFilter;
  String? _selectedClassFilter;
  Map<String, dynamic>? _classDetailsData;
  bool _isLoadingClassDetails = false;

  // User Management state
  List<dynamic> _allUsersList = [];
  List<dynamic> _allSchoolsList = [];
  bool _isLoadingUsers = false;
  String _userRoleFilter = 'ALL';
  bool _showSchoolsSection = false;
  String _userSearchQuery = '';

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
    _fetchAdminData();
    _fetchAllUsersAndSchools();
    _fetchSchoolDetails('LYCEE TECHNIQUE DE NGAOUNDAL');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);
    try {
      await ApiConfig.getWorkingHost();
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard.php?action=admin_analytics&user_id=${_currentUser.id}'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() {
          _adminData = data['data'];
          _isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (_) {
      _useFallbackData();
    }
  }

  Future<void> _fetchSchoolDetails(String schoolName) async {
    setState(() {
      _selectedSchoolFilter = schoolName;
      _isLoadingClassDetails = true;
    });
    try {
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_school_details&school_name=${Uri.encodeComponent(schoolName)}'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true && data['data'] != null) {
        setState(() {
          _classDetailsData = data['data'];
          _isLoadingClassDetails = false;
        });
      } else {
        setState(() => _isLoadingClassDetails = false);
      }
    } catch (_) {
      setState(() => _isLoadingClassDetails = false);
    }
  }

  Future<void> _fetchAllUsersAndSchools() async {
    setState(() => _isLoadingUsers = true);
    try {
      final uResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_all_users'),
      );
      final uData = jsonDecode(uResp.body);

      final sResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=get_all_schools'),
      );
      final sData = jsonDecode(sResp.body);

      setState(() {
        if (uData['success'] == true && uData['data'] != null) {
          _allUsersList = uData['data'] as List;
        }
        if (sData['success'] == true && sData['data'] != null) {
          _allSchoolsList = sData['data'] as List;
        }
        _isLoadingUsers = false;
      });
    } catch (_) {
      setState(() => _isLoadingUsers = false);
    }
  }

  List<String> _getDivisionsForRegion(String regionName) {
    if (_adminData != null && _adminData!['regions'] is List) {
      final regList = _adminData!['regions'] as List;
      for (final r in regList) {
        if ((r['name'] ?? '').toString().toUpperCase() == regionName.toUpperCase()) {
          final divs = r['divisions'] as List? ?? [];
          final divNames = divs.map((d) => (d['name'] ?? '').toString()).where((n) => n.isNotEmpty).toList();
          if (divNames.isNotEmpty) return divNames;
        }
      }
    }
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

  void _showEditSchoolDialog(Map<String, dynamic> school) {
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

  void _showAddSchoolDialog() {
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
                    Text(_isEn ? 'School Name:' : 'Nom de l\'Établissement :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEn ? 'Please enter a school name' : 'Veuillez saisir un nom d\'établissement')));
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

  void _showAddUserDialog() {
    final nameCtrl      = TextEditingController();
    final matCtrl       = TextEditingController();
    final birthDateCtrl = TextEditingController();
    final classCtrl     = TextEditingController();
    final subjectCtrl   = TextEditingController();

    String selectedRole     = 'student';
    String selectedGender   = 'M';
    String selectedRegion   = 'ADAMOUA';
    List<String> currentDivisions = _getDivisionsForRegion(selectedRegion);
    String selectedDivision = currentDivisions.first;
    int? selectedSchoolId   = _allSchoolsList.isNotEmpty ? _parseInt(_allSchoolsList.first['id']) : 1;

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
                Icon(Icons.person_add_rounded, color: _green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isEn ? 'Create User Account' : 'Créer un Compte',
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
                    // System Role
                    Text(_isEn ? 'System Role:' : 'Rôle Système :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      isExpanded: true,
                      dropdownColor: _card,
                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(value: 'regional_delegate', child: Text(_isEn ? 'Regional Delegate' : 'Délégué Régional', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'principal', child: Text(_isEn ? 'Principal' : 'Proviseur', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'dean_of_studies', child: Text(_isEn ? 'Dean of Studies' : 'Censeur', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'teacher', child: Text(_isEn ? 'Teacher' : 'Enseignant', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'student', child: Text(_isEn ? 'Student' : 'Élève', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Full Name
                    Text(_isEn ? 'Full Name:' : 'Nom Complet :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: _text, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: '',
                        prefixIcon: Icon(Icons.person_outline, color: _green, size: 18),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Matricule & Gender (Gender + DOB ONLY FOR STUDENT)
                    if (selectedRole == 'student') ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isEn ? 'Matricule / Student ID:' : 'Matricule :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: matCtrl,
                                  style: TextStyle(color: _text, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '',
                                    prefixIcon: Icon(Icons.badge_outlined, color: _green, size: 18),
                                    filled: true, fillColor: _bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isEn ? 'Gender:' : 'Genre :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: selectedGender,
                                  isExpanded: true,
                                  dropdownColor: _card,
                                  style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12.5),
                                  decoration: InputDecoration(
                                    filled: true, fillColor: _bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: [
                                    DropdownMenuItem(value: 'M', child: Text(_isEn ? 'Male (M)' : 'Masculin (M)', overflow: TextOverflow.ellipsis)),
                                    DropdownMenuItem(value: 'F', child: Text(_isEn ? 'Female (F)' : 'Féminin (F)', overflow: TextOverflow.ellipsis)),
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
                      const SizedBox(height: 12),

                      // Date of Birth (ONLY FOR STUDENT)
                      Text(_isEn ? 'Date of Birth (YYYY-MM-DD):' : 'Date de Naissance :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      TextField(
                        controller: birthDateCtrl,
                        style: TextStyle(color: _text, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'YYYY-MM-DD',
                          prefixIcon: Icon(Icons.cake_outlined, color: _green, size: 18),
                          filled: true, fillColor: _bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      // Single Matricule field for all other roles
                      Text(_isEn ? 'Matricule / Staff ID:' : 'Matricule / Identifiant :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      TextField(
                        controller: matCtrl,
                        style: TextStyle(color: _text, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: '',
                          prefixIcon: Icon(Icons.badge_outlined, color: _green, size: 18),
                          filled: true, fillColor: _bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Region & Division Row (DIVISION REMOVED ONLY FOR REGIONAL DELEGATE)
                    if (selectedRole == 'regional_delegate') ...[
                      Text(_isEn ? 'Region:' : 'Région :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        value: selectedRegion,
                        isExpanded: true,
                        dropdownColor: _card,
                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12),
                        decoration: InputDecoration(
                          filled: true, fillColor: _bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: ['ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST'].map((r) {
                          return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedRegion = val;
                              currentDivisions = _getDivisionsForRegion(selectedRegion);
                              selectedDivision = currentDivisions.contains(selectedDivision) ? selectedDivision : currentDivisions.first;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isEn ? 'Region:' : 'Région :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: selectedRegion,
                                  isExpanded: true,
                                  dropdownColor: _card,
                                  style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12),
                                  decoration: InputDecoration(
                                    filled: true, fillColor: _bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: ['ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST'].map((r) {
                                    return DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() {
                                        selectedRegion = val;
                                        currentDivisions = _getDivisionsForRegion(selectedRegion);
                                        selectedDivision = currentDivisions.contains(selectedDivision) ? selectedDivision : currentDivisions.first;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isEn ? 'Division:' : 'Département :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: currentDivisions.contains(selectedDivision) ? selectedDivision : currentDivisions.first,
                                  isExpanded: true,
                                  dropdownColor: _card,
                                  style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12),
                                  decoration: InputDecoration(
                                    filled: true, fillColor: _bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  items: currentDivisions.map((d) {
                                    return DropdownMenuItem(value: d, child: Text(d, overflow: TextOverflow.ellipsis));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedDivision = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // School Dropdown (For Principal, Teacher, Student)
                    if (selectedRole != 'admin' && selectedRole != 'regional_delegate' && selectedRole != 'divisional_delegate') ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_isEn ? 'School:' : 'Établissement :', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showAddSchoolDialog();
                            },
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: _green, size: 14),
                                const SizedBox(width: 4),
                                Text(_isEn ? '+ Add School' : '+ Ajouter', style: TextStyle(color: _green, fontSize: 11.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int>(
                        value: selectedSchoolId,
                        isExpanded: true,
                        dropdownColor: _card,
                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12),
                        decoration: InputDecoration(
                          filled: true, fillColor: _bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: _allSchoolsList.map<DropdownMenuItem<int>>((sc) {
                          return DropdownMenuItem<int>(
                            value: _parseInt(sc['id']),
                            child: Text((sc['name'] ?? '').toString(), overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedSchoolId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Class / Subject fields for Teacher/Student
                    if (selectedRole == 'teacher' || selectedRole == 'student') ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_isEn ? 'Class Name:' : 'Classe :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: classCtrl,
                                  style: TextStyle(color: _text, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: '',
                                    prefixIcon: Icon(Icons.bookmark_outline, color: _green, size: 18),
                                    filled: true, fillColor: _bg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedRole == 'teacher') ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_isEn ? 'Subject:' : 'Matière :', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: subjectCtrl,
                                    style: TextStyle(color: _text, fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: '',
                                      prefixIcon: Icon(Icons.book_outlined, color: _green, size: 18),
                                      filled: true, fillColor: _bg,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub))),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(_isEn ? 'Create User' : 'Créer l\'Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () async {
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
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleUserStatus(int userId, int newStatus) async {
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin.php?action=toggle_user_status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'is_activated': newStatus}),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        if (mounted) {
          _fetchAllUsersAndSchools();
        }
      }
    } catch (err) {
      // silent catch
    }
  }

  Future<void> _deleteUserAccount(int userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text(_isEn ? 'Delete User Account' : 'Supprimer l\'Utilisateur', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          _isEn
              ? 'Are you sure you want to permanently delete account "$userName"? This action cannot be undone.'
              : 'Êtes-vous sûr de vouloir supprimer définitivement le compte "$userName" ? Cette action est irréversible.',
          style: TextStyle(color: _sub, fontSize: 13.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(_isEn ? 'Delete Permanently' : 'Supprimer Définitivement'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final resp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/admin.php?action=delete_user'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        );
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          if (mounted) {
            _fetchAllUsersAndSchools();
          }
        }
      } catch (err) {
        // silent catch
      }
    }
  }

  void _downloadAdminReport() {
    final title = _adminData?['title'] ?? 'MINISTÈRE DE L\'ENSEIGNEMENT SECONDAIRE — DIRECTION GÉNÉRALE';
    final admin = _currentUser.fullName;

    final totalRegions = _parseInt(_adminData?['total_regions'] ?? 10);
    final totalSchools = _parseInt(_adminData?['total_schools'] ?? 0);
    final totalStudents = _parseInt(_adminData?['total_students'] ?? 0);
    final assessedStudents = _parseInt(_adminData?['assessed_students'] ?? 0);
    final totalTeachers = _parseInt(_adminData?['total_teachers'] ?? 0);
    final visualCount = _parseInt(_adminData?['visual_count'] ?? 0);
    final auditoryCount = _parseInt(_adminData?['auditory_count'] ?? 0);
    final kinestheticCount = _parseInt(_adminData?['kinesthetic_count'] ?? 0);
    final readWriteCount = _parseInt(_adminData?['read_write_count'] ?? 0);

    final csvContent = '''MINESEC LST — National VARK System Report
"Field","Value"
"Title","$title"
"Administrator","$admin"
"Total Regions","$totalRegions"
"Total Schools","$totalSchools"
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.summarize_rounded, color: _green, size: 26),
            const SizedBox(width: 10),
            Text(_isEn ? 'National System Report' : 'Rapport Système National', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
              child: SelectableText(csvContent, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isEn ? 'Close' : 'Fermer', style: TextStyle(color: _sub))),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isEn ? 'National Report Downloaded Successfully!' : 'Rapport National Téléchargé avec Succès !'), backgroundColor: _green),
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
      _adminData = {
        'admin_name': _currentUser.fullName,
        'title': 'MINISTÈRE DE L\'ENSEIGNEMENT SECONDAIRE — DIRECTION GÉNÉRALE',
        'total_regions': 3,
        'total_schools': 6,
        'total_students': 2,
        'assessed_students': 1,
        'total_teachers': 1,
        'visual_count': 1,
        'auditory_count': 1,
        'kinesthetic_count': 0,
        'read_write_count': 0,
        'regions_analytics': [
          {'name': 'ADAMOUA', 'schools': 4, 'students': 2, 'assessed_pct': '50%'},
          {'name': 'CENTRE', 'schools': 1, 'students': 0, 'assessed_pct': '0%'},
          {'name': 'LITTORAL', 'schools': 1, 'students': 0, 'assessed_pct': '0%'},
        ],
        'ai_national_strategy_en': '• High Visual Preference Detected: Encourage visual mind maps, diagrams, color-coded study guides, and video presentations to boost student comprehension.\n• Auditory Support Directive: Facilitate interactive classroom discussions, group debates, and verbal lecture summaries to aid memory retention.\n• Kinesthetic & Practical Engagement: Equip schools with hands-on laboratory materials, interactive workshops, and kinesthetic learning kits.\n• Continuous Curriculum Support: Provide teachers with multi-sensory instructional guides to personalize support for every student profile.',
        'ai_national_strategy_fr': '• Forte Préférence Visuelle Détectée : Encouragez les cartes mentales visuelles, les schémas, les guides d\'étude en couleurs et les présentations vidéo pour booster la compréhension.\n• Directive d\'Accompagnement Auditif : Facilitez les discussions interactives en classe, les débats de groupe et les résumés de cours oraux pour renforcer la mémorisation.\n• Engagement Kinesthésique et Pratique : Équipez les établissements en matériel de laboratoire pratique, ateliers interactifs et kits d\'apprentissage kinesthésiques.\n• Accompagnement Pédagogique Continu : Fournissez aux enseignants des guides d\'enseignement multisensoriels pour personnaliser le suivi de chaque élève.',
      };
    });
  }

  void _showAdminProfileDialog() async {
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
                passCtrl.text    = (profile['password'] ?? 'admin1').toString();
                secCodeCtrl.text = (profile['security_code'] ?? '1234#').toString();
              } else {
                passCtrl.text    = 'admin1';
                secCodeCtrl.text = '1234#';
              }
              if (ctx.mounted) setModalState(() => loading = false);
            }).catchError((_) {
              passCtrl.text    = 'admin1';
              secCodeCtrl.text = '1234#';
              if (ctx.mounted) setModalState(() => loading = false);
            });
          }

          return Container(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: _border),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _green.withValues(alpha: 0.15),
                            child: Icon(Icons.admin_panel_settings_rounded, color: _green, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEn ? 'Admin Profile' : 'Profil Administrateur',
                                style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                _currentUser.fullName,
                                style: TextStyle(color: _sub, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: _sub),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (loading) ...[
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
                  ] else ...[
                    _profileInfoRow(Icons.badge_outlined, _isEn ? 'Matricule / Admin ID' : 'Matricule / Identifiant', _currentUser.matNumber ?? 'ADM202601'),
                    const SizedBox(height: 10),
                    _profileInfoRow(Icons.email_outlined, 'Email', 'admin@minesec.cm'),
                    const SizedBox(height: 10),
                    _profileInfoRow(Icons.security_rounded, _isEn ? 'Role' : 'Rôle', 'ADMINISTRATEUR CENTRAL MINESEC'),
                    const SizedBox(height: 16),

                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      style: TextStyle(color: _text),
                      decoration: InputDecoration(
                        labelText: _isEn ? 'New Password' : 'Nouveau Mot de passe',
                        labelStyle: TextStyle(color: _sub),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border)),
                        prefixIcon: Icon(Icons.lock_outline_rounded, color: _green),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility, color: _sub),
                          onPressed: () => setModalState(() => obscurePass = !obscurePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: secCodeCtrl,
                      obscureText: obscureSec,
                      style: TextStyle(color: _text),
                      decoration: InputDecoration(
                        labelText: _isEn ? 'New Security Code' : 'Nouveau Code de Sécurité',
                        labelStyle: TextStyle(color: _sub),
                        filled: true, fillColor: _bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _border)),
                        prefixIcon: Icon(Icons.pin_outlined, color: _green),
                        suffixIcon: IconButton(
                          icon: Icon(obscureSec ? Icons.visibility_off : Icons.visibility, color: _sub),
                          onPressed: () => setModalState(() => obscureSec = !obscureSec),
                        ),
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
                Expanded(child: _buildSettingsInlineView()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsInlineView() {
    return StatefulBuilder(
      builder: (ctx, setSt) => SingleChildScrollView(
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

            Text(_isEn ? 'APPEARANCE' : 'APPARENCE', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                    child: Icon(_isDarkMode ? Icons.nightlight_round_outlined : Icons.wb_sunny_outlined, color: _isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFFCD116), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEn ? 'Display Theme' : 'Thème d\'affichage', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5)),
                        Text(_isDarkMode ? (_isEn ? 'Dark Mode' : 'Mode Sombre') : (_isEn ? 'Light Mode' : 'Mode Clair'), style: TextStyle(color: _sub, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isDarkMode,
                    onChanged: (val) {
                      setState(() => _isDarkMode = val);
                      setSt(() {});
                    },
                    activeColor: const Color(0xFF34D399),
                    activeTrackColor: _green.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(_isEn ? 'LANGUAGE' : 'LANGUE', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.language_rounded, color: Colors.blueAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(_isEn ? 'App Language' : 'Langue de l\'application', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _isEn = true);
                            setSt(() {});
                          },
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
                          onTap: () {
                            setState(() => _isEn = false);
                            setSt(() {});
                          },
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

            Text(_isEn ? 'ACCOUNT PROFILE' : 'PROFIL DU COMPTE', style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _green,
                        child: Text(
                          _currentUser.fullName.isNotEmpty ? _currentUser.fullName[0].toUpperCase() : 'U',
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
                            Text('${_currentUser.role.toUpperCase()} | ${_currentUser.matNumber ?? "MINESEC2026"}', style: TextStyle(color: _sub, fontSize: 12)),
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
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAdminProfileDialog();
                      },
                      icon: const Icon(Icons.person_rounded, size: 18),
                      label: Text(_isEn ? 'Profile' : 'Profil', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalSchools  = _parseInt(_adminData?['total_schools'] ?? 6);
    final int totalStudents = _parseInt(_adminData?['total_students'] ?? 2);
    final int assessed      = _parseInt(_adminData?['assessed_students'] ?? 1);
    final int totalTeachers = _parseInt(_adminData?['total_teachers'] ?? 1);

    final int visSt   = _parseInt(_adminData?['visual_count'] ?? 1);
    final int audSt   = _parseInt(_adminData?['auditory_count'] ?? 1);
    final int kinesSt = _parseInt(_adminData?['kinesthetic_count'] ?? 0);
    final int rwSt    = _parseInt(_adminData?['read_write_count'] ?? 0);

    final List regions = _adminData?['regions_analytics'] as List? ?? [];
    final List<String> regionNames = [];
    for (var r in regions) {
      final name = (r['name'] ?? '').toString();
      if (name.isNotEmpty && !regionNames.contains(name)) {
        regionNames.add(name);
      }
    }
    if (regionNames.isEmpty) regionNames.addAll(['ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST']);

    final int visCount = _parseInt(_adminData?['visual_count'] ?? 0);
    final int audCount = _parseInt(_adminData?['auditory_count'] ?? 2);
    final int kinCount = _parseInt(_adminData?['kinesthetic_count'] ?? 0);
    final int rwCount  = _parseInt(_adminData?['read_write_count'] ?? 0);

    final educatorNationalRec = VarkAcademicEngine.evaluateForEducators(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
      contextName: 'National Territory',
    );
    final String aiStrategy = _isEn ? educatorNationalRec['en']! : educatorNationalRec['fr']!;

    final isWide = MediaQuery.of(context).size.width >= 800;
    final List nationalHierarchy = _adminData?['national_hierarchy'] as List? ?? [];

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      tickedClasses: regionNames,
      selectedClass: _selectedRegionFilter ?? regionNames.first,
      adminItems: nationalHierarchy,
      onClassSelected: (selection) {
        setState(() {
          _currentNavIndex = 2;
          if (selection.contains('::')) {
            final parts = selection.split('::');
            final scName = parts.last;
            _fetchSchoolDetails(scName);
          } else {
            _selectedRegionFilter = selection;
          }
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      onItemSelected: (idx) {
        setState(() => _currentNavIndex = idx);
        if (idx == 3) {
          _fetchAllUsersAndSchools();
        }
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

                // Main Content Body
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchAdminData,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(22),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TAB 0: DASHBOARD OVERVIEW ──────────────────────────────
                          if (_currentNavIndex == 0) ...[
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
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_isEn ? 'Welcome Back,' : 'Bienvenue,', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
                                            const SizedBox(height: 2),
                                            Text(_currentUser.fullName, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                                        child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 24),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: [
                                      _scopeBadge(Icons.public_rounded, 'Territoire: NATIONAL (10 Régions)'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 10, runSpacing: 10,
                              children: [
                                Text(_isEn ? 'National System Metrics' : 'Aperçu Exécutif National', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
                                ElevatedButton.icon(
                                  onPressed: _downloadAdminReport,
                                  style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  icon: const Icon(Icons.download_rounded, size: 16),
                                  label: Text(_isEn ? 'Download Report' : 'Exporter Rapport', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            LayoutBuilder(
                              builder: (ctx, constraints) {
                                final isSmall = constraints.maxWidth < 600;
                                final width = isSmall ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 36) / 4;
                                return Wrap(
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

                            // National VARK Learning Styles Breakdown Card (EXCLUSIVELY IN TAB 0: DASHBOARD OVERVIEW)
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
                          ],

                          // ── TAB 1: NATIONAL VARK ANALYTICS & POLICY ──────────────────
                          if (_currentNavIndex == 1) ...[
                            Text(_isEn ? 'National Educational Policy' : 'Directives Pédagogiques Nationales', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),
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
                                      Text(_isEn ? 'National Pedagogical Strategy' : 'Stratégie Pédagogique Nationale', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(aiStrategy, style: TextStyle(color: _text, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],

                          // ── TAB 2: GLOBAL SCHOOL OVERVIEW & VARK ANALYTICS ──────────
                          if (_currentNavIndex == 2) ...[
                            if (_isLoadingClassDetails) ...[
                              const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                            ] else if (_classDetailsData != null) ...[
                              Builder(
                                builder: (ctx) {
                                  final scName  = _classDetailsData!['school_name'] ?? '';
                                  final regName = _classDetailsData!['region'] ?? 'ADAMOUA';
                                  final divName = _classDetailsData!['division'] ?? 'DJEREM';
                                  final totSt   = _parseInt(_classDetailsData!['total_students']);
                                  final totCls  = _parseInt(_classDetailsData!['total_classes'] ?? 2);
                                  final totTch  = _parseInt(_classDetailsData!['total_teachers'] ?? 1);
                                  final assSt   = _parseInt(_classDetailsData!['assessed_students']);

                                  final vis = _parseInt(_classDetailsData!['visual_count']);
                                  final aud = _parseInt(_classDetailsData!['auditory_count']);
                                  final kin = _parseInt(_classDetailsData!['kinesthetic_count']);
                                  final rw  = _parseInt(_classDetailsData!['read_write_count']);

                                  final educatorScRec = VarkAcademicEngine.evaluateForEducators(
                                    auditory: aud,
                                    visual: vis,
                                    kinesthetic: kin,
                                    readWrite: rw,
                                    contextName: scName,
                                  );
                                  final aiRec = _isEn ? educatorScRec['en']! : educatorScRec['fr']!;

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Global School Statistics & Header Card
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _green.withValues(alpha: 0.35), width: 1.5),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _green.withValues(alpha: 0.08),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: _green.withValues(alpha: 0.14),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(Icons.account_balance_rounded, color: _green, size: 26),
                                                ),
                                                const SizedBox(width: 14),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _isEn ? 'Global School Overview' : 'Aperçu Global de l\'Établissement',
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
                                                        '${_isEn ? "Region" : "Région"}: $regName • ${_isEn ? "Division" : "Département"}: $divName',
                                                        style: TextStyle(color: _sub, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),

                                            // Key Metric Cards
                                            Row(
                                              children: [
                                                Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Élèves', value: '$totSt', color: const Color(0xFF3B82F6))),
                                                const SizedBox(width: 10),
                                                Expanded(child: _overviewStatCard(icon: Icons.meeting_room_rounded, label: _isEn ? 'Classes' : 'Classes', value: '$totCls', color: const Color(0xFF006A4E))),
                                                const SizedBox(width: 10),
                                                Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Teachers' : 'Enseignants', value: '$totTch', color: const Color(0xFF8B5CF6))),
                                                const SizedBox(width: 10),
                                                Expanded(child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'Assessed' : 'Évalués', value: '$assSt', color: const Color(0xFF10B981))),
                                              ],
                                            ),
                                            const SizedBox(height: 24),

                                            // Big VARK Pie Chart & Legend for School
                                            Text(
                                              _isEn ? 'School-Wide VARK Learning Styles Breakdown:' : 'Répartition VARK de l\'Établissement :',
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
                                                    _isEn ? 'Teaching Recommendations' : 'Recommandations pour l\'Enseignement',
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
                                  );
                                },
                              ),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(36),
                                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(18), border: Border.all(color: _border)),
                                child: Column(
                                  children: [
                                    Icon(Icons.touch_app_rounded, color: _green, size: 40),
                                    const SizedBox(height: 12),
                                    Text(
                                      _isEn ? 'Select a School from the Left Sidebar' : 'Sélectionnez un Établissement dans le Menu de Gauche',
                                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _isEn
                                          ? 'Expand Region ➔ Division ➔ School to view live statistics and institutional VARK AI policy.'
                                          : 'Déroulez Région ➔ Département ➔ Établissement pour afficher les statistiques et directives IA.',
                                      style: TextStyle(color: _sub, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],

                          // ── TAB 3: SYSTEM USER & GOVERNANCE DIRECTORY ───────────────
                          if (_currentNavIndex == 3) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Action Header Bar
                                LayoutBuilder(
                                  builder: (context, headerConstraints) {
                                    final isCompact = headerConstraints.maxWidth < 600;
                                    if (isCompact) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_isEn ? 'User & System Governance' : 'Gestion des Utilisateurs & Sécurité', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 17)),
                                          const SizedBox(height: 2),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _green,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              ),
                                              onPressed: _showAddUserDialog,
                                              icon: const Icon(Icons.person_add_rounded, size: 16),
                                              label: Text(_isEn ? '+ Create User' : '+ Créer un Utilisateur', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                            ),
                                          ),
                                        ],
                                      );
                                    }
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
                                ),
                                const SizedBox(height: 16),

                                // Toggle between Users & Schools
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  child: Row(
                                    children: [
                                      ChoiceChip(
                                        label: Text(_isEn ? 'Users (${_allUsersList.length})' : 'Utilisateurs (${_allUsersList.length})', style: TextStyle(color: !_showSchoolsSection ? Colors.white : _text, fontWeight: FontWeight.bold)),
                                        selected: !_showSchoolsSection,
                                        selectedColor: _green,
                                        backgroundColor: _card,
                                        onSelected: (val) => setState(() => _showSchoolsSection = false),
                                      ),
                                      const SizedBox(width: 10),
                                      ChoiceChip(
                                        label: Text(_isEn ? 'Schools (${_allSchoolsList.length})' : 'Établissements (${_allSchoolsList.length})', style: TextStyle(color: _showSchoolsSection ? Colors.white : _text, fontWeight: FontWeight.bold)),
                                        selected: _showSchoolsSection,
                                        selectedColor: const Color(0xFF0284C7),
                                        backgroundColor: _card,
                                        onSelected: (val) => setState(() => _showSchoolsSection = true),
                                      ),
                                    ],
                                  ),
                                ),

                                // Live Database List Table (Users or Schools)
                                if (_isLoadingUsers) ...[
                                  const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator())),
                                ] else if (_showSchoolsSection) ...[
                                  Builder(
                                    builder: (ctx) {
                                      final filteredSchools = _allSchoolsList.where((s) {
                                        final name = (s['name'] ?? '').toString().toLowerCase();
                                        final reg  = (s['region'] ?? '').toString().toLowerCase();
                                        final div  = (s['division'] ?? '').toString().toLowerCase();
                                        final town = (s['town'] ?? '').toString().toLowerCase();
                                        final q    = _userSearchQuery.toLowerCase();
                                        return q.isEmpty || name.contains(q) || reg.contains(q) || div.contains(q) || town.contains(q);
                                      }).toList();

                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(22),
                                        decoration: BoxDecoration(
                                          color: _card,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _border),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        _isEn ? 'Registered Schools Directory (${filteredSchools.length})' : 'Répertoire des Établissements Enregistrés (${filteredSchools.length})',
                                                        style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 17),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _isEn ? 'Institutional secondary & technical schools database' : 'Base de données des établissements scolaires enregistrés',
                                                        style: TextStyle(color: _sub, fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF0284C7),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  ),
                                                  onPressed: _showAddSchoolDialog,
                                                  icon: const Icon(Icons.add_business_rounded, size: 18),
                                                  label: Text(
                                                    _isEn ? '+ Add School' : '+ Ajouter un Établissement',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 18),
                                            if (filteredSchools.isEmpty) ...[
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(36),
                                                decoration: BoxDecoration(
                                                  color: _bg,
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(color: _border),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Icon(Icons.school_outlined, color: _sub, size: 42),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      _isEn ? 'No schools registered or matching search.' : 'Aucun établissement trouvé.',
                                                      style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.bold),
                                                    ),
                                                    const SizedBox(height: 14),
                                                    ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7), foregroundColor: Colors.white),
                                                      onPressed: _showAddSchoolDialog,
                                                      icon: const Icon(Icons.add_business_rounded, size: 16),
                                                      label: Text(_isEn ? '+ Register First School' : '+ Ajouter un Établissement'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ] else ...[
                                               // Full-Width Structured Table Header
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
                                               ),
                                            ],
                                          ],
                                        ),
] else ...[
                                  Builder(
                                    builder: (ctx) {
                                      final filteredUsers = _allUsersList.where((u) {
                                        final r = (u['role'] ?? '').toString();
                                        if (r == 'admin') return false;

                                        final name = (u['full_name'] ?? '').toString().toLowerCase();
                                        final mat  = (u['matricule'] ?? '').toString().toLowerCase();

                                        final matchesRole = (_userRoleFilter == 'ALL') || (r == _userRoleFilter);
                                        final matchesSearch = _userSearchQuery.isEmpty || name.contains(_userSearchQuery.toLowerCase()) || mat.contains(_userSearchQuery.toLowerCase());

                                        return matchesRole && matchesSearch;
                                      }).toList();

                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _isEn ? 'Registered Users Directory (${filteredUsers.length})' : 'Répertoire des Utilisateurs Enregistrés (${filteredUsers.length})',
                                              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 14),
                                            if (filteredUsers.isEmpty) ...[
                                              Text(_isEn ? 'No users matching criteria.' : 'Aucun utilisateur correspondant.', style: TextStyle(color: _sub, fontSize: 13)),
                                            ] else ...[
                                              SingleChildScrollView(
                                                scrollDirection: Axis.horizontal,
                                                child: DataTable(
                                                  headingRowColor: WidgetStateProperty.all(_bg),
                                                  dataRowMinHeight: 52,
                                                  dataRowMaxHeight: 64,
                                                  columnSpacing: 24,
                                                  columns: [
                                                    DataColumn(label: Text(_isEn ? 'User Name' : 'Nom & Utilisateur', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Role' : 'Rôle', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Matricule' : 'Matricule', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Region / Division' : 'Région / Dép.', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'School / Governance Entity' : 'Établissement / Structure', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Status' : 'Statut', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                    DataColumn(label: Text(_isEn ? 'Actions' : 'Actions', style: TextStyle(color: _sub, fontWeight: FontWeight.bold, fontSize: 12.5))),
                                                  ],
                                                  rows: filteredUsers.map<DataRow>((u) {
                                                    final uId     = _parseInt(u['id']);
                                                    final uName   = (u['full_name'] ?? '').toString();
                                                    final uRole   = (u['role'] ?? '').toString();
                                                    final uMat    = (u['matricule'] ?? 'N/A').toString();
                                                    final uReg    = (u['region'] ?? 'ADAMOUA').toString();
                                                    final uDiv    = (u['division'] ?? 'DJEREM').toString();
                                                    final uSchool = (u['school_name'] ?? '').toString();
                                                    final isAct   = _parseInt(u['is_activated']) == 1;

                                                    Color roleColor = Colors.teal;
                                                    if (uRole == 'regional_delegate') roleColor = const Color(0xFF2563EB);
                                                    if (uRole == 'divisional_delegate') roleColor = const Color(0xFF8B5CF6);
                                                    if (uRole == 'principal') roleColor = const Color(0xFFF59E0B);
                                                    if (uRole == 'teacher') roleColor = const Color(0xFF10B981);

                                                    return DataRow(
                                                      cells: [
                                                        DataCell(
                                                          Row(
                                                            children: [
                                                              CircleAvatar(
                                                                radius: 14,
                                                                backgroundColor: roleColor.withValues(alpha: 0.15),
                                                                child: Text(uName.isNotEmpty ? uName[0] : 'U', style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 11.5)),
                                                              ),
                                                              const SizedBox(width: 10),
                                                              Text(uName, style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13)),
                                                            ],
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                                            child: Text(
                                                              uRole.toUpperCase().replaceAll('_', ' '),
                                                              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 11),
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(Text(uMat, style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 12.5))),
                                                        DataCell(Text('$uReg / $uDiv', style: TextStyle(color: _sub, fontSize: 12))),
                                                        DataCell(Text(uSchool.isNotEmpty ? uSchool : 'N/A', style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w500))),
                                                        DataCell(
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                            decoration: BoxDecoration(
                                                              color: isAct ? _green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            child: Text(
                                                              isAct ? (_isEn ? 'Active' : 'Actif') : (_isEn ? 'Blocked' : 'Bloqué'),
                                                              style: TextStyle(color: isAct ? _green : Colors.red, fontWeight: FontWeight.bold, fontSize: 11.5),
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              IconButton(
                                                                icon: Icon(
                                                                  isAct ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                                                  color: isAct ? Colors.orange : _green,
                                                                  size: 20,
                                                                ),
                                                                tooltip: isAct ? (_isEn ? 'Block Account' : 'Bloquer le Compte') : (_isEn ? 'Activate Account' : 'Activer le Compte'),
                                                                onPressed: () => _toggleUserStatus(uId, isAct ? 0 : 1),
                                                              ),
                                                              IconButton(
                                                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                                                tooltip: _isEn ? 'Delete Account' : 'Supprimer le Compte',
                                                                onPressed: () => _deleteUserAccount(uId, uName),
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
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
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

  Widget _varkBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: ', style: TextStyle(color: _text, fontSize: 11.5, fontWeight: FontWeight.w600)),
          Text('$count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
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
  Widget _pieLegendItem(String label, int count, Color color) {
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
