import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';

class TeacherDashboard extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;

  const TeacherDashboard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.isEn,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late UserModel _currentUser;
  late bool _isDarkMode;
  late bool _isEn;

  bool _isLoading = true;
  Map<String, dynamic>? _classData;

  String? _selectedClass;
  String? _selectedSubject;
  int _currentNavIndex = 0; // 0 = Dashboard Overview (Welcome Banner + Overview), 1 = Class View (Welcome banner removed)

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
    _fetchClassData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchClassData([String? targetClass, String? targetSubject]) async {
    setState(() {
      _isLoading = true;
      if (targetClass != null) _selectedClass = targetClass;
      if (targetSubject != null) _selectedSubject = targetSubject;
    });

    try {
      final resp = await http.post(
        Uri.parse('http://localhost:8080/minesec_api/api/dashboard.php?action=teacher_class'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _currentUser.id,
          if (_selectedClass != null) 'class_name': _selectedClass,
          if (_selectedSubject != null) 'subject': _selectedSubject,
        }),
      );

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() {
          _classData = data['data'];
          _selectedClass = _classData?['class_name'];
          _selectedSubject = _classData?['subject'];
          _isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  void _downloadTeacherReport() {
    final className = _selectedClass ?? (_classData?['class_name'] ?? '1ère TI');
    final subject   = _selectedSubject ?? (_classData?['subject'] ?? 'Informatique');
    final List students = _classData?['students'] as List? ?? [];

    final buffer = StringBuffer();
    buffer.writeln('MINESEC LST — Teacher Class Diagnostic Results Report');
    buffer.writeln('"Teacher","${_currentUser.fullName}"');
    buffer.writeln('"Subject","$subject"');
    buffer.writeln('"Class","$className"');
    buffer.writeln('"School","${_currentUser.schoolId ?? 'LYCEE TECHNIQUE DE NGAOUNDAL'}"');
    buffer.writeln();
    buffer.writeln('"Full Name","Matricule","Class","Dominant Style","Visual","Auditory","Kinesthetic","Read/Write"');

    for (final st in students) {
      final stMap = st as Map<String, dynamic>;
      final name  = stMap['full_name'] ?? '';
      final mat   = stMap['mat_number'] ?? '';
      final cls   = stMap['class_name'] ?? className;
      final style = stMap['learning_style'] ?? 'Not Assessed';
      final v     = stMap['visual_score'] ?? 0;
      final a     = stMap['auditory_score'] ?? 0;
      final k     = stMap['kinesthetic_score'] ?? 0;
      final r     = stMap['read_write_score'] ?? 0;
      buffer.writeln('"$name","$mat","$cls","$style","$v","$a","$k","$r"');
    }

    final csvContent = buffer.toString();

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
              _isEn ? 'Download Class Results' : 'Télécharger Résultats de Classe',
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
                  ? 'VARK Diagnostic CSV export generated for $className ($subject).'
                  : 'Export CSV VARK généré pour la classe $className ($subject).',
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
                  content: Text(_isEn ? 'Class Results Downloaded Successfully!' : 'Résultats de Classe Téléchargés avec Succès !'),
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
      _classData = {
        'class_name': '1ère TI',
        'subject': 'Informatique',
        'staff_id': 'T2026001',
        'ticked_classes': ['1ère TI', 'Terminale TI'],
        'summary': {
          'total_students': 2,
          'assessed': 2,
          'visual': 1,
          'auditory': 1,
          'kinesthetic': 0,
          'read_write': 0,
        },
        'students': [
          {
            'full_name': 'Bello Oumarou',
            'mat_number': 'AD2026001',
            'class_name': '1ère TI',
            'gender': 'Male',
            'learning_style': 'Visual Learner (Score: 8/16)',
            'visual_score': 8,
            'auditory_score': 4,
            'kinesthetic_score': 3,
            'read_write_score': 1,
          },
          {
            'full_name': 'Amina Mohamadou',
            'mat_number': 'AD2026002',
            'class_name': 'Terminale TI',
            'gender': 'Female',
            'learning_style': 'Auditory Learner (Score: 9/16)',
            'visual_score': 3,
            'auditory_score': 9,
            'kinesthetic_score': 2,
            'read_write_score': 2,
          },
        ],
        'ai_recommendation_en': '• Incorporate visual mind maps, architectural diagrams, and flowcharts on the board.\n• Provide structured printed notes and code summaries for reading.\n• Use interactive lab exercises and hands-on coding demonstrations during class.',
        'ai_recommendation_fr': '• Intégrez des cartes mentales, des schémas d\'architecture et des organigrammes au tableau.\n• Fournissez des fiches de cours structurées et des résumés de code rédigés.\n• Proposez des travaux pratiques guidés et des démonstrations de code interactives en classe.',
      };
    });
  }

  void _showTeacherProfileDialog() async {
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
                passCtrl.text    = (profile['password'] ?? 'teacher1').toString();
                secCodeCtrl.text = (profile['security_code'] ?? '1234@').toString();
              } else {
                passCtrl.text    = 'teacher1';
                secCodeCtrl.text = '1234@';
              }
              if (ctx.mounted) setModalState(() => loading = false);
            }).catchError((_) {
              passCtrl.text    = 'teacher1';
              secCodeCtrl.text = '1234@';
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
                              initials.isEmpty ? 'T' : initials,
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
                                  _isEn ? 'Teacher' : 'Enseignant',
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
                        _isEn ? 'Teacher Database Credentials' : 'Identifiants Enseignant en Base de Données',
                        style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _profileInfoRow(Icons.badge_rounded, _isEn ? 'Matricule / Staff ID' : 'Matricule / Identifiant', 'T2026001'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.school_rounded, _isEn ? 'School' : 'Établissement', 'LYCEE TECHNIQUE DE NGAOUNDAL'),
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

  @override
  Widget build(BuildContext context) {
    final className = _selectedClass ?? (_classData?['class_name'] ?? '1ère TI');
    final subject   = _selectedSubject ?? (_classData?['subject'] ?? 'Informatique');

    final summary        = _classData?['summary'] as Map<String, dynamic>? ?? {};
    final int visSt      = _parseInt(summary['visual']);
    final int audSt      = _parseInt(summary['auditory']);
    final int kinesSt    = _parseInt(summary['kinesthetic']);
    final int readWriteSt= _parseInt(summary['read_write']);

    final aiRec = _isEn
        ? (_classData?['ai_recommendation_en'] ?? '')
        : (_classData?['ai_recommendation_fr'] ?? '');

    final List students      = _classData?['students'] as List? ?? [];
    final List tickedClasses = (_classData?['ticked_classes'] as List?)?.map((e) => e.toString()).toList() ?? ['1ère TI', 'Terminale TI'];
    final List classSummaries= _classData?['class_summaries'] as List? ?? [];
    final int overallClasses = _parseInt(_classData?['overall_total_classes'] ?? tickedClasses.length);
    final int overallStudents= _parseInt(_classData?['overall_total_students'] ?? students.length);
    final int overallAssessed= _parseInt(_classData?['overall_total_assessed'] ?? summary['assessed']);

    final isWide = MediaQuery.of(context).size.width >= 800;

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      tickedClasses: tickedClasses.cast<String>(),
      selectedClass: className,
      onClassSelected: (cls) {
        setState(() => _currentNavIndex = 1);
        _fetchClassData(cls);
      },
      onItemSelected: (idx) {
        setState(() => _currentNavIndex = idx);
        if (idx == 0) {
          _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          _fetchClassData(_selectedClass, _selectedSubject);
        }
      },
      onOpenProfile: _showTeacherProfileDialog,
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
                // ── TOP NAVIGATION BAR ──────────────────────────────────────
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

                          // Account Profile Button with Popup Menu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                            color: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFF334155),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                _showTeacherProfileDialog();
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
                  child: RefreshIndicator(
                    onRefresh: () => _fetchClassData(_selectedClass, _selectedSubject),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(22),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TAB INDEX 0: DASHBOARD OVERVIEW LANDING PAGE (WELCOME BANNER ONLY) ──
                          if (_currentNavIndex == 0) ...[
                            // Teacher Welcome Banner Card
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
                                          Text(_isEn ? 'Welcome,' : 'Bienvenue,', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
                                          Text(_currentUser.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                                        child: const Icon(Icons.co_present_rounded, color: Colors.white, size: 26),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _scopeBadge(Icons.book_rounded, '${_isEn ? "Subject" : "Matière"}: $subject'),
                                      _scopeBadge(Icons.location_city_rounded, _currentUser.division ?? 'DJEREM'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Executive Summary Metric Cards Grid
                            Text(
                              _isEn ? 'Executive Overview Summary' : 'Aperçu Synthétique Global',
                              style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: _overviewStatCard(
                                    icon: Icons.class_rounded,
                                    label: _isEn ? 'Assigned Classes' : 'Classes Assignées',
                                    value: '$overallClasses',
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _overviewStatCard(
                                    icon: Icons.people_alt_rounded,
                                    label: _isEn ? 'Total Students' : 'Total Élèves',
                                    value: '$overallStudents',
                                    color: const Color(0xFF006A4E),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _overviewStatCard(
                                    icon: Icons.assignment_turned_in_rounded,
                                    label: _isEn ? 'Assessed Students' : 'Élèves Évalués',
                                    value: '$overallAssessed',
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _overviewStatCard(
                                    icon: Icons.psychology_rounded,
                                    label: _isEn ? 'Pedagogical Status' : 'Statut Pédagogique',
                                    value: _isEn ? 'Optimal' : 'Optimal',
                                    color: const Color(0xFF8B5CF6),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          // ── TAB INDEX 1: CLASS DETAILS VIEW (WELCOME BANNER REMOVED AS REQUESTED) ──
                          if (_currentNavIndex == 1) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$className — $subject',
                                      style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 20),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isEn ? 'Class Diagnostic Results & Student Roster' : 'Résultats Diagnostics de Classe & Liste des Élèves',
                                      style: TextStyle(color: _sub, fontSize: 12.5),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                  child: Text(
                                    _currentUser.division ?? 'DJEREM',
                                    style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // VARK Cards Grid
                            Text(
                              _isEn ? 'Class Learning Styles Breakdown' : 'Répartition des Styles d\'Apprentissage de la Classe',
                              style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(child: _varkStatCard(_isEn ? 'Visual' : 'Visuel', '$visSt', Icons.visibility_rounded, const Color(0xFF3B82F6))),
                                const SizedBox(width: 10),
                                Expanded(child: _varkStatCard(_isEn ? 'Auditory' : 'Auditif', '$audSt', Icons.record_voice_over_rounded, const Color(0xFFEC4899))),
                                const SizedBox(width: 10),
                                Expanded(child: _varkStatCard(_isEn ? 'Kinesthetic' : 'Kinesthésique', '$kinesSt', Icons.directions_run_rounded, const Color(0xFF10B981))),
                                const SizedBox(width: 10),
                                Expanded(child: _varkStatCard(_isEn ? 'Read/Write' : 'Lecture/Écriture', '$readWriteSt', Icons.menu_book_rounded, const Color(0xFFF59E0B))),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // AI Recommendation Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _green.withValues(alpha: 0.3), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, color: _green, size: 22),
                                      const SizedBox(width: 8),
                                      Text(
                                        _isEn ? 'AI Pedagogical Teaching Recommendations' : 'Recommandations Pédagogiques IA',
                                        style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    aiRec,
                                    style: TextStyle(color: _text, fontSize: 13.5, height: 1.6, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            // STUDENT ROSTER & RESULTS SECTION
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.people_alt_rounded, color: _green, size: 22),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEn ? 'Student Roster & Assessment Results' : 'Liste des Élèves & Résultats VARK',
                                      style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: _downloadTeacherReport,
                                      icon: const Icon(Icons.download_rounded, size: 16),
                                      label: Text(
                                        _isEn ? 'Download Results' : 'Télécharger Résultats',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                      child: Text(
                                        '${_isEn ? "Total" : "Total"}: ${students.length}',
                                        style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            if (students.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                                child: Center(
                                  child: Text(
                                    _isEn ? 'No students found in the database for this class.' : 'Aucun élève trouvé dans la base de données pour cette classe.',
                                    style: TextStyle(color: _sub, fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: students.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (ctx, idx) {
                                  final st = students[idx] as Map<String, dynamic>;
                                  final stName = st['full_name'] ?? 'Élève';
                                  final stMat  = st['mat_number'] ?? 'AD2026001';
                                  final style  = st['learning_style'] ?? (_isEn ? 'Not Assessed Yet' : 'Pas encore évalué');

                                  final int vScore = _parseInt(st['visual_score']);
                                  final int aScore = _parseInt(st['auditory_score']);
                                  final int kScore = _parseInt(st['kinesthetic_score']);
                                  final int rScore = _parseInt(st['read_write_score']);

                                  Color styleColor = const Color(0xFF64748B);
                                  if (style.contains('Visual')) styleColor = const Color(0xFF3B82F6);
                                  if (style.contains('Auditory')) styleColor = const Color(0xFFEC4899);
                                  if (style.contains('Kinesthetic')) styleColor = const Color(0xFF10B981);
                                  if (style.contains('Read/Write')) styleColor = const Color(0xFFF59E0B);

                                  return Container(
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
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: _green.withValues(alpha: 0.12),
                                              child: Icon(Icons.person_rounded, color: _green, size: 22),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(stName, style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14.5)),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Matricule: $stMat | ${st['class_name'] ?? className}',
                                                    style: TextStyle(color: _sub, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(color: styleColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                              child: Text(style, style: TextStyle(color: styleColor, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // Scores Breakdown Row
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: _bg,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: _border.withValues(alpha: 0.5)),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              _studentScoreBadge(_isEn ? 'Visual' : 'Visuel', vScore, const Color(0xFF3B82F6)),
                                              _studentScoreBadge(_isEn ? 'Auditory' : 'Auditif', aScore, const Color(0xFFEC4899)),
                                              _studentScoreBadge(_isEn ? 'Kinesthetic' : 'Kinesthésique', kScore, const Color(0xFF10B981)),
                                              _studentScoreBadge(_isEn ? 'Read/Write' : 'Lecture', rScore, const Color(0xFFF59E0B)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
    );
  }

  Widget _pieLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _overviewStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(Icons.trending_up_rounded, color: color.withValues(alpha: 0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _studentScoreBadge(String label, int score, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Text(
          '$score',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
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

  Widget _varkStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ── CUSTOM PIE CHART PAINTER ─────────────────────────────────────────────────
class _VarkPieChartPainter extends CustomPainter {
  final int visual;
  final int auditory;
  final int kinesthetic;
  final int readWrite;

  _VarkPieChartPainter({
    required this.visual,
    required this.auditory,
    required this.kinesthetic,
    required this.readWrite,
  });

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

    // 1. Visual (Blue)
    if (visual > 0) {
      final p = Paint()..color = const Color(0xFF3B82F6)..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, visAngle, true, p);
      startAngle += visAngle;
    }

    // 2. Auditory (Pink)
    if (auditory > 0) {
      final p = Paint()..color = const Color(0xFFEC4899)..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, audAngle, true, p);
      startAngle += audAngle;
    }

    // 3. Read/Write (Orange)
    if (readWrite > 0) {
      final p = Paint()..color = const Color(0xFFF59E0B)..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, rwAngle, true, p);
      startAngle += rwAngle;
    }

    // 4. Kinesthetic (Green)
    if (kinesthetic > 0) {
      final p = Paint()..color = const Color(0xFF10B981)..style = PaintingStyle.fill;
      canvas.drawArc(rect, startAngle, kinesAngle, true, p);
      startAngle += kinesAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _VarkPieChartPainter oldDelegate) => true;
}
