import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../dashboards/student_dashboard.dart';
import '../dashboards/teacher_dashboard.dart';
import '../dashboards/principal_dashboard.dart';
import '../dashboards/delegate_dashboard.dart';
import '../dashboards/admin_dashboard.dart';

class ActivationView extends StatefulWidget {
  final bool isDarkMode;
  final bool isEn;
  const ActivationView({super.key, required this.isDarkMode, required this.isEn});

  @override
  State<ActivationView> createState() => _ActivationViewState();
}

class _ActivationViewState extends State<ActivationView> {
  int _step = 0; // 0=matricule, 1=confirm, 2=set credentials
  bool _loading = false;
  String? _error;

  final _matriculeCtrl    = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  final _confirmPassCtrl  = TextEditingController();
  final _securityCtrl     = TextEditingController();

  Map<String, dynamic>? _foundUser;

  bool _showPass    = false;
  bool _showConfirm = false;
  bool _showPin     = false;

  Color get _green  => const Color(0xFF006A4E);
  Color get _accent => const Color(0xFF34D399);
  Color get _bg     => widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
  Color get _text   => widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => widget.isDarkMode ? Colors.white60 : const Color(0xFF475569);
  Color get _fill   => widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  Color get _border => widget.isDarkMode ? const Color(0x33FFFFFF) : const Color(0xFFE2E8F0);

  bool get _isEn => widget.isEn;

