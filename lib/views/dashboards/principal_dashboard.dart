import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';

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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Color get _green  => const Color(0xFF006A4E);
  Color get _bg     => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _card   => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _text   => _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => _isDarkMode ? Colors.white60 : const Color(0xFF64748B);
  Color get _border => _isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _isDarkMode = widget.isDarkMode;
    _isEn = widget.isEn;
    _fetchSchoolData();
  }

  Future<void> _fetchSchoolData() async {
    setState(() => _isLoading = true);
    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/minesec_api/api/dashboard.php?action=principal_school&principal_id=${_currentUser.id}'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() {
          _schoolData = data['data'];
          _isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (_) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    setState(() {
      _isLoading = false;
      _schoolData = {
        'school_name': 'LYCEE TECHNIQUE DE NGAOUNDAL',
        'principal_name': _currentUser.fullName,
        'matricule': _currentUser.matNumber ?? 'P2026001',
        'region': _currentUser.region ?? 'ADAMOUA',
        'division': _currentUser.division ?? 'DJEREM',
        'total_students': 450,
        'assessed_students': 380,
        'total_teachers': 28,
        'visual_count': 140,
        'auditory_count': 110,
        'kinesthetic_count': 70,
        'read_write_count': 60,
      };
    });
  }

  void _showPrincipalProfileDialog() async {
    final passCtrl    = TextEditingController(text: 'password123');
    final secCodeCtrl = TextEditingController(text: '1234');
    bool obscurePass  = true;
    bool obscureSec   = true;
    bool saving       = false;

    try {
      final res = await http.get(
        Uri.parse('http://localhost:8080/minesec_api/api/auth.php?action=get_profile&user_id=${_currentUser.id}'),
      );
      final pData = jsonDecode(res.body);
      if (pData['success'] == true && pData['data'] != null) {
        final profile = pData['data'];
        if (profile['password'] != null) passCtrl.text = profile['password'];
        if (profile['security_code'] != null) secCodeCtrl.text = profile['security_code'];
      }
    } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
                      gradient: LinearGradient(
                        colors: [_green, const Color(0xFF009966)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
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
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                                child: Text(
                                  _isEn ? 'Principal / Headmaster' : 'Proviseur / Directeur',
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

                  _profileInfoRow(Icons.person_outline_rounded, _isEn ? 'Full Name' : 'Nom Complet', _currentUser.fullName),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.school_outlined, _isEn ? 'School' : 'École', 'LYCEE TECHNIQUE DE NGAOUNDAL'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.map_outlined, _isEn ? 'Region' : 'Région', _currentUser.region ?? 'ADAMOUA'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.location_city_outlined, _isEn ? 'Division' : 'Département', _currentUser.division ?? 'DJEREM'),
                  const SizedBox(height: 14),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isEn ? 'Modify Present Password & Security Code' : 'Modifier Mot de Passe & Code de Sécurité',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 1. PRESENT PASSWORD INPUT (FIRST)
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: _isEn ? 'Present Password' : 'Mot de Passe Présent',
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

                  // 2. PRESENT SECURITY CODE INPUT (SECOND)
                  TextField(
                    controller: secCodeCtrl,
                    obscureText: obscureSec,
                    keyboardType: TextInputType.visiblePassword,
                    decoration: InputDecoration(
                      labelText: _isEn ? 'Present Security Code (e.g. 1234 or SEC#2026)' : 'Code de Sécurité Présent (ex: 1234 ou SEC#2026)',
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
                  const SizedBox(height: 18),

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
                          final resp = await http.post(
                            Uri.parse('http://localhost:8080/minesec_api/api/auth.php?action=update_profile'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode({
                              'user_id': _currentUser.id,
                              if (newPass.isNotEmpty) 'password': newPass,
                              if (newSec.isNotEmpty) 'security_code': newSec,
                            }),
                          );

                          if (mounted) {
                            Navigator.pop(ctx);
                          } else {
                            setModalState(() => saving = false);
                          }
                        } catch (e) {
                          setModalState(() => saving = false);
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
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
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

  int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return double.tryParse(val)?.toInt() ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final schoolName  = _schoolData?['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL';
    final totalSt     = _parseInt(_schoolData?['total_students']);
    final assessedSt  = _parseInt(_schoolData?['assessed_students']);
    final totalTech   = _parseInt(_schoolData?['total_teachers']);

    final isWide = MediaQuery.of(context).size.width >= 800;

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      onItemSelected: (idx) => setState(() => _currentNavIndex = idx),
      onOpenProfile: _showPrincipalProfileDialog,
      onToggleTheme: () => setState(() => _isDarkMode = !_isDarkMode),
      onToggleLanguage: () => setState(() => _isEn = !_isEn),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: isWide ? null : sidebarWidget,
      body: Row(
        children: [
          if (isWide) sidebarWidget,
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF0B132B),
                    border: Border(bottom: BorderSide(color: _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFF1E293B))),
                  ),
                  child: Row(
                    children: [
                      if (!isWide)
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 38, height: 38,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            padding: const EdgeInsets.all(2),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/minesec_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, _, __) => const Icon(Icons.school_rounded, color: Color(0xFF006A4E), size: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EDU PROFILE',
                                style: TextStyle(
                                  color: Color(0xFFFCD116),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                _isEn ? 'Principal Workspace' : 'Espace Proviseur',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => setState(() => _isDarkMode = !_isDarkMode),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF334155),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 1.5),
                              ),
                              child: Icon(
                                _isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                                color: const Color(0xFFFCD116),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 36,
                            width: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () { if (!_isEn) setState(() => _isEn = true); },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isEn ? const Color(0xFF006A4E) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'EN',
                                        style: TextStyle(
                                          color: _isEn ? Colors.white : Colors.white54,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () { if (_isEn) setState(() => _isEn = false); },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !_isEn ? const Color(0xFF006A4E) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'FR',
                                        style: TextStyle(
                                          color: !_isEn ? Colors.white : Colors.white54,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                            onPressed: _showPrincipalProfileDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Principal Header Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [_green, const Color(0xFF009966)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: _green.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(schoolName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 4),
                              Text('${_isEn ? "Principal" : "Proviseur"}: ${_currentUser.fullName}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _scopeBadge(Icons.badge_rounded, 'Matricule: ${_currentUser.matNumber ?? "P2026001"}'),
                                  _scopeBadge(Icons.map_rounded, _currentUser.region ?? 'ADAMOUA'),
                                  _scopeBadge(Icons.location_city_rounded, _currentUser.division ?? 'DJEREM'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stats Grid
                        Row(
                          children: [
                            Expanded(child: _statCard(_isEn ? 'Total Students' : 'Total Élèves', '$totalSt', Icons.groups_rounded, const Color(0xFF3B82F6))),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard(_isEn ? 'Assessed Students' : 'Élèves Évalués', '$assessedSt', Icons.task_alt_rounded, const Color(0xFF10B981))),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard(_isEn ? 'Total Teachers' : 'Corps Enseignant', '$totalTech', Icons.co_present_rounded, const Color(0xFF8B5CF6))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _scopeBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
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
}
