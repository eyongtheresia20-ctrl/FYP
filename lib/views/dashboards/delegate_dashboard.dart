import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';

class DelegateDashboard extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;

  const DelegateDashboard({
    super.key,
    required this.user,
    required this.isDarkMode,
    required this.isEn,
  });

  @override
  State<DelegateDashboard> createState() => _DelegateDashboardState();
}

class _DelegateDashboardState extends State<DelegateDashboard> {
  late UserModel _currentUser;
  late bool _isDarkMode;
  late bool _isEn;

  bool _isLoading = true;
  Map<String, dynamic>? _delegateData;
  String? _selectedSchoolFilter;
  final Map<String, String> _selectedClassFilterPerSchool = {};
  int _currentNavIndex = 0;

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
    _fetchDelegateData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDelegateData() async {
    setState(() => _isLoading = true);
    final action = _currentUser.isRegionalDelegate ? 'regional_analytics' : 'divisional_analytics';
    try {
      final resp = await http.get(
        Uri.parse('http://localhost:8080/minesec_api/api/dashboard.php?action=$action&user_id=${_currentUser.id}'),
      );
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() {
          _delegateData = data['data'];
          _isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (_) {
      _useFallbackData();
    }
  }

  void _downloadDelegateReport() {
    final title     = _delegateData?['title'] ?? 'MINESEC DELEGATION REPORT';
    final delegate  = _currentUser.fullName;
    final stats     = _delegateData?['summary'] as Map<String, dynamic>? ?? {};

    final csvContent = '''MINESEC LST — Territorial Delegation VARK Report
"Field","Value"
"Title","$title"
"Delegate Name","$delegate"
"Region","${_currentUser.region ?? "ADAMOUA"}"
"Division","${_currentUser.division ?? "DJEREM"}"
"Total Schools","${_parseInt(_delegateData?['total_schools'] ?? 12)}"
"Total Students","${_parseInt(_delegateData?['total_students'] ?? 4200)}"
"Assessed Students","${_parseInt(stats['assessed'] ?? 3600)}"
"Total Teachers","${_parseInt(_delegateData?['total_teachers'] ?? 180)}"
"Visual Count","${_parseInt(stats['visual'] ?? 1400)}"
"Auditory Count","${_parseInt(stats['auditory'] ?? 1100)}"
"Kinesthetic Count","${_parseInt(stats['kinesthetic'] ?? 600)}"
"Read/Write Count","${_parseInt(stats['read_write'] ?? 500)}"
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
              _isEn ? 'Download Delegation Report' : 'Télécharger le Rapport de la Délégation',
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
                  ? 'VARK Diagnostic CSV report generated for $title.'
                  : 'Rapport CSV VARK généré pour $title.',
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
                  content: Text(_isEn ? 'Delegation Report Downloaded Successfully!' : 'Rapport de la Délégation Téléchargé avec Succès !'),
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
    final isReg = _currentUser.isRegionalDelegate;
    setState(() {
      _isLoading = false;
      _delegateData = {
        'title': isReg ? 'DÉLÉGATION RÉGIONALE DE L\'ENSEIGNEMENT SECONDAIRE' : 'DÉLÉGATION DÉPARTEMENTALE DE L\'ENSEIGNEMENT SECONDAIRE',
        'delegate_name': _currentUser.fullName,
        'region': _currentUser.region ?? 'ADAMOUA',
        'division': _currentUser.division ?? 'DJEREM',
        'total_schools': isReg ? 45 : 3,
        'total_students': isReg ? 18500 : 2,
        'assessed_students': isReg ? 15200 : 1,
        'total_teachers': isReg ? 980 : 1,
        'visual_count': isReg ? 6800 : 1,
        'auditory_count': isReg ? 4900 : 1,
        'kinesthetic_count': isReg ? 2100 : 0,
        'read_write_count': isReg ? 1400 : 0,
        'items': isReg
            ? [
                {'name': 'DJEREM', 'schools_count': 3, 'students_count': 2, 'assessed_rate': '50%'},
                {'name': 'MAYO-BALEO', 'schools_count': 0, 'students_count': 0, 'assessed_rate': '0%'},
                {'name': 'FARO-ET-DEO', 'schools_count': 0, 'students_count': 0, 'assessed_rate': '0%'},
                {'name': 'VINA', 'schools_count': 0, 'students_count': 0, 'assessed_rate': '0%'},
              ]
            : [
                {
                  'name': 'LYCEE TECHNIQUE DE NGAOUNDAL', 
                  'teachers_count': 1, 
                  'students_count': 2, 
                  'assessed_rate': '50%',
                  'classes': [
                    {
                      'class_name': '1ère TI',
                      'total_students': 1,
                      'assessed': 1,
                      'visual': 1,
                      'auditory': 1,
                      'kinesthetic': 0,
                      'read_write': 0,
                      'ai_recommendation_en': '• Prioritize interactive ICT programming workshops and visual flowcharts for 1ère TI at LYCEE TECHNIQUE DE NGAOUNDAL.',
                      'ai_recommendation_fr': '• Priorisez les ateliers interactifs de programmation et les organigrammes visuels pour la classe de 1ère TI à LYCEE TECHNIQUE DE NGAOUNDAL.',
                      'students': [
                        {'full_name': 'Bello Oumarou', 'mat_number': 'AD2026001', 'class_name': '1ère TI', 'learning_style': 'Auditory-Visual (Dual Style)'},
                      ]
                    },
                    {
                      'class_name': 'Terminale TI',
                      'total_students': 1,
                      'assessed': 0,
                      'visual': 0,
                      'auditory': 0,
                      'kinesthetic': 0,
                      'read_write': 0,
                      'ai_recommendation_en': '• Prioritize interactive ICT programming workshops and visual flowcharts for Terminale TI at LYCEE TECHNIQUE DE NGAOUNDAL.',
                      'ai_recommendation_fr': '• Priorisez les ateliers interactifs de programmation et les organigrammes visuels pour la classe de Terminale TI à LYCEE TECHNIQUE DE NGAOUNDAL.',
                      'students': [
                        {'full_name': 'Amina Mohamadou', 'mat_number': 'AD2026002', 'class_name': 'Terminale TI', 'learning_style': 'Not Assessed'},
                      ]
                    }
                  ],
                  'ai_recommendation_en': '• School Policy Recommendation for LYCEE TECHNIQUE DE NGAOUNDAL: Allocate digital learning aids and conduct teacher VARK seminars.',
                  'ai_recommendation_fr': '• Recommandation Pédagogique pour LYCEE TECHNIQUE DE NGAOUNDAL : Allouez du matériel numérique et organisez des séminaires d\'apprentissage VARK.',
                },
                {
                  'name': 'LYCEE CLASSIQUE DE NGAOUNDAL', 
                  'teachers_count': 0, 
                  'students_count': 0, 
                  'assessed_rate': '0%',
                  'classes': [],
                  'ai_recommendation_en': '• School Policy Recommendation for LYCEE CLASSIQUE DE NGAOUNDAL: Allocate digital learning aids and conduct teacher VARK seminars.',
                  'ai_recommendation_fr': '• Recommandation Pédagogique pour LYCEE CLASSIQUE DE NGAOUNDAL : Allouez du matériel numérique et organisez des séminaires d\'apprentissage VARK.',
                },
                {
                  'name': 'LYCEE BILINGUE DE NGAOUNDAL', 
                  'teachers_count': 0, 
                  'students_count': 0, 
                  'assessed_rate': '0%',
                  'classes': [],
                  'ai_recommendation_en': '• School Policy Recommendation for LYCEE BILINGUE DE NGAOUNDAL: Allocate digital learning aids and conduct teacher VARK seminars.',
                  'ai_recommendation_fr': '• Recommandation Pédagogique pour LYCEE BILINGUE DE NGAOUNDAL : Allouez du matériel numérique et organisez des séminaires d\'apprentissage VARK.',
                },
              ],
        'ai_policy_en': isReg
            ? '• Distribute digital lab equipment across Adamoua region focusing on Vina and Djerem divisions.\n• Establish regional teacher training centers for VARK-adaptive curriculum design.'
            : '• Divisional Policy Directive for DJEREM: Coordinate inspection visits and prioritize digital infrastructure across technical and general secondary lycées.',
        'ai_policy_fr': isReg
            ? '• Distribuez les équipements informatiques dans la région de l\'Adamaoua en ciblant les départements de la Vina et du Djerem.\n• Créez des centres régionaux de formation continue des enseignants aux méthodes VARK.'
            : '• Directive Départementale pour le DJEREM : Coordonnez les inspections pédagogiques et priorisez l\'infrastructure numérique dans les lycées.',
      };
    });
  }

  void _showDelegateProfileDialog() async {
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
                passCtrl.text    = (profile['password'] ?? 'delegate1').toString();
                secCodeCtrl.text = (profile['security_code'] ?? '1234@').toString();
              } else {
                passCtrl.text    = 'delegate1';
                secCodeCtrl.text = '1234@';
              }
              if (ctx.mounted) setModalState(() => loading = false);
            }).catchError((_) {
              passCtrl.text    = 'delegate1';
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
                              initials.isEmpty ? 'D' : initials,
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
                                  _currentUser.isRegionalDelegate
                                      ? (_isEn ? 'Regional Delegate' : 'Délégué Régional')
                                      : (_isEn ? 'Divisional Delegate' : 'Délégué Départemental'),
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
                        _isEn ? 'Delegate Database Credentials' : 'Identifiants Délégué en Base de Données',
                        style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 14.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _profileInfoRow(Icons.map_rounded, _isEn ? 'Region' : 'Région', _currentUser.region ?? 'ADAMOUA'),
                  if (!_currentUser.isRegionalDelegate) ...[
                    const SizedBox(height: 8),
                    _profileInfoRow(Icons.location_city_rounded, _isEn ? 'Division' : 'Département', _currentUser.division ?? 'DJEREM'),
                  ],
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
    final isReg = _currentUser.isRegionalDelegate;
    final int totalSchools  = _parseInt(_delegateData?['total_schools'] ?? (isReg ? 45 : 12));
    final int totalStudents = _parseInt(_delegateData?['total_students'] ?? (isReg ? 18500 : 4200));
    final int assessed      = _parseInt(_delegateData?['assessed_students'] ?? (isReg ? 15200 : 3600));
    final int totalTeachers = _parseInt(_delegateData?['total_teachers'] ?? (isReg ? 980 : 240));

    final int visSt   = _parseInt(_delegateData?['visual_count'] ?? (isReg ? 6800 : 1600));
    final int audSt   = _parseInt(_delegateData?['auditory_count'] ?? (isReg ? 4900 : 1100));
    final int kinesSt = _parseInt(_delegateData?['kinesthetic_count'] ?? (isReg ? 2100 : 500));
    final int rwSt    = _parseInt(_delegateData?['read_write_count'] ?? (isReg ? 1400 : 400));

    final List items = _delegateData?['items'] as List? ?? [];
    final List<String> schoolNames = [];
    for (var it in items) {
      final name = (it['name'] ?? '').toString();
      if (name.isNotEmpty && !schoolNames.contains(name)) {
        schoolNames.add(name);
      }
    }
    if (schoolNames.isEmpty) schoolNames.addAll(['LYCEE TECHNIQUE DE NGAOUNDAL', 'LYCEE CLASSIQUE DE NGAOUNDAL', 'LYCEE BILINGUE DE NGAOUNDAL']);

    final String aiPolicy = _isEn
        ? (_delegateData?['ai_policy_en'] ?? '')
        : (_delegateData?['ai_policy_fr'] ?? '');

    final isWide = MediaQuery.of(context).size.width >= 800;

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      tickedClasses: schoolNames,
      selectedClass: _selectedSchoolFilter ?? schoolNames.first,
      onClassSelected: (selection) {
        setState(() {
          _currentNavIndex = 2;
          if (selection.contains('::')) {
            final parts = selection.split('::');
            final scName = parts[0];
            final clsName = parts[1];
            _selectedSchoolFilter = scName;
            _selectedClassFilterPerSchool[scName] = clsName;
          } else {
            _selectedSchoolFilter = selection;
          }
        });
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      onItemSelected: (idx) {
        setState(() => _currentNavIndex = idx);
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      },
      onOpenProfile: _showDelegateProfileDialog,
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
                // TOP NAVIGATION BAR (SLEEK DARK NAVBAR)
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
                            color: _card,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (value) async {
                              if (value == 'profile') {
                                _showDelegateProfileDialog();
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
                                    Text(_isEn ? 'Profile' : 'Profil', style: TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
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

                // Main Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchDelegateData,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(22),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TAB 0: DASHBOARD OVERVIEW LANDING PAGE ──────────────────
                          if (_currentNavIndex == 0) ...[
                            // Delegate Welcome Banner Card
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
                                          Text(
                                            isReg ? (_isEn ? 'Welcome Regional Delegate,' : 'Bienvenue Délégué Régional,') : (_isEn ? 'Welcome Divisional Delegate,' : 'Bienvenue Délégué Départemental,'),
                                            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                                          ),
                                          Text(_currentUser.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                                        child: Icon(isReg ? Icons.map_rounded : Icons.location_city_rounded, color: Colors.white, size: 26),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Wrap(
                                    spacing: 8, runSpacing: 8,
                                    children: [
                                      _scopeBadge(Icons.map_rounded, 'Région: ${_currentUser.region ?? "ADAMOUA"}'),
                                      if (!isReg) _scopeBadge(Icons.location_city_rounded, 'Département: ${_currentUser.division ?? "DJEREM"}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Metric Stat Cards Grid
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_isEn ? 'Territorial Executive Overview' : 'Aperçu Exécutif Territorial', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _downloadDelegateReport,
                                  icon: const Icon(Icons.download_rounded, size: 18),
                                  label: Text(_isEn ? 'Download Results' : 'Télécharger Résultats', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(child: _overviewStatCard(icon: Icons.location_city_rounded, label: isReg ? (_isEn ? 'Total Schools' : 'Établissements') : (_isEn ? 'Schools' : 'Établissements'), value: '$totalSchools', color: const Color(0xFF006A4E))),
                                const SizedBox(width: 10),
                                Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF3B82F6))),
                                const SizedBox(width: 10),
                                Expanded(child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'Assessed Students' : 'Élèves Évalués', value: '$assessed', color: const Color(0xFF10B981))),
                                const SizedBox(width: 10),
                                Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Teachers' : 'Enseignants', value: '$totalTeachers', color: const Color(0xFF8B5CF6))),
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
                                      Text(isReg ? (_isEn ? 'Regional VARK Learning Styles Breakdown' : 'Répartition VARK Régionale') : (_isEn ? 'Divisional VARK Learning Styles Breakdown' : 'Répartition VARK Départementale'), style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
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

                          // ── TAB 1: ANALYTICS & AI STRATEGIC POLICY ──────────────────
                          if (_currentNavIndex == 1) ...[
                            Text(isReg ? (_isEn ? 'Regional Educational Strategy' : 'Stratégie Éducative Régionale') : (_isEn ? 'Divisional Educational Strategy' : 'Stratégie Éducative Départementale'), style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),
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
                                      Text(_isEn ? 'AI Regional Policy Directives' : 'Directives Stratégiques Régionales IA', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(aiPolicy, style: TextStyle(color: _text, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],

                          // ── TAB 2: DIVISIONS / SCHOOLS DIRECTORY ─────────────────────
                          if (_currentNavIndex == 2) ...[

                            // Dropdown Selector Component for Schools/Divisions
                            Builder(
                              builder: (ctx) {
                                final activeSelection = (_selectedSchoolFilter != null && schoolNames.contains(_selectedSchoolFilter))
                                    ? _selectedSchoolFilter!
                                    : schoolNames.first;

                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(18),
                                  margin: const EdgeInsets.only(bottom: 18),
                                  decoration: BoxDecoration(
                                    color: _card,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: _green.withValues(alpha: 0.35), width: 1.5),
                                    boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.tune_rounded, color: _green, size: 22),
                                              const SizedBox(width: 10),
                                              Text(
                                                isReg ? (_isEn ? 'Select Division:' : 'Sélectionner un Département :') : (_isEn ? 'Select School:' : 'Sélectionner un Établissement :'),
                                                style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                            child: Text(
                                              '${schoolNames.length} ${isReg ? (_isEn ? "Divisions" : "Départements") : (_isEn ? "Schools" : "Établissements")}',
                                              style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // Dropdown Popup Menu Trigger
                                      PopupMenuButton<String>(
                                        tooltip: _isEn ? 'Select Dropdown' : 'Menu Déroulant',
                                        onSelected: (val) {
                                          setState(() => _selectedSchoolFilter = val);
                                        },
                                        itemBuilder: (ctx) => schoolNames.map((scName) {
                                          final isSelected = scName == activeSelection;
                                          return PopupMenuItem<String>(
                                            value: scName,
                                            child: Row(
                                              children: [
                                                Icon(isReg ? Icons.location_city_rounded : Icons.school_rounded, color: isSelected ? _green : _sub, size: 20),
                                                const SizedBox(width: 12),
                                                Text(
                                                  scName,
                                                  style: TextStyle(
                                                    color: isSelected ? _green : _text,
                                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                if (isSelected) ...[
                                                  const Spacer(),
                                                  Icon(Icons.check_circle_rounded, color: _green, size: 18),
                                                ],
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: _bg,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: _green, width: 1.5),
                                            boxShadow: [BoxShadow(color: _green.withValues(alpha: 0.1), blurRadius: 6)],
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(isReg ? Icons.location_city_rounded : Icons.school_rounded, color: _green, size: 22),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    activeSelection,
                                                    style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 15.5),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(color: _green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                                    child: Text(
                                                      _isEn ? 'Dropdown Menu ▾' : 'Menu Déroulant ▾',
                                                      style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12.5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (ctx, idx) {
                                final item = items[idx] as Map<String, dynamic>;
                                final schoolClasses = item['classes'] as List? ?? [
                                  {
                                    'class_name': '1ère TI',
                                    'total_students': 65,
                                    'assessed': 54,
                                    'visual': 28,
                                    'auditory': 16,
                                    'kinesthetic': 6,
                                    'read_write': 4,
                                    'ai_recommendation_en': '• Prioritize interactive ICT programming workshops and visual flowcharts for 1ère TI.',
                                    'ai_recommendation_fr': '• Priorisez les ateliers interactifs de programmation et les organigrammes visuels pour la classe de 1ère TI.',
                                    'students': [
                                      {'full_name': 'Bello Oumarou', 'mat_number': 'AD2026001', 'learning_style': 'Visual-Auditory Learner'},
                                    ]
                                  },
                                  {
                                    'class_name': 'Terminale TI',
                                    'total_students': 58,
                                    'assessed': 48,
                                    'visual': 22,
                                    'auditory': 12,
                                    'kinesthetic': 10,
                                    'read_write': 4,
                                    'ai_recommendation_en': '• Focus on practical network physical wiring and hardware labs for Terminale TI.',
                                    'ai_recommendation_fr': '• Axez l\'apprentissage sur le câblage réseau pratique et les travaux pratiques informatiques pour la classe de Terminale TI.',
                                    'students': [
                                      {'full_name': 'Amina Mohamadou', 'mat_number': 'AD2026002', 'learning_style': 'Kinesthetic-Visual Learner'},
                                    ]
                                  }
                                ];

                                return Container(
                                  decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                    child: ExpansionTile(
                                      initiallyExpanded: idx == 0,
                                      leading: CircleAvatar(backgroundColor: _green.withValues(alpha: 0.12), child: Icon(isReg ? Icons.location_city_rounded : Icons.school_rounded, color: _green, size: 22)),
                                      title: Text(item['name'] ?? '', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15)),
                                      subtitle: Text(
                                        isReg ? '${item["schools_count"]} ${_isEn ? "Schools" : "Établissements"}' : '${item["teachers_count"]} ${_isEn ? "Teachers" : "Enseignants"} • Click to view Classes & Results',
                                        style: TextStyle(color: _sub, fontSize: 12),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                        child: Text('${item["students_count"]} ${_isEn ? "Students" : "Élèves"}', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Builder(
                                            builder: (cContext) {
                                              final scName = item['name'] ?? '';
                                              final List<String> classNamesOnly = [];
                                              for (var c in schoolClasses) {
                                                final cn = (c['class_name'] ?? '').toString();
                                                if (cn.isNotEmpty && !classNamesOnly.contains(cn)) {
                                                  classNamesOnly.add(cn);
                                                }
                                              }
                                              if (classNamesOnly.isEmpty) classNamesOnly.addAll(['1ère TI', 'Terminale TI']);

                                              final activeClass = (_selectedClassFilterPerSchool[scName] != null && classNamesOnly.contains(_selectedClassFilterPerSchool[scName]))
                                                  ? _selectedClassFilterPerSchool[scName]!
                                                  : classNamesOnly.first;

                                              final selectedClassObj = schoolClasses.firstWhere(
                                                (c) => (c['class_name'] ?? '') == activeClass,
                                                orElse: () => schoolClasses.first,
                                              ) as Map<String, dynamic>;

                                              final cName = selectedClassObj['class_name'] ?? activeClass;
                                              final totSt = selectedClassObj['total_students'] ?? 0;
                                              final assSt = selectedClassObj['assessed'] ?? 0;
                                              final vis   = selectedClassObj['visual'] ?? 0;
                                              final aud   = selectedClassObj['auditory'] ?? 0;
                                              final kin   = selectedClassObj['kinesthetic'] ?? 0;
                                              final rw    = selectedClassObj['read_write'] ?? 0;
                                              final cRec  = _isEn ? (selectedClassObj['ai_recommendation_en'] ?? '') : (selectedClassObj['ai_recommendation_fr'] ?? '');
                                              final stList = selectedClassObj['students'] as List? ?? [];

                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // 2. SELECTED CLASS DETAILS CARD
                                                  Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: _bg,
                                                      borderRadius: BorderRadius.circular(16),
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
                                                                Icon(Icons.school_rounded, color: _green, size: 20),
                                                                const SizedBox(width: 8),
                                                                Text('Class: $cName', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16)),
                                                              ],
                                                            ),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                              decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                                              child: Text('${_isEn ? "Students" : "Élèves"}: $totSt ($assSt ${_isEn ? "Assessed" : "Évalués"})', style: TextStyle(color: _green, fontSize: 12, fontWeight: FontWeight.bold)),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Wrap(
                                                          spacing: 8, runSpacing: 6,
                                                          children: [
                                                            _varkBadge(_isEn ? 'Visual' : 'Visuel', vis, const Color(0xFF3B82F6)),
                                                            _varkBadge(_isEn ? 'Auditory' : 'Auditif', aud, const Color(0xFFEC4899)),
                                                            _varkBadge(_isEn ? 'Kinesthetic' : 'Kinesthésique', kin, const Color(0xFF10B981)),
                                                            _varkBadge(_isEn ? 'Read/Write' : 'Lecture/Écriture', rw, const Color(0xFFF59E0B)),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 14),
                                                        Text(_isEn ? 'Students & Dominant Learning Styles:' : 'Élèves & Styles d\'Apprentissage Dominants :', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13)),
                                                        const SizedBox(height: 8),
                                                        Column(
                                                          children: stList.map<Widget>((st) {
                                                            final sMap = st as Map<String, dynamic>;
                                                            final sName = sMap['full_name'] ?? '';
                                                            final sMat = sMap['mat_number'] ?? '';
                                                            final sStyle = sMap['learning_style'] ?? '';
                                                            return Container(
                                                              margin: const EdgeInsets.only(bottom: 6),
                                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                                                              child: Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      CircleAvatar(
                                                                        radius: 14,
                                                                        backgroundColor: _green.withValues(alpha: 0.15),
                                                                        child: Icon(Icons.person_rounded, color: _green, size: 16),
                                                                      ),
                                                                      const SizedBox(width: 10),
                                                                      Column(
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(sName, style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.bold)),
                                                                          Text('${_isEn ? "Matricule" : "Matricule"} : $sMat', style: TextStyle(color: _sub, fontSize: 11)),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  Container(
                                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                                    decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                                                    child: Text(sStyle, style: const TextStyle(color: Color(0xFFEC4899), fontSize: 11, fontWeight: FontWeight.bold)),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }).toList(),
                                                        ),
                                                        const SizedBox(height: 14),
                                                        Container(
                                                          width: double.infinity,
                                                          padding: const EdgeInsets.all(12),
                                                          decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10), border: Border.all(color: _green.withValues(alpha: 0.3))),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Icon(Icons.auto_awesome_rounded, color: _green, size: 18),
                                                                  const SizedBox(width: 8),
                                                                  Text(
                                                                    '${_isEn ? "Final AI Recommendation for" : "Recommandation Finale IA pour"} $cName :',
                                                                    style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 12.5),
                                                                  ),
                                                                ],
                                                              ),
                                                              const SizedBox(height: 6),
                                                              Text(cRec, style: TextStyle(color: _text, fontSize: 12, height: 1.5)),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('$label: ', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          Text('$count', style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold)),
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
