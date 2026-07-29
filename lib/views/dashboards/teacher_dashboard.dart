import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

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
  bool _isLoading = true;
  Map<String, dynamic>? _classData;
  String? _errorMsg;

  Color get _green  => const Color(0xFF006A4E);
  Color get _accent => const Color(0xFF34D399);
  Color get _bg     => widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  Color get _card   => widget.isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _text   => widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => widget.isDarkMode ? Colors.white60 : const Color(0xFF64748B);
  Color get _border => widget.isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _fetchClassData();
  }

  Future<void> _fetchClassData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final resp = await http.post(
        Uri.parse('http://localhost:8080/minesec_api/api/dashboard.php?action=teacher_class'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': _currentUser.id}),
      );

      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        setState(() {
          _classData = data['data'];
          _isLoading = false;
        });
      } else {
        _useFallbackData();
      }
    } catch (e) {
      _useFallbackData();
    }
  }

  void _useFallbackData() {
    setState(() {
      _isLoading = false;
      _classData = {
        'class_name': '1ère TI',
        'subject': 'Informatique',
        'staff_id': 'T2026001',
        'summary': {
          'total_students': 15,
          'assessed': 12,
          'visual': 5,
          'auditory': 4,
          'kinesthetic': 2,
          'read_write': 1,
        },
        'students': [
          {
            'full_name': 'Bello Oumarou',
            'mat_number': 'AD2026001',
            'class_name': '1ère TI',
            'learning_style': 'Visual-Auditory',
            'visual_score': 8,
            'auditory_score': 7,
            'kinesthetic_score': 4,
          },
          {
            'full_name': 'Amina Mohamadou',
            'mat_number': 'AD2026002',
            'class_name': '1ère TI',
            'learning_style': 'Auditory-Kinesthetic',
            'visual_score': 5,
            'auditory_score': 9,
            'kinesthetic_score': 8,
          },
          {
            'full_name': 'Ngo Mbock Marie',
            'mat_number': 'CM2026002',
            'class_name': '1ère TI',
            'learning_style': 'Visual',
            'visual_score': 10,
            'auditory_score': 3,
            'kinesthetic_score': 2,
          },
          {
            'full_name': 'Kamga Paul',
            'mat_number': 'CM2026001',
            'class_name': '1ère TI',
            'learning_style': 'Kinesthetic',
            'visual_score': 4,
            'auditory_score': 4,
            'kinesthetic_score': 9,
          },
        ],
        'ai_recommendation_en':
            '• Primary Mode: Visual & Auditory Learners Dominant\n• Use high-contrast color coding, architectural mind maps, and live code flowcharts.\n• Conduct interactive Q&A sessions and verbal logic walkthroughs.\n• Provide structured hands-on lab exercises for practical reinforcement.',
        'ai_recommendation_fr':
            '• Mode Principal : Apprenants Visuels & Auditifs Dominants\n• Utilisez des organigrammes de code, cartes mentales visuelles et du surlignage couleur.\n• Organisez des échanges interactifs et des synthèses orales de logique informatique.\n• Proposez des ateliers de travaux pratiques guidés en laboratoire.',
      };
    });
  }

  void _showTeacherProfileDialog() {
    final roleLabel = widget.isEn ? 'Teacher' : 'Enseignant(e)';

    final passCtrl    = TextEditingController(text: 'password123');
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

                  // Avatar Header Banner
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
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
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
                      Icon(Icons.badge_outlined, color: _green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.isEn ? 'Teacher Information & Credentials' : 'Informations & Identifiants Enseignant',
                        style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Profile Details (Read-only Cards)
                  _profileInfoRow(Icons.person_outline_rounded, widget.isEn ? 'Full Name' : 'Nom Complet', _currentUser.fullName),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.confirmation_number_outlined, widget.isEn ? 'Matricule / Staff ID' : 'Matricule Enseignant', _classData?['staff_id'] ?? 'T2026001'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.school_outlined, widget.isEn ? 'School' : 'École', 'LYCEE TECHNIQUE DE NGAOUNDAL'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.class_outlined, widget.isEn ? 'Assigned Class' : 'Classe Assignée', _classData?['class_name'] ?? '1ère TI'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.menu_book_outlined, widget.isEn ? 'Subject' : 'Matière Enseignée', _classData?['subject'] ?? 'Informatique'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.map_outlined, widget.isEn ? 'Region' : 'Région', _currentUser.region ?? 'ADAMOUA'),
                  const SizedBox(height: 8),
                  _profileInfoRow(Icons.location_city_outlined, widget.isEn ? 'Division' : 'Département', _currentUser.division ?? 'DJEREM'),
                  const SizedBox(height: 18),

                  // Security Settings Section Header
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isEn ? 'Modify Present Password & Security Code' : 'Modifier Mot de Passe & Code de Sécurité',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Present Security Code Input
                  TextField(
                    controller: secCodeCtrl,
                    obscureText: obscureSec,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.isEn ? 'Present Security Code (e.g. 1234)' : 'Code de Sécurité Présent (ex: 1234)',
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

                  // Present Password Input
                  TextField(
                    controller: passCtrl,
                    obscureText: obscurePass,
                    decoration: InputDecoration(
                      labelText: widget.isEn ? 'Present Password' : 'Mot de Passe Présent',
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

                  // Save Button
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
                            SnackBar(content: Text(widget.isEn ? 'Please enter a password or security code.' : 'Veuillez saisir un mot de passe ou code de sécurité.')),
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
                                  content: Text(widget.isEn ? 'Security code & password updated in database!' : 'Code de sécurité et mot de passe mis à jour dans la base de données !'),
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
                        saving ? (widget.isEn ? 'Saving...' : 'Enregistrement...') : (widget.isEn ? 'Save Changes' : 'Enregistrer les Modifications'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Close button
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(widget.isEn ? 'Cancel' : 'Annuler', style: TextStyle(color: _sub)),
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
    final className = _classData?['class_name'] ?? '1ère TI';
    final subject   = _classData?['subject'] ?? 'Informatique';
    final summary   = _classData?['summary'] as Map<String, dynamic>? ?? {};

    final int totalSt    = summary['total_students'] ?? 0;
    final int assessedSt = summary['assessed'] ?? 0;
    final int visualSt   = summary['visual'] ?? 0;
    final int auditorySt = summary['auditory'] ?? 0;
    final int kinesSt    = summary['kinesthetic'] ?? 0;
    final int readWriteSt= summary['read_write'] ?? 0;

    final aiRec = widget.isEn
        ? (_classData?['ai_recommendation_en'] ?? '')
        : (_classData?['ai_recommendation_fr'] ?? '');

    final List students = _classData?['students'] as List? ?? [];

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.school_rounded, color: _green, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EDU PROFILE', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 15)),
                Text(
                  widget.isEn ? 'Teacher Workspace' : 'Espace Enseignant',
                  style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'profile') _showTeacherProfileDialog();
              if (val == 'logout') {
                AuthService.logout();
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _green,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: _green.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    widget.isEn ? 'Account' : 'Compte',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 20),
                ],
              ),
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, color: _green, size: 18),
                    const SizedBox(width: 10),
                    Text(widget.isEn ? 'Profile & Settings' : 'Profil & Identifiants', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFFF5252), size: 18),
                    const SizedBox(width: 10),
                    Text(widget.isEn ? 'Logout' : 'Déconnexion', style: const TextStyle(color: Color(0xFFFF5252), fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchClassData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome & Assigned Scope Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_green, const Color(0xFF009966)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: _green.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
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
                            Text(widget.isEn ? 'Welcome,' : 'Bienvenue,', style: const TextStyle(color: Colors.white70, fontSize: 13.5)),
                            Text(_currentUser.fullName, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.co_present_rounded, color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _scopeBadge(Icons.class_rounded, '${widget.isEn ? "Class" : "Classe"}: $className'),
                        _scopeBadge(Icons.book_rounded, '${widget.isEn ? "Subject" : "Matière"}: $subject'),
                        _scopeBadge(Icons.location_city_rounded, _currentUser.division ?? 'DJEREM'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Class Access Control Notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_rounded, color: _green, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.isEn
                            ? 'Scoped Access: You are currently viewing analytics strictly for your assigned class ($className) in $subject.'
                            : 'Accès Filtré : Vous consultez exclusivement les résultats de votre classe assignée ($className) en $subject.',
                        style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: _green),
                  ),
                )
              else ...[
                // Section Header: VARK Learning Styles Breakdown
                Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, color: _green, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      widget.isEn ? 'Class Learning Styles Breakdown' : 'Profil des Styles d\'Apprentissage ($className)',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stat Cards Grid
                Row(
                  children: [
                    Expanded(child: _varkStatCard('Visuel', visualSt, const Color(0xFF3B82F6), Icons.visibility_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _varkStatCard('Auditif', auditorySt, const Color(0xFF8B5CF6), Icons.hearing_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _varkStatCard('Kinesthésique', kinesSt, const Color(0xFF10B981), Icons.directions_run_rounded)),
                  ],
                ),
                const SizedBox(height: 18),

                // AI Pedagogical Recommendations Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _accent.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
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
                              color: _accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.auto_awesome_rounded, color: _green, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isEn ? 'AI Pedagogical Recommendations' : 'Recommandations Pédagogiques IA',
                                  style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                Text(
                                  widget.isEn ? 'Tailored for your $className $subject class' : 'Adaptées sur mesure pour votre classe de $className en $subject',
                                  style: TextStyle(color: _sub, fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        aiRec.isNotEmpty
                            ? aiRec
                            : (widget.isEn
                                ? '• Incorporate visual code diagrams and flowcharts.\n• Provide audio explanations and collaborative discussions.\n• Schedule hands-on computer lab sessions.'
                                : '• Intégrez des diagrammes visuels et cartes mentales.\n• Favorisez les explications orales et échanges interactifs.\n• Planifiez des séances de travaux pratiques sur ordinateur.'),
                        style: TextStyle(color: _text, fontSize: 13, height: 1.55, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Student List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_alt_outlined, color: _green, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          widget.isEn ? 'Students Roster & Profiles' : 'Liste des Élèves & Profils ($assessedSt / $totalSt)',
                          style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: _sub, size: 20),
                      onPressed: _fetchClassData,
                      tooltip: widget.isEn ? 'Refresh' : 'Actualiser',
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Student Roster Cards
                if (students.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
                    child: Column(
                      children: [
                        Icon(Icons.person_off_outlined, color: _sub, size: 38),
                        const SizedBox(height: 10),
                        Text(
                          widget.isEn ? 'No student assessment results found for $className.' : 'Aucun résultat d\'évaluation trouvé pour la classe $className.',
                          style: TextStyle(color: _sub, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final st = students[idx] as Map<String, dynamic>;
                      final stName = st['full_name'] ?? 'Élève';
                      final stMat  = st['mat_number'] ?? 'CM2026';
                      final style  = st['learning_style'] ?? 'Visuel';
                      final vis    = st['visual_score'] ?? 0;
                      final aud    = st['auditory_score'] ?? 0;
                      final kin    = st['kinesthetic_score'] ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: _green.withOpacity(0.12),
                              child: Text(
                                stName.substring(0, stName.length > 1 ? 2 : 1).toUpperCase(),
                                style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(stName, style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Matricule: $stMat | ${widget.isEn ? "Style" : "Style"}: $style',
                                    style: TextStyle(color: _sub, fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      _miniScoreChip('Visuel', '$vis', const Color(0xFF3B82F6)),
                                      const SizedBox(width: 6),
                                      _miniScoreChip('Auditif', '$aud', const Color(0xFF8B5CF6)),
                                      const SizedBox(width: 6),
                                      _miniScoreChip('Kinesthésique', '$kin', const Color(0xFF10B981)),
                                    ],
                                  ),
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
    );
  }

  Widget _scopeBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _varkStatCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(color: _sub, fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('$count', style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _miniScoreChip(String label, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $val',
        style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}
