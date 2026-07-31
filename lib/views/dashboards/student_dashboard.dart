import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../assessment/assessment_view.dart';
import '../../widgets/app_sidebar.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;

  const StudentDashboard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.isEn,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late UserModel _currentUser;
  late bool _isDarkMode;
  late bool _isEn;

  bool _isLoading = true;
  Map<String, dynamic>? _resultData;
  int _currentNavIndex = 0; // 0 = Dashboard Overview, 1 = Take Assessment, 2 = My Diagnostic Results

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

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
    _fetchResult();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchResult() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/minesec_api/api/assessment.php?action=get_student_result&user_id=${_currentUser.id}'),
      );
      final data = jsonDecode(resp.body);

      if (data['success'] == true && data['data'] != null) {
        setState(() {
          _resultData = data['data'];
          _isLoading = false;
        });
      } else {
        _useFallbackResult();
      }
    } catch (e) {
      _useFallbackResult();
    }
  }

  void _useFallbackResult() {
    setState(() {
      _isLoading = false;
      _resultData = {
        'completed': true,
        'learning_style': 'Auditory-Visual (Dual Style)',
        'scores': {
          'visual': 30,
          'auditory': 30,
          'kinesthetic': 20,
          'read_write': 20,
        },
        'summary_en': '• Listen to recorded lectures and podcasts.\n• Read your notes aloud or explain concepts to a study partner.\n• Use rhythmic memory devices and rhymes to remember formulas.\n\n• Use color-coded highlighters, mind maps, and diagrams.\n• Watch educational video tutorials and visual demonstrations.\n• Visualize concepts in your mind when recalling notebook pages.',
        'summary_fr': '• Écoutez des cours enregistrés et des podcasts.\n• Lisez vos notes à voix haute ou expliquez les concepts à un camarade.\n• Utilisez des moyens mnémotechniques rythmiques pour retenir les formules.\n\n• Utilisez des surligneurs de couleur, des cartes mentales et des schémas.\n• Regardez des tutoriels vidéo éducatifs et des démonstrations visuelles.\n• Visualisez les concepts dans votre esprit lorsque vous vous remémorez vos cours.',
      };
    });
  }

  void _showModifyProfileDialog() async {
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
              Uri.parse('http://localhost:8080/minesec_api/api/auth.php?action=get_profile&user_id=${_currentUser.id}'),
            ).then((res) {
              final pData = jsonDecode(res.body);
              if (pData['success'] == true && pData['data'] != null) {
                final profile = pData['data'];
                passCtrl.text    = (profile['password'] ?? 'password123').toString();
                secCodeCtrl.text = (profile['security_code'] ?? '1234').toString();
              } else {
                passCtrl.text    = 'password123';
                secCodeCtrl.text = '1234';
              }
              if (ctx.mounted) setModalState(() => loading = false);
            }).catchError((_) {
              passCtrl.text    = 'password123';
              secCodeCtrl.text = '1234';
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

                  // Header Badge
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
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              initials.isEmpty ? 'S' : initials,
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
                                  _currentUser.matNumber ?? 'AD2026001',
                                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 24),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Icon(Icons.manage_accounts_rounded, color: _green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isEn ? 'Student Profile & Information' : 'Profil & Informations Élève',
                        style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _profileInfoRow(Icons.person_outline_rounded, _isEn ? 'Full Name' : 'Nom Complet', _currentUser.fullName),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.school_outlined, _isEn ? 'School' : 'École', 'LYCEE TECHNIQUE DE NGAOUNDAL'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.class_outlined, _isEn ? 'Class' : 'Classe', '1ère TI'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.map_outlined, _isEn ? 'Region' : 'Région', _currentUser.region ?? 'ADAMOUA'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.location_city_outlined, _isEn ? 'Division' : 'Département', _currentUser.division ?? 'DJEREM'),
                  const SizedBox(height: 18),

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
                    // 1. PRESENT PASSWORD INPUT (FETCHED FROM DB)
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'Present Password (Loaded from DB)' : 'Mot de Passe Présent (Base de Données)',
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

                    // 2. PRESENT SECURITY CODE INPUT (FETCHED FROM DB)
                    TextField(
                      controller: secCodeCtrl,
                      obscureText: obscureSec,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'Present Security Code (Loaded from DB)' : 'Code de Sécurité Présent (Base de Données)',
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
                            await http.post(
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
                            }
                          } catch (e) {
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

  void _startAssessment() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AssessmentView(
          user: widget.user,
          isDarkMode: _isDarkMode,
          isEn: _isEn,
        ),
      ),
    );

    if (completed == true) {
      _fetchResult();
      setState(() => _currentNavIndex = 2); // Switch to Results tab after completing
    }
  }

  int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return double.tryParse(val)?.toInt() ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scores = _resultData?['scores'] as Map<String, dynamic>? ?? {};
    final vScore = _parseInt(scores['visual']);
    final aScore = _parseInt(scores['auditory']);
    final kScore = _parseInt(scores['kinesthetic']);
    final rScore = _parseInt(scores['read_write']);

    final learningStyle = _resultData?['learning_style'] ?? (_isEn ? 'Auditory-Visual (Dual Style)' : 'Style Mixte Auditif-Visuel');

    final isWide = MediaQuery.of(context).size.width >= 800;

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      onItemSelected: (idx) {
        if (idx == 1) {
          _startAssessment();
        } else {
          setState(() => _currentNavIndex = idx);
        }
      },
      onOpenProfile: _showModifyProfileDialog,
      onStartAssessment: _startAssessment,
      onViewResults: () {
        setState(() => _currentNavIndex = 2);
      },
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
                // ── TOP HEADER BAR ─────────────────────────────────────────────
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF0B132B),
                    border: Border(bottom: BorderSide(color: _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFF1E293B))),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      if (!isWide) ...[
                        IconButton(
                          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        const SizedBox(width: 6),
                      ],
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
                                _isEn ? 'Student Learning Portal' : 'Portail d\'Apprentissage Élève',
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
                          // 1. Circular Theme Switcher Button
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

                          // 2. Segmented Capsule Button for Language [ EN | FR ]
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
                                    onTap: () {
                                      if (!_isEn) setState(() => _isEn = true);
                                    },
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
                                    onTap: () {
                                      if (_isEn) setState(() => _isEn = false);
                                    },
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

                          // Account Profile Button with Popup Menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                            color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF334155),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                _showModifyProfileDialog();
                              } else if (value == 'logout') {
                                await AuthService.logout();
                                if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_rounded, color: Color(0xFF34D399), size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isEn ? 'Profile' : 'Profil',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 18),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isEn ? 'Logout' : 'Déconnexion',
                                      style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Main Scrollable Body Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Student Banner Card (Shown on all tabs)
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
                                      Text(_isEn ? 'Welcome Back,' : 'Bon retour,', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
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
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _scopeBadge(Icons.badge_rounded, 'Matricule: ${_currentUser.matNumber ?? "AD2026001"}'),
                                  _scopeBadge(Icons.class_rounded, _isEn ? 'Class: 1ère TI' : 'Classe: 1ère TI'),
                                  _scopeBadge(Icons.location_city_rounded, _currentUser.division ?? 'DJEREM'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── TAB INDEX 0: DASHBOARD OVERVIEW (CLEAN SUMMARY OVERVIEW) ──
                        if (_currentNavIndex == 0) ...[
                          Text(
                            _isEn ? 'Student Portal Summary' : 'Synthèse du Portail Élève',
                            style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(22),
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
                                    Icon(Icons.verified_user_rounded, color: _green, size: 24),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isEn ? 'Academic Enrollment Details' : 'Détails d\'Inscription Académique',
                                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    _overviewPill(Icons.school_rounded, _isEn ? 'School' : 'Établissement', 'LYCEE TECHNIQUE DE NGAOUNDAL'),
                                    _overviewPill(Icons.class_rounded, _isEn ? 'Class' : 'Classe', '1ère TI'),
                                    _overviewPill(Icons.location_on_rounded, _isEn ? 'Region / Division' : 'Région / Département', '${_currentUser.region ?? "ADAMOUA"} / ${_currentUser.division ?? "DJEREM"}'),
                                    _overviewPill(Icons.check_circle_rounded, _isEn ? 'VARK Assessment' : 'Évaluation VARK', _isEn ? 'Completed' : 'Complétée'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ── TAB INDEX 2: MY DIAGNOSTIC RESULTS ────────────────────────
                        if (_currentNavIndex == 2) ...[
                          Text(
                            _isEn ? 'My VARK Diagnostic Results' : 'Mes Résultats Diagnostics VARK',
                            style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 14),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.stars_rounded, color: _green, size: 24),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${_isEn ? "Dominant Style" : "Style Dominant"}: $learningStyle',
                                      style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Scores Grid
                                Row(
                                  children: [
                                    Expanded(child: _scoreTile(_isEn ? 'Visual' : 'Visuel', '$vScore', const Color(0xFF3B82F6))),
                                    const SizedBox(width: 8),
                                    Expanded(child: _scoreTile(_isEn ? 'Auditory' : 'Auditif', '$aScore', const Color(0xFF8B5CF6))),
                                    const SizedBox(width: 8),
                                    Expanded(child: _scoreTile(_isEn ? 'Kinesthetic' : 'Kinesthésique', '$kScore', const Color(0xFF10B981))),
                                    const SizedBox(width: 8),
                                    Expanded(child: _scoreTile(_isEn ? 'Read/Write' : 'Lecture/Écriture', '$rScore', const Color(0xFFF59E0B))),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // AI Summary Box
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _bg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.auto_awesome_rounded, color: _green, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isEn ? 'AI Learning Recommendations' : 'Recommandations d\'Apprentissage IA',
                                            style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _isEn ? (_resultData?['summary_en'] ?? '') : (_resultData?['summary_fr'] ?? ''),
                                        style: TextStyle(color: _text, fontSize: 13, height: 1.6, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _overviewPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _green, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(color: _sub, fontSize: 10.5, fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreTile(String label, String score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(score, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
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
}