  Future<void> _checkMatricule() async {
    final m = _matriculeCtrl.text.trim();
    if (m.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AuthService.checkMatricule(m);
      if (result['already_activated'] == true) {
        setState(() {
          _error = _isEn
              ? 'This account is already activated. Please Sign In instead.'
              : 'Ce compte est déjà activé. Veuillez vous connecter.';
          _loading = false;
        });
        return;
      }
      setState(() { _foundUser = result; _step = 1; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _activate() async {
    if (_passwordCtrl.text != _confirmPassCtrl.text) {
      setState(() { _error = _isEn ? 'Passwords do not match.' : 'Les mots de passe ne correspondent pas.'; });
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() { _error = _isEn ? 'Password must be at least 6 characters.' : 'Au moins 6 caractères.'; });
      return;
    }
    if (_securityCtrl.text.trim().length < 4) {
      setState(() { _error = _isEn ? 'Security code must be at least 4 characters.' : 'Code de sécurité : au moins 4 caractères.'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.activateAccount(
        matricule:    _matriculeCtrl.text.trim(),
        password:     _passwordCtrl.text,
        securityCode: _securityCtrl.text.trim(),
      );
      if (mounted) _routeToDashboard(user);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _routeToDashboard(UserModel user) {
    Widget dashboard;
    if (user.isStudent)            dashboard = StudentDashboard(user: user, isDarkMode: widget.isDarkMode, isEn: _isEn);
    else if (user.isTeacher)       dashboard = TeacherDashboard(user: user, isDarkMode: widget.isDarkMode, isEn: _isEn);
    else if (user.isPrincipal)     dashboard = PrincipalDashboard(user: user, isDarkMode: widget.isDarkMode, isEn: _isEn);
    else if (user.isDivisionalDelegate || user.isRegionalDelegate)
                                   dashboard = DelegateDashboard(user: user, isDarkMode: widget.isDarkMode, isEn: _isEn);
    else                           dashboard = AdminDashboard(user: user, isDarkMode: widget.isDarkMode, isEn: _isEn);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: _text),
        title: Text(
          _isEn ? 'Account Activation' : 'Activation de Compte',
          style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF162032) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon Header Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _green.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: _accent.withOpacity(0.3)),
                      ),
                      child: Icon(Icons.flash_on_rounded, color: _accent, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Step indicator
                  _StepIndicator(step: _step, isEn: _isEn, green: _green, sub: _sub),
                  const SizedBox(height: 24),

                  // Error
                  if (_error != null) _ErrorBanner(message: _error!),
                  if (_error != null) const SizedBox(height: 16),

                  // Steps
                  if (_step == 0) _buildStep0(),
                  if (_step == 1) _buildStep1(),
                  if (_step == 2) _buildStep2(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Step 0: Enter Matricule ─────────────────────────────────
  Widget _buildStep0() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_isEn ? 'Enter your Matricule' : 'Entrez votre matricule',
          style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(_isEn ? 'Your matricule or staff ID assigned by MINESEC.'
                 : 'Votre matricule ou identifiant attribué par le MINESEC.',
          style: TextStyle(color: _sub, fontSize: 13)),
      const SizedBox(height: 24),
      _field(
        controller: _matriculeCtrl,
        hint: _isEn ? 'e.g. CM12345 or 6XXXXXXXX' : 'ex. CM12345 ou 6XXXXXXXX',
        icon: Icons.badge_outlined,
        keyboardType: TextInputType.text,
      ),
      const SizedBox(height: 20),
      _primaryButton(
        label: _isEn ? 'Verify Matricule' : 'Vérifier le Matricule',
        onTap: _checkMatricule,
      ),
    ],
  );

  // ── Step 1: Confirm Identity ────────────────────────────────
  Widget _buildStep1() {
    final u = _foundUser!;
    final roleLabel = _roleLabel(u['role'] as String? ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_isEn ? 'Confirm your Identity' : 'Confirmez votre identité',
            style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _InfoCard(isDarkMode: widget.isDarkMode, green: _green, accent: _accent, children: [
          _InfoRow(label: _isEn ? 'Name'   : 'Nom',   value: u['full_name']   ?? '—', sub: _sub, text: _text),
          _InfoRow(label: _isEn ? 'Role'   : 'Rôle',  value: roleLabel,               sub: _sub, text: _text),
          if (u['school_name'] != null) _InfoRow(label: _isEn ? 'School' : 'École', value: u['school_name'],   sub: _sub, text: _text),
          if (u['class_name']  != null) _InfoRow(label: _isEn ? 'Class'  : 'Classe', value: u['class_name'],  sub: _sub, text: _text),
          if (u['subject']     != null) _InfoRow(label: _isEn ? 'Subject': 'Matière', value: u['subject'],    sub: _sub, text: _text),
          if (u['region']      != null) _InfoRow(label: _isEn ? 'Region' : 'Région', value: u['region'],      sub: _sub, text: _text),
        ]),
        const SizedBox(height: 24),
        Text(_isEn ? 'Is this you?' : 'Est-ce bien vous ?',
            style: TextStyle(color: _sub, fontSize: 13)),
        const SizedBox(height: 12),
        _primaryButton(label: _isEn ? 'Yes, Continue' : 'Oui, Continuer',
            onTap: () => setState(() { _step = 2; _error = null; })),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: _sub,
            side: BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => setState(() { _step = 0; _foundUser = null; _error = null; }),
          child: Text(_isEn ? 'That\'s not me' : 'Ce n\'est pas moi'),
        ),
      ],
    );
  }

  // ── Step 2: Set Password + Security Code ─────────────────────
  Widget _buildStep2() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(_isEn ? 'Set your Credentials' : 'Définissez vos identifiants',
          style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(_isEn ? 'Choose a password and a 4–6 digit security PIN.'
                 : 'Choisissez un mot de passe et un code PIN de 4 à 6 chiffres.',
          style: TextStyle(color: _sub, fontSize: 13)),
      const SizedBox(height: 24),

      Text(_isEn ? 'Password' : 'Mot de passe',
          style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      _field(controller: _passwordCtrl, hint: '••••••••', icon: Icons.lock_outline,
          obscure: !_showPass,
          suffix: IconButton(icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, size: 18, color: _sub),
              onPressed: () => setState(() => _showPass = !_showPass))),
      const SizedBox(height: 16),

      Text(_isEn ? 'Confirm Password' : 'Confirmer le mot de passe',
          style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      _field(controller: _confirmPassCtrl, hint: '••••••••', icon: Icons.lock_outline,
          obscure: !_showConfirm,
          suffix: IconButton(icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, size: 18, color: _sub),
              onPressed: () => setState(() => _showConfirm = !_showConfirm))),
      const SizedBox(height: 16),

      Text(_isEn ? 'Security Code (symbols, numbers, letters)' : 'Code de sécurité (symboles, chiffres, lettres)',
          style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      _field(controller: _securityCtrl, hint: 'e.g. SEC#2026', icon: Icons.shield_outlined,
          obscure: !_showPin,
          suffix: IconButton(icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, size: 18, color: _sub),
              onPressed: () => setState(() => _showPin = !_showPin))),
      const SizedBox(height: 28),

      _loading
          ? const Center(child: CircularProgressIndicator())
          : _primaryButton(label: _isEn ? 'Activate Account' : 'Activer le Compte', onTap: _activate),
    ],
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: _text, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _sub.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: _fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent, width: 1.8)),
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _loading ? null : onTap,
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'student':              return _isEn ? 'Student'              : 'Élève';
      case 'teacher':              return _isEn ? 'Teacher'              : 'Enseignant(e)';
      case 'principal':            return _isEn ? 'Principal'            : 'Proviseur';
      case 'divisional_delegate':  return _isEn ? 'Divisional Delegate'  : 'Délégué Départemental';
      case 'regional_delegate':    return _isEn ? 'Regional Delegate'    : 'Délégué Régional';
      case 'admin':                return _isEn ? 'MINESEC Administrator' : 'Administrateur MINESEC';
      default:                     return role;
    }
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  final bool isEn;
  final Color green;
  final Color sub;
  const _StepIndicator({required this.step, required this.isEn, required this.green, required this.sub});

  @override
  Widget build(BuildContext context) {
    final labels = isEn
        ? ['Matricule', 'Confirm', 'Credentials']
        : ['Matricule', 'Confirmer', 'Identifiants'];
    return Row(
      children: List.generate(3, (i) {
        final active = i <= step;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: Container(height: 3, color: active ? green : sub.withOpacity(0.2))),
              if (i < 2) const SizedBox(width: 4),
            ],
          ),
        );
      })
        ..addAll([]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFF4444).withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFF4444).withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF4444), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: Color(0xFFFF4444), fontSize: 13))),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final bool isDarkMode;
  final Color green;
  final Color accent;
  final List<Widget> children;
  const _InfoCard({required this.isDarkMode, required this.green, required this.accent, required this.children});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF0FDF8),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: green.withOpacity(0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color sub;
  final Color text;
  const _InfoRow({required this.label, required this.value, required this.sub, required this.text});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600))),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.w700))),
      ],
    ),
  );
}
