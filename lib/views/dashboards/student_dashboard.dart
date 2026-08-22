import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/offline_assessment_service.dart';
import '../assessment/assessment_view.dart';
import '../../widgets/app_sidebar.dart';
import '../../core/api_config.dart';

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
  int _selectedViewTab = 0; // 0 = Latest Attempt, 1 = Multi-Test Cumulative Synthesis

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
      await ApiConfig.getWorkingHost();
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/assessment.php?action=get_student_result&user_id=${_currentUser.id}'),
      );
      final data = jsonDecode(resp.body);

      if (data['success'] == true && data['data'] != null) {
        setState(() {
          _resultData = data['data'];
          _isLoading = false;
          final attempts = _parseInt(_resultData?['attempt_count']);
          final historyLen = (_resultData?['history'] as List?)?.length ?? 0;
          if (attempts > 1 || historyLen > 1) {
            _selectedViewTab = 1; // Auto-select combined multi-test average when 2+ attempts exist
          }
        });
        return;
      }
    } catch (e) {
      // Fallback to local storage if API call fails
    }

    final offlineData = await OfflineAssessmentService.getStoredResult(_currentUser.id);
    if (offlineData != null) {
      setState(() {
        _resultData = offlineData;
        _isLoading = false;
      });
    } else {
      _useFallbackResult();
    }
  }

  void _useFallbackResult() {
    setState(() {
      _isLoading = false;
      _resultData = {
        'completed': true,
        'attempt_count': 2,
        'learning_style': 'Auditory-Visual (Dual Style)',
        'scores': {
          'visual': 30.0,
          'auditory': 30.0,
          'kinesthetic': 20.0,
          'read_write': 20.0,
        },
        'summary_en': '• Listen to recorded lectures and podcasts.\n• Read your notes aloud or explain concepts to a study partner.\n• Use rhythmic memory devices and rhymes to remember formulas.\n\n• Use color-coded highlighters, mind maps, and diagrams.\n• Watch educational video tutorials and visual demonstrations.\n• Visualize concepts in your mind when recalling notebook pages.',
        'summary_fr': '• Écoutez des cours enregistrés et des podcasts.\n• Lisez vos notes à voix haute ou expliquez les concepts à un camarade.\n• Utilisez des moyens mnémotechniques rythmiques pour retenir les formules.\n\n• Utilisez des surligneurs de couleur, des cartes mentales et des schémas.\n• Regardez des tutoriels vidéo éducatifs et des démonstrations visuelles.\n• Visualisez les concepts dans votre esprit lorsque vous vous remémorez vos cours.',
        'completed_at': DateTime.now().toString().split('.')[0],
        'composite': {
          'learning_style': 'Auditory-Visual (Dual Style)',
          'scores': {
            'visual': 35.0,
            'auditory': 35.0,
            'kinesthetic': 15.0,
            'read_write': 15.0,
          },
          'recommendations': {
            'en': '• Multi-Test AI Strategy: Combine auditory discussions with visual color-coded mind maps.\n• Listen to recorded lectures while creating visual diagrams and summary notes.',
            'fr': '• Stratégie IA Multi-Tests : Combinez les discussions auditives avec des cartes mentales visuelles colorées.\n• Écoutez des cours enregistrés tout en créant des schémas visuels et fiches de synthèse.',
          },
          'trend_en': 'Across your 2 test attempts, your Auditory preference increased (+10%) while Visual preference remained strong. You benefit most from dual-modal auditory and visual learning techniques.',
          'trend_fr': 'Sur l\'ensemble de vos 2 tentatives, votre préférence auditive a augmenté (+10%) tandis que votre préférence visuelle reste forte. Vous bénéficiez d\'une approche bimodal auditive et visuelle.',
        },
        'history': [
          {
            'id': 2,
            'learning_style': 'Auditory-Visual (Dual Style)',
            'scores': {'visual': 30.0, 'auditory': 30.0, 'kinesthetic': 20.0, 'read_write': 20.0},
            'summary_en': '• Listen to recorded lectures and podcasts.\n• Read notes aloud with a study partner.\n• Use color-coded highlighters, mind maps, and diagrams.',
            'summary_fr': '• Écoutez des cours enregistrés et podcasts.\n• Lisez des notes à voix haute avec un camarade.\n• Utilisez des surligneurs de couleur, cartes mentales et diagrammes.',
            'completed_at': DateTime.now().subtract(const Duration(days: 2)).toString().split('.')[0],
          },
          {
            'id': 1,
            'learning_style': 'Visual Dominant',
            'scores': {'visual': 40.0, 'auditory': 20.0, 'kinesthetic': 20.0, 'read_write': 20.0},
            'summary_en': '• Use visual mind maps, diagrams, and color-coded notes.\n• Watch educational videos and visual demonstrations.',
            'summary_fr': '• Utilisez des cartes mentales visuelles, schémas et notes colorées.\n• Regardez des vidéos éducatives et démonstrations visuelles.',
            'completed_at': DateTime.now().subtract(const Duration(days: 7)).toString().split('.')[0],
          }
        ]
      };
    });
  }

  void _downloadStudentReport() {
    if (_resultData != null) {
      OfflineAssessmentService.downloadPdfReport(
        user: _currentUser,
        resultData: _resultData!,
        isEn: _isEn,
      );
    }
  }

  void _showAttemptDetailsModal(Map<String, dynamic> item, int attemptNum) {
    final style = item['learning_style'] ?? 'VARK';
    final dateStr = item['completed_at'] ?? 'N/A';
    final sc = item['scores'] as Map<String, dynamic>? ?? {};
    final summary = _isEn ? (item['summary_en'] ?? '') : (item['summary_fr'] ?? '');

    final v = _parseInt(sc['visual']);
    final a = _parseInt(sc['auditory']);
    final k = _parseInt(sc['kinesthetic']);
    final r = _parseInt(sc['read_write']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(top: BorderSide(color: _border)),
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Text('#$attemptNum', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_isEn ? "Test Attempt" : "Tentative de Test"} #$attemptNum',
                          style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        Text(
                          '${_isEn ? "Completed on" : "Complété le"} $dateStr',
                          style: TextStyle(color: _sub, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: _sub),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dominant Style Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology_rounded, color: _green, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_isEn ? "Dominant Learning Style" : "Style Dominant"}: $style',
                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scores breakdown
              Text(_isEn ? 'VARK Score Breakdown' : 'Répartition des Scores VARK', style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _scoreTile(_isEn ? 'Visual' : 'Visuel', '$v%', const Color(0xFF3B82F6))),
                  const SizedBox(width: 8),
                  Expanded(child: _scoreTile(_isEn ? 'Auditory' : 'Auditif', '$a%', const Color(0xFF8B5CF6))),
                  const SizedBox(width: 8),
                  Expanded(child: _scoreTile(_isEn ? 'Kinesthetic' : 'Kinesthésique', '$k%', const Color(0xFF10B981))),
                  const SizedBox(width: 8),
                  Expanded(child: _scoreTile(_isEn ? 'Read/Write' : 'Lecture/Écriture', '$r%', const Color(0xFFF59E0B))),
                ],
              ),
              const SizedBox(height: 18),

              // AI Recommendation for this test attempt
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: _green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _isEn ? 'AI Recommendation for Test #$attemptNum' : 'Recommandation IA pour Test #$attemptNum',
                          style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      summary.isNotEmpty
                          ? summary
                          : (_isEn ? 'No detailed summary available.' : 'Aucun résumé disponible.'),
                      style: TextStyle(color: _text, fontSize: 12.5, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                      hintText: '1234',
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
                          _currentUser.fullName.isNotEmpty ? _currentUser.fullName[0].toUpperCase() : 'S',
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
                            Text('${_currentUser.role.toUpperCase()} | ${_currentUser.matNumber ?? "STD2026"}', style: TextStyle(color: _sub, fontSize: 12)),
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
                        _showModifyProfileDialog();
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
      onOpenProfile: _showSettingsModalDialog,
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
      body: SafeArea(
        child: Row(
          children: [
            if (isWide) sidebarWidget,
            Expanded(
              child: Column(
                children: [
                  // ── TOP HEADER BAR (UNIFORM & SEAMLESS) ──────────────────────
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
                          if (_isLoading)
                            Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Center(child: CircularProgressIndicator(color: _green)),
                            )
                          else ...[
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                Text(
                                  _isEn ? 'My VARK Diagnostic Results' : 'Mes Résultats Diagnostics VARK',
                                  style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _downloadStudentReport,
                                  icon: const Icon(Icons.download_rounded, size: 18),
                                  label: Text(
                                    _isEn ? 'PDF Report' : 'Rapport PDF',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Segmented View Selector (If 2+ attempts exist)
                            if (((_parseInt(_resultData?['attempt_count'])) > 1 || ((_resultData?['history'] as List?)?.length ?? 0) > 1) && _resultData?['composite'] != null) ...[
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _border),
                                ),
                                padding: const EdgeInsets.all(3),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedViewTab = 0),
                                        borderRadius: BorderRadius.circular(11),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _selectedViewTab == 0 ? _green : Colors.transparent,
                                            borderRadius: BorderRadius.circular(11),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            _isEn ? '🌟 Latest Test Attempt' : '🌟 Dernière Tentative',
                                            style: TextStyle(
                                              color: _selectedViewTab == 0 ? Colors.white : _sub,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => setState(() => _selectedViewTab = 1),
                                        borderRadius: BorderRadius.circular(11),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: _selectedViewTab == 1 ? _green : Colors.transparent,
                                            borderRadius: BorderRadius.circular(11),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            '${_isEn ? "🧠 Multi-Test Synthesis" : "🧠 Synthèse Multi-Tests"} (${_resultData?['attempt_count'] ?? 2})',
                                            style: TextStyle(
                                              color: _selectedViewTab == 1 ? Colors.white : _sub,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],

                            // SINGLE UNIFIED RESULTS CARD
                            Builder(
                              builder: (context) {
                                final isCompositeMode = _selectedViewTab == 1 && _resultData?['composite'] != null;
                                final currentStyle = isCompositeMode
                                    ? (_resultData!['composite']['learning_style'] ?? 'VARK')
                                    : (learningStyle);

                                final scMap = isCompositeMode
                                    ? (_resultData!['composite']['scores'] as Map<String, dynamic>? ?? {})
                                    : (_resultData?['scores'] as Map<String, dynamic>? ?? {});

                                final vVal = isCompositeMode ? '${scMap['visual']}%' : '$vScore%';
                                final aVal = isCompositeMode ? '${scMap['auditory']}%' : '$aScore%';
                                final kVal = isCompositeMode ? '${scMap['kinesthetic']}%' : '$kScore%';
                                final rVal = isCompositeMode ? '${scMap['read_write']}%' : '$rScore%';

                                final aiRecText = isCompositeMode
                                    ? (_isEn
                                        ? (_resultData!['composite']['recommendations']['en'] ?? '')
                                        : (_resultData!['composite']['recommendations']['fr'] ?? ''))
                                    : (_isEn ? (_resultData?['summary_en'] ?? '') : (_resultData?['summary_fr'] ?? ''));

                                final trendText = isCompositeMode
                                    ? (_isEn ? (_resultData!['composite']['trend_en'] ?? '') : (_resultData!['composite']['trend_fr'] ?? ''))
                                    : '';

                                return Container(
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
                                          Icon(isCompositeMode ? Icons.psychology_rounded : Icons.stars_rounded, color: _green, size: 24),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${isCompositeMode ? (_isEn ? "Combined Dominant Style" : "Style Dominant Combiné") : (_isEn ? "Latest Attempt Style" : "Style Dernière Tentative")}: $currentStyle',
                                              style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 15.5),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // 4-Tile Scores Grid
                                      Row(
                                        children: [
                                          Expanded(child: _scoreTile(_isEn ? 'Visual' : 'Visuel', vVal, const Color(0xFF3B82F6))),
                                          const SizedBox(width: 8),
                                          Expanded(child: _scoreTile(_isEn ? 'Auditory' : 'Auditif', aVal, const Color(0xFF8B5CF6))),
                                          const SizedBox(width: 8),
                                          Expanded(child: _scoreTile(_isEn ? 'Kinesthetic' : 'Kinesthésique', kVal, const Color(0xFF10B981))),
                                          const SizedBox(width: 8),
                                          Expanded(child: _scoreTile(_isEn ? 'Read/Write' : 'Lecture/Écriture', rVal, const Color(0xFFF59E0B))),
                                        ],
                                      ),

                                      // Multi-Test Evolution Trend Banner (If composite mode)
                                      if (isCompositeMode && trendText.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: _green.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: _green.withValues(alpha: 0.2)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.trending_up_rounded, color: _green, size: 20),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _isEn ? 'Learning Evolution Insights' : 'Analyse de l\'Évolution d\'Apprentissage',
                                                      style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12.5),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      trendText,
                                                      style: TextStyle(color: _text, fontSize: 12, height: 1.4),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 16),

                                      // AI Recommendation Box
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
                                              aiRecText,
                                              style: TextStyle(color: _text, fontSize: 13, height: 1.6, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // Test Attempt History Timeline
                            if (_resultData?['history'] != null && (_resultData!['history'] as List).isNotEmpty) ...[
                              const SizedBox(height: 22),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _isEn ? 'Test Attempt History' : 'Historique des Tentatives de Test',
                                    style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: _green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                                    child: Text(
                                      '${(_resultData!['history'] as List).length} ${_isEn ? "Attempts" : "Tentatives"}',
                                      style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...(_resultData!['history'] as List).asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                final attemptNum = (_resultData!['history'] as List).length - index;
                                final dateStr = item['completed_at'] ?? 'N/A';
                                final style = item['learning_style'] ?? 'VARK';
                                final sc = item['scores'] as Map<String, dynamic>? ?? {};

                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showAttemptDetailsModal(item, attemptNum),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _card,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: _border),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38, height: 38,
                                            decoration: BoxDecoration(color: _green.withValues(alpha: 0.15), shape: BoxShape.circle),
                                            alignment: Alignment.center,
                                            child: Text('#$attemptNum', style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 13)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${_isEn ? "Attempt" : "Tentative"} #$attemptNum — $style',
                                                  style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${_isEn ? "Date" : "Date"} : $dateStr | V: ${sc['visual']}% A: ${sc['auditory']}% K: ${sc['kinesthetic']}% R: ${sc['read_write']}%',
                                                  style: TextStyle(color: _sub, fontSize: 11.5),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Icon(Icons.touch_app_rounded, color: _green, size: 12),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      _isEn ? 'Tap to view full AI recommendation' : 'Appuyez pour voir la recommandation IA',
                                                      style: TextStyle(color: _green, fontSize: 10.5, fontWeight: FontWeight.w600),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.chevron_right_rounded, color: _sub, size: 22),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ],
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
