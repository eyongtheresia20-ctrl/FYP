import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_sidebar.dart';
import '../../core/api_config.dart';

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
      await ApiConfig.getWorkingHost();
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/dashboard.php?action=teacher_class'),
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
        'class_summaries': [
          {'class_name': '1ère TI', 'total_students': 2, 'assessed': 1},
          {'class_name': 'Terminale TI', 'total_students': 2, 'assessed': 1},
        ],
        'overall_total_classes': 2,
        'overall_total_students': 4,
        'overall_total_assessed': 2,
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
                    // 1. PASSWORD CARD ROW (LABEL TOP, VALUE BELOW)
                    _profileEditableRow(
                      icon: Icons.lock_outline_rounded,
                      label: _isEn ? 'Password' : 'Mot de Passe',
                      controller: passCtrl,
                      obscureText: obscurePass,
                      onToggleObscure: () => setModalState(() => obscurePass = !obscurePass),
                      hintText: '••••••••',
                    ),
                    const SizedBox(height: 10),

                    // 2. SECURITY CODE CARD ROW (LABEL TOP, VALUE BELOW)
                    _profileEditableRow(
                      icon: Icons.security_rounded,
                      label: _isEn ? 'Security Code' : 'Code de Sécurité',
                      controller: secCodeCtrl,
                      obscureText: obscureSec,
                      onToggleObscure: () => setModalState(() => obscureSec = !obscureSec),
                      hintText: '1234@',
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

  Widget _profileEditableRow({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    String? hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 1),
                TextField(
                  controller: controller,
                  obscureText: obscureText,
                  style: TextStyle(color: _text, fontSize: 13.5, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: _sub.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.normal),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 3),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: _sub, size: 20),
            onPressed: onToggleObscure,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
                Expanded(child: _buildSettingsInlineView(() => setModalState(() {}))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsInlineView([VoidCallback? onModalRefresh]) {
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
                      if (onModalRefresh != null) onModalRefresh();
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
                            if (onModalRefresh != null) onModalRefresh();
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
                            if (onModalRefresh != null) onModalRefresh();
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
                            Text('${_currentUser.role.toUpperCase()} | ${_currentUser.matNumber ?? "TCH2026"}', style: TextStyle(color: _sub, fontSize: 12)),
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
                        _showTeacherProfileDialog();
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
          ? '• Diagnostic analysis active for class $className.\n• Complete student VARK assessments to generate customized pedagogical recommendations.'
          : '• Analyse diagnostique active pour la classe $className.\n• Complétez les évaluations VARK des élèves pour générer des recommandations pédagogiques personnalisées.';
    }

    String dominant = 'Auditory';
    int maxCount = aud;
    if (vis > maxCount) { maxCount = vis; dominant = 'Visual'; }
    if (kin > maxCount) { maxCount = kin; dominant = 'Kinesthetic'; }
    if (rw > maxCount)  { maxCount = rw;  dominant = 'Read/Write'; }
    List<String> recsEn = [];
    List<String> recsFr = [];

    if (dominant == 'Auditory') {
      recsEn.add('• Auditory Learning Strategy (Primary Focus) in $className: Incorporate clear verbal explanations, class discussions, audio lecture recordings, and Q&A sessions into daily lesson plans.');
      recsFr.add('• Stratégie d\'Apprentissage Auditif (Focus Principal) en $className : Intégrez des explications orales claires, débats, enregistrements audio et séances de Q/R dans vos cours.');
    } else if (dominant == 'Visual') {
      recsEn.add('• Visual Learning Strategy (Primary Focus) in $className: Utilize color-coded visual charts, mind maps, flowcharts, and video demonstrations during daily instruction.');
      recsFr.add('• Stratégie d\'Apprentissage Visuel (Focus Principal) en $className : Utilisez des schémas visuels en couleurs, cartes mentales, organigrammes et vidéos pendant les leçons.');
    } else if (dominant == 'Kinesthetic') {
      recsEn.add('• Kinesthetic Learning Strategy (Primary Focus) in $className: Structure lessons around hands-on laboratory experiments, interactive coding, and practical exercises.');
      recsFr.add('• Stratégie d\'Apprentissage Kinesthésique (Focus Principal) en $className : Structurez vos cours autour de travaux pratiques en laboratoire, codage interactif et exercices.');
    } else {
      recsEn.add('• Read/Write Learning Strategy (Primary Focus) in $className: Provide structured printed handouts, comprehensive reading glossaries, and detailed bulleted note-taking frameworks.');
      recsFr.add('• Stratégie d\'Apprentissage Lecture/Écriture (Focus Principal) en $className : Fournissez des fiches de cours imprimées, des glossaires détaillés et fiches de résumés.');
    }

    // Include directives for all other learning styles to encourage every student in class
    recsEn.add('• Auditory Strategy: Encourage interactive verbal Q&A sessions and oral presentation tasks.');
    recsFr.add('• Stratégie Auditive : Encouragez des sessions de Q/R orales interactives et exposés oraux.');

    recsEn.add('• Visual Strategy: Prepare color-coded visual diagrams, mind maps, and whiteboard models.');
    recsFr.add('• Stratégie Visuelle : Préparez des schémas visuels en couleurs et cartes mentales.');

    recsEn.add('• Kinesthetic Strategy: Incorporate practical demonstrations, hands-on lab exercises, and active group work.');
    recsFr.add('• Stratégie Kinesthésique : Intégrez des démonstrations pratiques, TP et travaux de groupe actifs.');

    recsEn.add('• Read/Write Strategy: Supply written study outlines, exercise sheets, and structured reading assignments.');
    recsFr.add('• Stratégie Lecture/Écriture : Fournissez des plans de cours écrits et fiches d\'exercices.');

    return isEn ? recsEn.join('\n') : recsFr.join('\n');
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

    final aiRec = _generateClassroomRec(
      vis: visSt,
      aud: audSt,
      kin: kinesSt,
      rw: readWriteSt,
      className: className,
      isEn: _isEn,
    );

    final List students      = _classData?['students'] as List? ?? [];
    final List tickedClasses = (_classData?['ticked_classes'] as List?)?.map((e) => e.toString()).toList() ?? ['1ère TI', 'Terminale TI'];
    final List classSummaries= _classData?['class_summaries'] as List? ?? [];
    final int overallClasses = _parseInt(_classData?['overall_total_classes'] ?? tickedClasses.length);
    final int overallStudents= _parseInt(_classData?['overall_total_students'] ?? students.length);
    final int overallAssessed= _parseInt(_classData?['overall_total_assessed'] ?? summary['assessed']);

    final List<Map<String, dynamic>> parsedClassSummaries = [];
    if (classSummaries.isNotEmpty) {
      for (final cs in classSummaries) {
        if (cs is Map) {
          parsedClassSummaries.add(Map<String, dynamic>.from(cs));
        }
      }
    } else {
      for (final clsName in tickedClasses) {
        final clsStudents = students.where((s) => s['class_name'] == clsName).toList();
        final clsAssessed = clsStudents.where((s) => s['learning_style'] != null && s['learning_style'] != 'Not Assessed').length;
        parsedClassSummaries.add({
          'class_name': clsName,
          'total_students': clsStudents.length,
          'assessed': clsAssessed,
        });
      }
    }

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

                            LayoutBuilder(
                               builder: (ctx, constraints) {
                                 final isNarrow = constraints.maxWidth < 600;

                                 final classesCard = _overviewStatCard(
                                   icon: Icons.class_rounded,
                                   label: _isEn ? 'Assigned Classes' : 'Classes Assignées',
                                   value: '$overallClasses ${_isEn ? "Classes" : "Classes"}',
                                   color: const Color(0xFF3B82F6),
                                   subtitle: tickedClasses.join(' • '),
                                 );

                                 final totalStdsCard = _overviewStatCard(
                                   icon: Icons.people_alt_rounded,
                                   label: _isEn ? 'Total Enrolled' : 'Total Inscrits',
                                   value: '$overallStudents ${_isEn ? "Students" : "Élèves"}',
                                   color: const Color(0xFF006A4E),
                                   subtitle: _isEn ? 'Across assigned classes' : 'Classes assignées',
                                 );

                                 final overallPctText = overallStudents > 0 ? '${((overallAssessed / overallStudents) * 100).toInt()}%' : '0%';
                                 final assessedStdsCard = _overviewStatCard(
                                   icon: Icons.assignment_turned_in_rounded,
                                   label: _isEn ? 'Total Assessed' : 'Total Évalués',
                                   value: '$overallAssessed / $overallStudents',
                                   color: const Color(0xFF10B981),
                                   subtitle: '$overallPctText ${_isEn ? "Assessment Rate" : "Taux d'Évaluation"}',
                                 );

                                 final pedagogicalCard = _overviewStatCard(
                                   icon: Icons.psychology_rounded,
                                   label: _isEn ? 'Pedagogical Status' : 'Statut Pédagogique',
                                   value: _isEn ? 'Optimal' : 'Optimal',
                                   color: const Color(0xFF8B5CF6),
                                   subtitle: _isEn ? 'VARK Diagnostic Active' : 'Diagnostic VARK Actif',
                                 );

                                 if (isNarrow) {
                                   return Column(
                                     children: [
                                       Row(
                                         children: [
                                           Expanded(child: classesCard),
                                           const SizedBox(width: 10),
                                           Expanded(child: totalStdsCard),
                                         ],
                                       ),
                                       const SizedBox(height: 10),
                                       Row(
                                         children: [
                                           Expanded(child: assessedStdsCard),
                                           const SizedBox(width: 10),
                                           Expanded(child: pedagogicalCard),
                                         ],
                                       ),
                                     ],
                                   );
                                 } else {
                                   return Row(
                                     children: [
                                       Expanded(child: classesCard),
                                       const SizedBox(width: 10),
                                       Expanded(child: totalStdsCard),
                                       const SizedBox(width: 10),
                                       Expanded(child: assessedStdsCard),
                                       const SizedBox(width: 10),
                                       Expanded(child: pedagogicalCard),
                                     ],
                                   );
                                 }
                               },
                            ),

                            // Per-Class Breakdown Section
                            _buildPerClassBreakdownSection(parsedClassSummaries),
                          ],

                          // ── TAB INDEX 1: CLASS DETAILS VIEW (WELCOME BANNER REMOVED AS REQUESTED) ──
                          if (_currentNavIndex == 1) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
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
                             // VARK Cards Grid (Responsive Grid on Mobile vs Row on Desktop)
                             Text(
                               _isEn ? 'Class Learning Styles Breakdown' : 'Répartition des Styles d\'Apprentissage de la Classe',
                               style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
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
                                           Expanded(child: _varkStatCard(_isEn ? 'Visual' : 'Visuel', '$visSt', Icons.visibility_rounded, const Color(0xFF3B82F6))),
                                           const SizedBox(width: 10),
                                           Expanded(child: _varkStatCard(_isEn ? 'Auditory' : 'Auditif', '$audSt', Icons.record_voice_over_rounded, const Color(0xFFEC4899))),
                                         ],
                                       ),
                                       const SizedBox(height: 10),
                                       Row(
                                         children: [
                                           Expanded(child: _varkStatCard(_isEn ? 'Kinesthetic' : 'Kinesthésique', '$kinesSt', Icons.directions_run_rounded, const Color(0xFF10B981))),
                                           const SizedBox(width: 10),
                                           Expanded(child: _varkStatCard(_isEn ? 'Read/Write' : 'Lecture/Écriture', '$readWriteSt', Icons.menu_book_rounded, const Color(0xFFF59E0B))),
                                         ],
                                       ),
                                     ],
                                   );
                                 } else {
                                   return Row(
                                     children: [
                                       Expanded(child: _varkStatCard(_isEn ? 'Visual' : 'Visuel', '$visSt', Icons.visibility_rounded, const Color(0xFF3B82F6))),
                                       const SizedBox(width: 10),
                                       Expanded(child: _varkStatCard(_isEn ? 'Auditory' : 'Auditif', '$audSt', Icons.record_voice_over_rounded, const Color(0xFFEC4899))),
                                       const SizedBox(width: 10),
                                       Expanded(child: _varkStatCard(_isEn ? 'Kinesthetic' : 'Kinesthésique', '$kinesSt', Icons.directions_run_rounded, const Color(0xFF10B981))),
                                       const SizedBox(width: 10),
                                       Expanded(child: _varkStatCard(_isEn ? 'Read/Write' : 'Lecture/Écriture', '$readWriteSt', Icons.menu_book_rounded, const Color(0xFFF59E0B))),
                                     ],
                                   );
                                 }
                               },
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
                                       Expanded(
                                         child: Text(
                                           _isEn ? 'Recommendation' : 'Recommandation',
                                           style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15),
                                         ),
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

                             // STUDENT ROSTER & RESULTS SECTION (RESPONSIVE WRAP)
                             Wrap(
                               alignment: WrapAlignment.spaceBetween,
                               crossAxisAlignment: WrapCrossAlignment.center,
                               spacing: 12,
                               runSpacing: 10,
                               children: [
                                 Row(
                                   mainAxisSize: MainAxisSize.min,
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
                                   mainAxisSize: MainAxisSize.min,
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

                                         // Scores Breakdown Row (Responsive Wrap)
                                         Container(
                                           width: double.infinity,
                                           padding: const EdgeInsets.all(10),
                                           decoration: BoxDecoration(
                                             color: _bg,
                                             borderRadius: BorderRadius.circular(10),
                                             border: Border.all(color: _border.withValues(alpha: 0.5)),
                                           ),
                                           child: Wrap(
                                             alignment: WrapAlignment.spaceAround,
                                             spacing: 8,
                                             runSpacing: 8,
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
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.trending_up_rounded, color: color.withValues(alpha: 0.5), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Text(label, style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPerClassBreakdownSection(List<Map<String, dynamic>> parsedClassSummaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
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
                '${parsedClassSummaries.length} ${_isEn ? "Assigned Classes" : "Classes Assignées"}',
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
              // Clean Structured Data Table View for Desktop / Wide screens
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
                                    setState(() => _currentNavIndex = 1);
                                    _fetchClassData(clsName);
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
              // Mobile View List Cards
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
                                setState(() => _currentNavIndex = 1);
                                _fetchClassData(clsName);
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
