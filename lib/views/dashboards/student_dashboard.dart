import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/localization.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/offline_assessment_service.dart';
import '../assessment/assessment_view.dart';

class StudentDashboard extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;
  const StudentDashboard({super.key, required this.user, required this.isDarkMode, required this.isEn});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> with SingleTickerProviderStateMixin {
  late UserModel _currentUser;
  late bool _isDarkMode;
  late bool _isEn;
  late TabController _tabController;

  bool _loadingResult = false;
  Map<String, dynamic>? _resultData;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _isDarkMode = widget.isDarkMode;
    _isEn = widget.isEn;
    _tabController = TabController(length: 2, vsync: this);
    _fetchResult();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchResult() async {
    setState(() => _loadingResult = true);

    // 1. Try API first so signing in to an existing account gets stored DB results
    try {
      final res = await http.get(
        Uri.parse('http://localhost:8080/minesec_api/api/assessment.php?action=get_result&user_id=${_currentUser.id}'),
      ).timeout(const Duration(seconds: 3));
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && data['success'] == true && data['data'] != null && data['data']['completed'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final encoded = jsonEncode(data['data']);
        await prefs.setString('vark_result_${_currentUser.id}', encoded);
        await prefs.setString('vark_latest_result', encoded);
        if (mounted) {
          setState(() {
            _resultData = data['data'];
            _loadingResult = false;
          });
        }
        return;
      }
    } catch (_) {
      // Ignore network errors and continue to local fallback
    }

    // 2. Fallback to local offline storage if offline or network unavailable
    final offlineRes = await OfflineAssessmentService.getStoredResult(_currentUser.id);
    if (mounted) {
      setState(() {
        _resultData = offlineRes;
        _loadingResult = false;
      });
    }
  }

  Color get _green  => const Color(0xFF006A4E);
  Color get _accent => _isDarkMode ? const Color(0xFF34D399) : const Color(0xFF006A4E);
  Color get _bg     => _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _card   => _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _text   => _isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => _isDarkMode ? Colors.white60 : const Color(0xFF64748B);
  Color get _border => _isDarkMode ? const Color(0x33FFFFFF) : const Color(0xFFE2E8F0);

  void _showModifyProfileDialog() {
    final roleLabel = _isEn ? 'Student' : 'Élève';

    final passCtrl    = TextEditingController(text: 'maru444t');
    final secCodeCtrl = TextEditingController(text: '1234');
    bool obscurePass  = true;
    bool obscureSec   = true;
    bool saving       = false;

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
                  // Drag handle
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Avatar + Name Header Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_green, const Color(0xFF34D399).withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              initials.isEmpty ? 'BO' : initials,
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
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  roleLabel,
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

                  // Title
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

                  // Read-only info cards: Name, School, Class, DOB, Region, Division
                  _profileInfoRow(Icons.person_outline_rounded, _isEn ? 'Full Name' : 'Nom Complet', _currentUser.fullName),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.school_outlined, _isEn ? 'School' : 'École', _currentUser.schoolId != null ? 'LYCEE TECHNIQUE DE NGAOUNDAL (ID: ${_currentUser.schoolId})' : 'LYCEE TECHNIQUE DE NGAOUNDAL'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.class_outlined, _isEn ? 'Class' : 'Classe', '1ère TI'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.cake_outlined, _isEn ? 'Date of Birth' : 'Date de Naissance', '2007-03-12'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.map_outlined, _isEn ? 'Region' : 'Région', _currentUser.region ?? 'ADAMOUA'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.location_city_outlined, _isEn ? 'Division' : 'Département', _currentUser.division ?? 'DJEREM'),
                  const SizedBox(height: 18),

                  // Section Header: Editable Password & Security Code
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _isEn ? 'Modify Security Code & Password' : 'Modifier Sécurité & Mot de Passe',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Security Code Input Field (Present / Editable)
                  TextField(
                    controller: secCodeCtrl,
                    obscureText: obscureSec,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _isEn ? 'Present Security Code (e.g. 1234)' : 'Code de Sécurité Présent (ex: 1234)',
                      labelStyle: TextStyle(color: _sub, fontSize: 12),
                      prefixIcon: Icon(Icons.security_rounded, color: _green, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(obscureSec ? Icons.visibility_off : Icons.visibility, color: _sub, size: 20),
                        onPressed: () => setModalState(() => obscureSec = !obscureSec),
                      ),
                      filled: true,
                      fillColor: _bg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _green, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Password Input Field (Present / Editable)
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _green, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Save / Modify Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: saving ? null : () async {
                        final newPass = passCtrl.text.trim();
                        final newSec  = secCodeCtrl.text.trim();

                        if (newPass.isEmpty && newSec.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_isEn ? 'Please enter a password or security code.' : 'Veuillez saisir un mot de passe ou code de sécurité.')),
                          );
                          return;
                        }

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

                          final data = jsonDecode(resp.body);
                          if (data['success'] == true) {
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: _green,
                                  content: Text(_isEn ? 'Security code & password updated in database!' : 'Code de sécurité et mot de passe mis à jour dans la base de données !'),
                                ),
                              );
                            }
                          } else {
                            setModalState(() => saving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(data['message'] ?? 'Failed to update credentials.')),
                            );
                          }
                        } catch (e) {
                          setModalState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Network error: $e')),
                          );
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

                  // Close button
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startAssessment() async {
    final completed = await Navigator.of(context).push<bool>(
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
      _tabController.animateTo(1); // Switch to My Results tab
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _resultData != null && (_resultData!['completed'] == true || _resultData!['learning_style'] != null);

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFF0B132B),
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFF1E293B),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 1. LEFT LOGO & TITLE
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
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
                      const SizedBox(width: 12),
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
                            _isEn ? 'Learning Style Tracker' : 'Traqueur de Style d\'Apprentissage',
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

                  // 3. RIGHT ACTIONS (Theme Toggle + Language Pill + Account Dropdown)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Theme Mode Toggle (Moon icon in dark circle container)
                      GestureDetector(
                        onTap: () => setState(() => _isDarkMode = !_isDarkMode),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: Icon(
                            _isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                            color: _isDarkMode ? const Color(0xFFFCD116) : Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Language Switch Pill (EN | FR)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEn = true;
                                  AppLocalization().setLanguage('en');
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _isEn ? const Color(0xFF006A4E) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  'EN',
                                  style: TextStyle(
                                    color: _isEn ? Colors.white : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEn = false;
                                  AppLocalization().setLanguage('fr');
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: !_isEn ? const Color(0xFF006A4E) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  'FR',
                                  style: TextStyle(
                                    color: !_isEn ? Colors.white : Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Account Dropdown Pill Button (Green button with dropdown)
                      PopupMenuButton<String>(
                        tooltip: _isEn ? 'Account Menu' : 'Menu Compte',
                        offset: const Offset(0, 48),
                        elevation: 8,
                        color: _card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: _border),
                        ),
                        onSelected: (val) async {
                          if (val == 'profile') {
                            _showModifyProfileDialog();
                          } else if (val == 'logout') {
                            await AuthService.logout();
                            if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline_rounded, color: _green, size: 18),
                                const SizedBox(width: 10),
                                Text(_isEn ? 'Profile' : 'Profil',
                                    style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(height: 1),
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                const Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 18),
                                const SizedBox(width: 10),
                                Text(_isEn ? 'Logout' : 'Déconnexion',
                                    style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF006A4E),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF006A4E).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                _isEn ? 'Account' : 'Compte',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, const Color(0xFF009966)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEn ? 'Welcome,' : 'Bienvenue,',
                            style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        Text(_currentUser.fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(_isEn ? 'Student' : 'Élève',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Interactive Slide Bar (Tabs) ───────────────────────────
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: _green.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                labelColor: Colors.white,
                unselectedLabelColor: _sub,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_document, size: 18),
                        const SizedBox(width: 8),
                        Text(_isEn ? 'Take Exam' : 'Passer l\'Examen'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bar_chart_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(_isEn ? 'My Results' : 'Mes Résultats'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Slide Bar Content Area ─────────────────────────────────
            SizedBox(
              height: 440,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Slide 1: Take Exam Card
                  _DashCard(
                    card: _card,
                    border: _border,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.quiz_rounded, color: _accent, size: 48),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _isEn ? 'VARK Learning Style Questionnaire' : 'Questionnaire de Style d\'Apprentissage VARK',
                            style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _isEn ? 'Official 10-Question VARK Test (Duration: 15 mins).\nDiscover if you are Visual, Auditory, Read/Write, or Kinesthetic.'
                                  : 'Test officiel VARK en 10 questions (Durée : 15 mins).\nDécouvrez si vous êtes Visuel, Auditif, Lecture/Écriture ou Kinesthésique.',
                            style: TextStyle(color: _sub, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: _startAssessment,
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            hasResult
                                ? (_isEn ? 'Retake VARK Assessment' : 'Repasser l\'Évaluation VARK')
                                : (_isEn ? 'Start Assessment Now' : 'Commencer l\'Évaluation'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Slide 2: Results Card
                  _DashCard(
                    card: _card,
                    border: _border,
                    child: _loadingResult
                        ? const Center(child: CircularProgressIndicator())
                        : hasResult
                            ? _buildResultDetails()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _sub.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.hourglass_empty_rounded, color: _sub, size: 48),
                                  ),
                                  const SizedBox(height: 16),
                                  Center(
                                    child: Text(
                                      _isEn ? 'No Assessment Completed Yet' : 'Aucune Évaluation Complétée',
                                      style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      _isEn ? 'Click "Take Exam" tab above to complete your VARK test.'
                                            : 'Cliquez sur l\'onglet "Passer l\'Examen" ci-dessus pour compléter votre test VARK.',
                                      style: TextStyle(color: _sub, fontSize: 13),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
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

  Widget _buildResultDetails() {
    final style = _resultData!['learning_style'] ?? 'VARK';
    final scores = _resultData!['scores'] as Map<String, dynamic>? ?? {};
    final summary = _isEn ? _resultData!['summary_en'] : _resultData!['summary_fr'];
    final completedAt = _resultData!['completed_at']?.toString().split(' ')[0] ?? '';

    // Pick icon and color for dominant style
    final IconData styleIcon = style.contains('Visual')
        ? Icons.visibility_outlined
        : style.contains('Auditory')
            ? Icons.hearing_outlined
            : style.contains('Kinesthetic')
                ? Icons.sports_handball_outlined
                : Icons.menu_book_outlined;

    // Use primary brand green for clean, unified 2-color palette
    final Color styleColor = _green;

    // Build individual recommendation bullets
    final List<String> recs = [];
    if (summary != null && summary.isNotEmpty) {
      for (final String l in summary.split('\n')) {
        if (l.trim().isNotEmpty) {
          recs.add(l.trim());
        }
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          // ── Hero Banner: Dominant Learning Style ──────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_green, _green.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: _green.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(styleIcon, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEn ? 'Your Learning Style' : 'Votre Style d\'Apprentissage',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        style,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.2),
                      ),
                      if (completedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: Colors.white60, size: 11),
                            const SizedBox(width: 4),
                            Text(completedAt, style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── VARK Score Breakdown ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
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
                    Icon(Icons.bar_chart_rounded, color: _green, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _isEn ? 'VARK Score Breakdown' : 'Résultats VARK',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _scoreBar(_isEn ? 'Visual' : 'Visuel', Icons.visibility_outlined, (scores['visual'] ?? 0).toDouble(), _green),
                const SizedBox(height: 14),
                _scoreBar(_isEn ? 'Auditory' : 'Auditif', Icons.hearing_outlined, (scores['auditory'] ?? 0).toDouble(), _green),
                const SizedBox(height: 14),
                _scoreBar(_isEn ? 'Kinesthetic' : 'Kinesthésique', Icons.sports_handball_outlined, (scores['kinesthetic'] ?? 0).toDouble(), _green),
                const SizedBox(height: 14),
                _scoreBar(_isEn ? 'Read / Write' : 'Lecture / Écriture', Icons.menu_book_outlined, (scores['read_write'] ?? 0).toDouble(), _green),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── AI Study Recommendations ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
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
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.psychology_outlined, color: _accent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEn ? 'AI Study Recommendations' : 'Recommandations d\'Étude IA',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...recs.map((rec) {
                  final cleaned = rec.replaceFirst(RegExp(r'^[•\-]\s*'), '').trim();
                  if (cleaned.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cleaned,
                            style: TextStyle(color: _sub, fontSize: 13, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Download PDF Button ───────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: _green.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                OfflineAssessmentService.downloadPdfReport(
                  user: widget.user,
                  resultData: _resultData!,
                  isEn: _isEn,
                );
              },
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
              label: Text(
                _isEn ? 'Download PDF Report' : 'Télécharger le Rapport PDF',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBar(String label, IconData icon, double pct, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  Text('${pct.toInt()}%', style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashCard extends StatelessWidget {
  final Color card;
  final Color border;
  final Widget child;
  const _DashCard({required this.card, required this.border, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ),
    child: child,
  );
}
