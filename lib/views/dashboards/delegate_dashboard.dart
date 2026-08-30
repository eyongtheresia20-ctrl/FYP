import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';
import '../../core/api_config.dart';

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
  String? _selectedSubSchoolFilter;
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
      await ApiConfig.getWorkingHost();
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dashboard.php?action=$action&user_id=${_currentUser.id}'),
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

    final totalSchools = _parseInt(_delegateData?['total_schools'] ?? 0);
    final totalStudents = _parseInt(_delegateData?['total_students'] ?? 0);
    final assessedStudents = _parseInt(_delegateData?['assessed_students'] ?? 0);
    final totalTeachers = _parseInt(_delegateData?['total_teachers'] ?? 0);
    final visualCount = _parseInt(_delegateData?['visual_count'] ?? 0);
    final auditoryCount = _parseInt(_delegateData?['auditory_count'] ?? 0);
    final kinestheticCount = _parseInt(_delegateData?['kinesthetic_count'] ?? 0);
    final readWriteCount = _parseInt(_delegateData?['read_write_count'] ?? 0);

    final csvContent = '''MINESEC LST — Territorial Delegation VARK Report
"Field","Value"
"Title","$title"
"Delegate Name","$delegate"
"Region","${_currentUser.region ?? "ADAMOUA"}"
"Division","${_currentUser.division ?? "DJEREM"}"
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
        'total_schools': isReg ? 4 : 3,
        'total_students': 4,
        'assessed_students': 2,
        'total_teachers': 1,
        'visual_count': 0,
        'auditory_count': 2,
        'kinesthetic_count': 0,
        'read_write_count': 0,
        'items': isReg
            ? [
                {
                  'name': 'DJEREM',
                  'schools_count': 3,
                  'teachers_count': 1,
                  'students_count': 2,
                  'assessed_count': 1,
                  'assessed_rate': '50%',
                  'schools': [
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
                          'students': [
                            {'full_name': 'Amina Mohamadou', 'mat_number': 'AD2026002', 'class_name': 'Terminale TI', 'learning_style': 'Not Assessed'},
                          ]
                        }
                      ]
                    },
                    {'name': 'LYCEE CLASSIQUE DE NGAOUNDAL', 'teachers_count': 0, 'students_count': 0, 'assessed_rate': '0%', 'classes': []},
                    {'name': 'LYCEE BILINGUE DE NGAOUNDAL', 'teachers_count': 0, 'students_count': 0, 'assessed_rate': '0%', 'classes': []}
                  ]
                },
                {'name': 'MAYO-BALEO', 'schools_count': 0, 'students_count': 0, 'assessed_rate': '0%', 'schools': []},
                {'name': 'FARO-ET-DEO', 'schools_count': 0, 'students_count': 0, 'assessed_rate': '0%', 'schools': []},
                {
                  'name': 'VINA',
                  'schools_count': 1,
                  'students_count': 0,
                  'assessed_rate': '0%',
                  'schools': [
                    {'name': 'LYCEE TECHNIQUE DE NGAOUNDERE', 'teachers_count': 0, 'students_count': 0, 'assessed_rate': '0%', 'classes': []}
                  ]
                },
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
        'ai_policy_en': _generateDelegatePolicyRec(
          vis: isReg ? 6800 : 1600,
          aud: isReg ? 4900 : 1100,
          kin: isReg ? 2100 : 500,
          rw: isReg ? 1400 : 400,
          regionOrDivision: isReg ? (_currentUser.region ?? 'ADAMOUA') : (_currentUser.division ?? 'DJEREM'),
          isRegional: isReg,
          isEn: true,
        ),
        'ai_policy_fr': _generateDelegatePolicyRec(
          vis: isReg ? 6800 : 1600,
          aud: isReg ? 4900 : 1100,
          kin: isReg ? 2100 : 500,
          rw: isReg ? 1400 : 400,
          regionOrDivision: isReg ? (_currentUser.region ?? 'ADAMOUA') : (_currentUser.division ?? 'DJEREM'),
          isRegional: isReg,
          isEn: false,
        ),
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
                          _currentUser.fullName.isNotEmpty ? _currentUser.fullName[0].toUpperCase() : 'D',
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
                            Text('${_currentUser.role.toUpperCase()} | ${_currentUser.matNumber ?? "DLG2026"}', style: TextStyle(color: _sub, fontSize: 12)),
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
                        _showDelegateProfileDialog();
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

  String _generateDelegatePolicyRec({
    required int vis,
    required int aud,
    required int kin,
    required int rw,
    required String regionOrDivision,
    required bool isRegional,
    required bool isEn,
  }) {
    final total = vis + aud + kin + rw;
    final entityTypeEn = isRegional ? 'Regional' : 'Divisional';
    final entityTypeFr = isRegional ? 'Régionale' : 'Départementale';

    if (total == 0) {
      return isEn
          ? '• $entityTypeEn VARK Diagnostic Directive for $regionOrDivision:\n• Coordinate inspection visits with school principals across $regionOrDivision to accelerate student VARK diagnostic completion.\n• Ensure all secondary lycées establish offline diagnostic stations for unassessed classes.'
          : '• Directive de Diagnostic $entityTypeFr pour le $regionOrDivision :\n• Coordonnez les visites d\'inspection avec les proviseurs du $regionOrDivision pour accélérer la réalisation des tests VARK.\n• Veillez à ce que tous les lycées installent des stations de diagnostic hors-ligne.';
    }

    final counts = {'Visual': vis, 'Auditory': aud, 'Kinesthetic': kin, 'Read/Write': rw};
    String dominant = 'Auditory';
    int maxCount = aud;
    if (vis > maxCount) { maxCount = vis; dominant = 'Visual'; }
    if (kin > maxCount) { maxCount = kin; dominant = 'Kinesthetic'; }
    if (rw > maxCount)  { maxCount = rw;  dominant = 'Read/Write'; }

    final int pct = total > 0 ? ((maxCount / total) * 100).round() : 0;

    List<String> recsEn = [];
    List<String> recsFr = [];

    if (dominant == 'Auditory') {
      recsEn.add('• Auditory Learning Strategy (Primary Focus) in $regionOrDivision: Prioritize audio-visual equipment, lecture recordings, peer debates, and verbal instruction toolkits across all lycées.');
      recsFr.add('• Stratégie d\'Apprentissage Auditif (Focus Principal) au $regionOrDivision : Priorisez les équipements audiovisuels, enregistrements de cours, débats et outils d\'enseignement oral dans les lycées.');
    } else if (dominant == 'Visual') {
      recsEn.add('• Visual Learning Strategy (Primary Focus) in $regionOrDivision: Allocate digital projectors, interactive smartboards, visual simulation software, and color-coded study guides.');
      recsFr.add('• Stratégie d\'Apprentissage Visuel (Focus Principal) au $regionOrDivision : Allouez des vidéoprojecteurs, tableaux interactifs, logiciels visuels et fiches synthétiques en couleurs.');
    } else if (dominant == 'Kinesthetic') {
      recsEn.add('• Kinesthetic Learning Strategy (Primary Focus) in $regionOrDivision: Expand practical computer science laboratories, technical hardware workshops, and practical field training.');
      recsFr.add('• Stratégie d\'Apprentissage Kinesthésique (Focus Principal) au $regionOrDivision : Développez les laboratoires informatiques pratiques, ateliers de maintenance et stages techniques.');
    } else {
      recsEn.add('• Read/Write Learning Strategy (Primary Focus) in $regionOrDivision: Enrich school libraries with updated textbooks, digital reference manuals, e-libraries, and essay competitions.');
      recsFr.add('• Stratégie d\'Apprentissage Lecture/Écriture (Focus Principal) au $regionOrDivision : Enrichissez les bibliothèques en manuels, répertoires numériques et concours de rédaction.');
    }

    // Include directives for all other learning styles to encourage all students
    recsEn.add('• Auditory Directive: Facilitate interactive classroom discussions, oral presentations, and group debate competitions.');
    recsFr.add('• Directive Auditive : Facilitez les discussions interactives en classe, exposés oraux et concours de débats.');

    recsEn.add('• Visual Directive: Inspect computer labs and equip classrooms with visual charts, multi-colored whiteboards, and mind-mapping software.');
    recsFr.add('• Directive Visuelle : Inspectez les labos informatiques et équipez les classes de supports visuels et schémas.');

    recsEn.add('• Kinesthetic Workshop Directive: Provide hands-on laboratory equipment, practical ICT workshops, and physical learning activities.');
    recsFr.add('• Directive Kinesthésique : Fournissez du matériel de laboratoire pratique, des ateliers informatiques et activités physiques.');

    recsEn.add('• Read/Write Support: Supply comprehensive textbook reference guides, structured note-taking frameworks, and library resources.');
    recsFr.add('• Soutien Lecture/Écriture : Mettez à disposition des manuels de référence complets, fiches de synthèse et ressources en bibliothèque.');

    return isEn ? recsEn.join('\n') : recsFr.join('\n');
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

    final String aiPolicy = _generateDelegatePolicyRec(
      vis: visSt,
      aud: audSt,
      kin: kinesSt,
      rw: rwSt,
      regionOrDivision: isReg ? (_currentUser.region ?? 'ADAMOUA') : (_currentUser.division ?? 'DJEREM'),
      isRegional: isReg,
      isEn: _isEn,
    );

    final isWide = MediaQuery.of(context).size.width >= 800;

    final sidebarWidget = AppSidebar(
      user: _currentUser,
      isDarkMode: _isDarkMode,
      isEn: _isEn,
      selectedIndex: _currentNavIndex,
      tickedClasses: schoolNames,
      selectedClass: _selectedSchoolFilter ?? schoolNames.first,
      delegateItems: items,
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
            _selectedSubSchoolFilter = null;
          }
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
                                            _isEn ? 'Welcome Back,' : 'Bienvenue,',
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

                             // Metric Stat Cards Header (Responsive Wrap)
                             Wrap(
                               alignment: WrapAlignment.spaceBetween,
                               crossAxisAlignment: WrapCrossAlignment.center,
                               spacing: 12,
                               runSpacing: 10,
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

                             LayoutBuilder(
                               builder: (ctx, constraints) {
                                 final isNarrow = constraints.maxWidth < 600;
                                 if (isNarrow) {
                                   return Column(
                                     children: [
                                       Row(
                                         children: [
                                           Expanded(child: _overviewStatCard(icon: Icons.location_city_rounded, label: isReg ? (_isEn ? 'Total Schools' : 'Établissements') : (_isEn ? 'Schools' : 'Établissements'), value: '$totalSchools', color: const Color(0xFF006A4E))),
                                           const SizedBox(width: 10),
                                           Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF3B82F6))),
                                         ],
                                       ),
                                       const SizedBox(height: 10),
                                       Row(
                                         children: [
                                           Expanded(child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'Assessed Students' : 'Élèves Évalués', value: '$assessed', color: const Color(0xFF10B981))),
                                           const SizedBox(width: 10),
                                           Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Teachers' : 'Enseignants', value: '$totalTeachers', color: const Color(0xFF8B5CF6))),
                                         ],
                                       ),
                                     ],
                                   );
                                 } else {
                                   return Row(
                                     children: [
                                       Expanded(child: _overviewStatCard(icon: Icons.location_city_rounded, label: isReg ? (_isEn ? 'Total Schools' : 'Établissements') : (_isEn ? 'Schools' : 'Établissements'), value: '$totalSchools', color: const Color(0xFF006A4E))),
                                       const SizedBox(width: 10),
                                       Expanded(child: _overviewStatCard(icon: Icons.people_alt_rounded, label: _isEn ? 'Total Students' : 'Total Élèves', value: '$totalStudents', color: const Color(0xFF3B82F6))),
                                       const SizedBox(width: 10),
                                       Expanded(child: _overviewStatCard(icon: Icons.assignment_turned_in_rounded, label: _isEn ? 'Assessed Students' : 'Élèves Évalués', value: '$assessed', color: const Color(0xFF10B981))),
                                       const SizedBox(width: 10),
                                       Expanded(child: _overviewStatCard(icon: Icons.badge_rounded, label: _isEn ? 'Teachers' : 'Enseignants', value: '$totalTeachers', color: const Color(0xFF8B5CF6))),
                                     ],
                                   );
                                 }
                               },
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
                                       Expanded(
                                         child: Text(isReg ? (_isEn ? 'Regional VARK Learning Styles Breakdown' : 'Répartition VARK Régionale') : (_isEn ? 'Divisional VARK Learning Styles Breakdown' : 'Répartition VARK Départementale'), style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 16)),
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
                                       Container(
                                         width: 150,
                                         height: 150,
                                         padding: const EdgeInsets.all(8),
                                         decoration: BoxDecoration(
                                           color: _bg,
                                           shape: BoxShape.circle,
                                           border: Border.all(color: _border.withValues(alpha: 0.6)),
                                           boxShadow: [
                                             BoxShadow(
                                               color: _green.withValues(alpha: 0.08),
                                               blurRadius: 16,
                                               spreadRadius: 2,
                                             ),
                                           ],
                                         ),
                                         child: CustomPaint(
                                           painter: _VarkPieChartPainter(
                                             visual: visSt,
                                             auditory: audSt,
                                             kinesthetic: kinesSt,
                                             readWrite: rwSt,
                                           ),
                                         ),
                                       ),
                                       ConstrainedBox(
                                         constraints: const BoxConstraints(maxWidth: 320),
                                         child: Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                             _pieLegendItem(_isEn ? 'Visual Learner' : 'Visuel', visSt, assessed, const Color(0xFF3B82F6)),
                                             _pieLegendItem(_isEn ? 'Auditory Learner' : 'Auditif', audSt, assessed, const Color(0xFFEC4899)),
                                             _pieLegendItem(_isEn ? 'Kinesthetic Learner' : 'Kinesthésique', kinesSt, assessed, const Color(0xFF10B981)),
                                             _pieLegendItem(_isEn ? 'Read/Write Learner' : 'Lecture/Écriture', rwSt, assessed, const Color(0xFFF59E0B)),
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
                                      Text(_isEn ? 'Regional Pedagogical Directives' : 'Directives Pédagogiques Régionales', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(aiPolicy, style: TextStyle(color: _text, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],

                          // ── TAB 2: DIVISIONS / SCHOOLS & CLASSES DIRECTORY ─────────
                          if (_currentNavIndex == 2) ...[
                            Builder(
                              builder: (ctx) {
                                // 1. Selected Division or Primary Filter
                                final activeDivisionName = (_selectedSchoolFilter != null && schoolNames.contains(_selectedSchoolFilter))
                                    ? _selectedSchoolFilter!
                                    : schoolNames.first;

                                // Extract items matching activeDivisionName
                                Map<String, dynamic> activeDivObj = {};
                                List<Map<String, dynamic>> schoolItems = [];

                                if (isReg) {
                                  activeDivObj = items.firstWhere(
                                    (it) => (it['name'] ?? '') == activeDivisionName,
                                    orElse: () => items.isNotEmpty ? items.first as Map<String, dynamic> : {'name': activeDivisionName},
                                  ) as Map<String, dynamic>;

                                  final rawSc = activeDivObj['schools'] as List? ?? [];
                                  schoolItems = rawSc.map((e) => Map<String, dynamic>.from(e as Map)).toList();
                                } else {
                                  schoolItems = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
                                }

                                if (schoolItems.isEmpty) {
                                  schoolItems = [
                                    {
                                      'name': 'LYCEE TECHNIQUE DE NGAOUNDAL',
                                      'teachers_count': 1,
                                      'students_count': 2,
                                      'classes': [
                                        {
                                          'class_name': '1ère TI',
                                          'total_students': 65,
                                          'assessed': 54,
                                          'visual': 28,
                                          'auditory': 16,
                                          'kinesthetic': 6,
                                          'read_write': 4,
                                          'students': [
                                            {'full_name': 'Bello Oumarou', 'mat_number': 'AD2026001', 'learning_style': 'Visual Learner'},
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
                                          'students': [
                                            {'full_name': 'Amina Mohamadou', 'mat_number': 'AD2026002', 'learning_style': 'Auditory Learner'},
                                          ]
                                        }
                                      ]
                                    },
                                    {
                                      'name': 'LYCEE CLASSIQUE DE NGAOUNDAL',
                                      'teachers_count': 0,
                                      'students_count': 0,
                                      'classes': []
                                    },
                                    {
                                      'name': 'LYCEE BILINGUE DE NGAOUNDAL',
                                      'teachers_count': 0,
                                      'students_count': 0,
                                      'classes': []
                                    }
                                  ];
                                }

                                final availableSchoolNames = schoolItems.map((s) => s['name'] as String? ?? '').where((s) => s.isNotEmpty).toList();
                                if (availableSchoolNames.isEmpty) availableSchoolNames.add('LYCEE TECHNIQUE DE NGAOUNDAL');

                                final activeSchoolName = (_selectedSubSchoolFilter != null && availableSchoolNames.contains(_selectedSubSchoolFilter))
                                    ? _selectedSubSchoolFilter!
                                    : availableSchoolNames.first;

                                final selectedSchoolObj = schoolItems.firstWhere(
                                  (it) => (it['name'] ?? '') == activeSchoolName,
                                  orElse: () => schoolItems.first,
                                );

                                final scName = selectedSchoolObj['name'] ?? activeSchoolName;
                                final schoolClasses = selectedSchoolObj['classes'] as List? ?? [];

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
                                  orElse: () => schoolClasses.isNotEmpty ? schoolClasses.first as Map<String, dynamic> : {},
                                ) as Map<String, dynamic>;

                                final cName = selectedClassObj['class_name'] ?? activeClass;
                                final totSt = _parseInt(selectedClassObj['total_students'] ?? 0);
                                final assSt = _parseInt(selectedClassObj['assessed'] ?? 0);
                                final vis   = _parseInt(selectedClassObj['visual'] ?? 0);
                                final aud   = _parseInt(selectedClassObj['auditory'] ?? 0);
                                final kin   = _parseInt(selectedClassObj['kinesthetic'] ?? 0);
                                final rw    = _parseInt(selectedClassObj['read_write'] ?? 0);
                                final stList = selectedClassObj['students'] as List? ?? [];

                                final cRec = _generateClassroomRec(
                                  vis: vis,
                                  aud: aud,
                                  kin: kin,
                                  rw: rw,
                                  className: '$cName ($scName)',
                                  isEn: _isEn,
                                );

                                final scRec = _isEn
                                    ? (selectedSchoolObj['ai_recommendation_en'] as String? ?? '• Institutional Policy Directive for $scName: Coordinate with head teachers to complete VARK diagnostics and allocate audio-visual tools across all departments.')
                                    : (selectedSchoolObj['ai_recommendation_fr'] as String? ?? '• Directive Institutionnelle pour $scName : Coordonnez avec les proviseurs pour finaliser les tests VARK et allouer du matériel audio-visuel.');

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // ── SCHOOL LEVEL POLICY RECOMMENDATION CARD ──────────────────
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _card,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: _green.withValues(alpha: 0.35), width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _green.withValues(alpha: 0.06),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: _green.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Icon(Icons.account_balance_rounded, color: _green, size: 22),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _isEn ? 'School Directive & Recommendation' : 'Directive & Recommandation par Établissement',
                                                      style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      scName,
                                                      style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 15.5),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _bg,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: _border),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.auto_awesome_rounded, color: _green, size: 18),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    scRec,
                                                    style: TextStyle(color: _text, fontSize: 12.5, height: 1.5, fontWeight: FontWeight.w500),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // SELECTED CLASS DETAILS & VARK BREAKDOWN CARD
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: _card,
                                        borderRadius: BorderRadius.circular(16),
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
                                                  Icon(Icons.school_rounded, color: _green, size: 20),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Class: $cName',
                                                      style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                                child: Text(
                                                  '${_isEn ? "Students" : "Élèves"}: $totSt ($assSt ${_isEn ? "Assessed" : "Évalués"})',
                                                  style: TextStyle(color: _green, fontSize: 11.5, fontWeight: FontWeight.bold),
                                                ),
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
                                          Text(
                                            _isEn ? 'Students & Dominant Learning Styles:' : 'Élèves & Styles d\'Apprentissage Dominants :',
                                            style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(height: 8),
                                          Column(
                                            children: stList.map<Widget>((st) {
                                              final sMap = st as Map<String, dynamic>;
                                              final sName = sMap['full_name'] ?? '';
                                              final sMat = sMap['mat_number'] ?? '';
                                              final sStyle = sMap['learning_style'] ?? '';
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _border)),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          CircleAvatar(
                                                            radius: 14,
                                                            backgroundColor: _green.withValues(alpha: 0.15),
                                                            child: Icon(Icons.person_rounded, color: _green, size: 16),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(sName, style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                                                Text('${_isEn ? "Matricule" : "Matricule"} : $sMat', style: TextStyle(color: _sub, fontSize: 10.5), overflow: TextOverflow.ellipsis),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                                                      child: Text(sStyle, style: const TextStyle(color: Color(0xFFEC4899), fontSize: 10.5, fontWeight: FontWeight.bold)),
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
                                            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: _green.withValues(alpha: 0.3))),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.auto_awesome_rounded, color: _green, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        _isEn ? 'Recommendation' : 'Recommandation',
                                                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
                                                        softWrap: true,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(cRec, style: TextStyle(color: _text, fontSize: 12, height: 1.5), softWrap: true),
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

  Widget _pieLegendItem(String label, int count, int total, Color color) {
    final int pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$count${total > 0 ? " ($pct%)" : ""}',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
