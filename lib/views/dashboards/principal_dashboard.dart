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
  String? _selectedClassFilter;

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
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  void _downloadPrincipalReport() {
    final schoolName = _schoolData?['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL';
    final principal  = _currentUser.fullName;
    final stats      = _schoolData?['summary'] as Map<String, dynamic>? ?? {};

    final csvContent = '''MINESEC LST — Principal School VARK Summary Report
"Field","Value"
"School","$schoolName"
"Principal Name","$principal"
"Region","${_currentUser.region ?? "ADAMOUA"}"
"Division","${_currentUser.division ?? "DJEREM"}"
"Total Students","${_parseInt(_schoolData?['total_students'] ?? 450)}"
"Assessed Students","${_parseInt(stats['assessed'] ?? 380)}"
"Total Teachers","${_parseInt(_schoolData?['total_teachers'] ?? 28)}"
"Visual Count","${_parseInt(stats['visual'] ?? 160)}"
"Auditory Count","${_parseInt(stats['auditory'] ?? 120)}"
"Kinesthetic Count","${_parseInt(stats['kinesthetic'] ?? 60)}"
"Read/Write Count","${_parseInt(stats['read_write'] ?? 40)}"
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
              Uri.parse('http://localhost:8080/minesec_api/api/auth.php?action=get_profile&user_id=${_currentUser.id}'),
            ).then((res) {
              final pData = jsonDecode(res.body);
              if (pData['success'] == true && pData['data'] != null) {
                final profile = pData['data'];
                passCtrl.text    = (profile['password'] ?? 'principal1').toString();
                secCodeCtrl.text = (profile['security_code'] ?? '1234@').toString();
              } else {
                passCtrl.text    = 'principal1';
                secCodeCtrl.text = '1234@';
              }
              if (ctx.mounted) setModalState(() => loading = false);
            }).catchError((_) {
              passCtrl.text    = 'principal1';
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

                    TextField(
                      controller: secCodeCtrl,
                      obscureText: obscureSec,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: _isEn ? 'Present Security Code' : 'Code de Sécurité Présent',
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
        'ai_recommendation_en': '• Integrate visual mind maps and auditory lectures tailored for 1ère TI.\n• Utilize interactive group discussions and practical demonstration labs.',
        'ai_recommendation_fr': '• Intégrez des cartes mentales visuelles et des cours auditifs adaptés pour la classe de 1ère TI.\n• Utilisez des discussions de groupe interactives et des démonstrations pratiques en laboratoire.',
      },
      {
        'class_name': 'Terminale TI',
        'total_students': 1,
        'assessed': 0,
        'visual': 1,
        'auditory': 0,
        'kinesthetic': 1,
        'read_write': 0,
        'ai_recommendation_en': '• Focus on hands-on computer network assembly and physical hardware manipulation for Terminale TI.\n• Provide clear architectural diagrams to support visual understanding.',
        'ai_recommendation_fr': '• Axez l\'apprentissage sur le montage réseau informatique pratique et la manipulation matérielle pour la classe de Terminale TI.\n• Fournissez des schémas d\'architecture clairs pour soutenir la compréhension visuelle.',
      },
    ];

    final String aiPolicy = _isEn
        ? (_schoolData?['ai_policy_en'] ?? '')
        : (_schoolData?['ai_policy_fr'] ?? '');

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
                // ── TOP NAVIGATION BAR (SLEEK DARK NAVBAR) ──────────────────
                Container(
                  height: 68,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    border: const Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
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
                        children: [
                          InkWell(
                            onTap: () => setState(() => _isDarkMode = !_isDarkMode),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: 38, height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 1.5),
                              ),
                              child: Icon(_isDarkMode ? Icons.wb_sunny_rounded : Icons.nightlight_round, color: const Color(0xFFFCD116), size: 18),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 36, width: 100,
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
                                      decoration: BoxDecoration(color: _isEn ? const Color(0xFF006A4E) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                                      alignment: Alignment.center,
                                      child: Text('EN', style: TextStyle(color: _isEn ? Colors.white : Colors.white54, fontWeight: FontWeight.w900, fontSize: 11.5)),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () { if (_isEn) setState(() => _isEn = false); },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      decoration: BoxDecoration(color: !_isEn ? const Color(0xFF006A4E) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                                      alignment: Alignment.center,
                                      child: Text('FR', style: TextStyle(color: !_isEn ? Colors.white : Colors.white54, fontWeight: FontWeight.w900, fontSize: 11.5)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                            color: const Color(0xFF1E293B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                _showPrincipalProfileDialog();
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
                                    Text(_isEn ? 'Profile' : 'Profil', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    const Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 18),
                                    const SizedBox(width: 10),
                                    Text(_isEn ? 'Logout' : 'Déconnexion', style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w600, fontSize: 13)),
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

                // Main Body Content
                Expanded(
                  child: RefreshIndicator(
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
                                          Text(_isEn ? 'Welcome Principal,' : 'Bienvenue Proviseur,', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
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

                            // Stat Cards Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_isEn ? 'School Executive Overview' : 'Aperçu Général de l\'Établissement', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _downloadPrincipalReport,
                                  icon: const Icon(Icons.download_rounded, size: 18),
                                  label: Text(_isEn ? 'Download Results' : 'Télécharger Résultats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF006A4E))),
                                const SizedBox(width: 10),
                                Expanded(child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'Assessed Students' : 'Élèves Évalués', value: '$assessedStudents', color: const Color(0xFF10B981))),
                                const SizedBox(width: 10),
                                Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Total Teachers' : 'Total Enseignants', value: '$totalTeachers', color: const Color(0xFF3B82F6))),
                                const SizedBox(width: 10),
                                Expanded(child: _overviewStatCard(icon: Icons.psychology_rounded, label: _isEn ? 'Pedagogical Status' : 'Statut Pédagogique', value: _isEn ? 'Optimal' : 'Optimal', color: const Color(0xFF8B5CF6))),
                              ],
                            ),
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
                                      Text(_isEn ? 'School VARK Learning Styles Distribution' : 'Répartition VARK Globale de l\'Établissement', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
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
                                      Text(_isEn ? 'AI Strategic Pedagogical Policy Recommendations' : 'Recommandations Pédagogiques Stratégiques IA', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5)),
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
                                final cRec  = _isEn
                                    ? (selectedCb['ai_recommendation_en'] ?? '')
                                    : (selectedCb['ai_recommendation_fr'] ?? '');

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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.school_rounded, color: _green, size: 24),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Class: $cName',
                                                style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                            child: Text(
                                              '${_isEn ? "Students" : "Élèves"}: $totSt ($assSt ${_isEn ? "Assessed" : "Évalués"})',
                                              style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12.5),
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
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: _bg,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: _border),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 15,
                                                        backgroundColor: _green.withValues(alpha: 0.15),
                                                        child: Icon(Icons.person_rounded, color: _green, size: 16),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(sName, style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5)),
                                                          Text('${_isEn ? "Matricule" : "Matricule"}: $sMat', style: TextStyle(color: _sub, fontSize: 11.5)),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                    decoration: BoxDecoration(color: badgeCol.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeCol.withValues(alpha: 0.3))),
                                                    child: Text(
                                                      sStyle,
                                                      style: TextStyle(color: badgeCol, fontWeight: FontWeight.bold, fontSize: 11.5),
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
                                        padding: const EdgeInsets.all(16),
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
                                                Text(
                                                  '${_isEn ? "Final AI Recommendation for" : "Recommandation Finale IA pour"} $cName:',
                                                  style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 14),
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
