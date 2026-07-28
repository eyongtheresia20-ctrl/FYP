import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../dashboards/student_dashboard.dart';
import '../dashboards/teacher_dashboard.dart';
import '../dashboards/principal_dashboard.dart';
import '../dashboards/delegate_dashboard.dart';
import '../dashboards/admin_dashboard.dart';

class LoginView extends StatefulWidget {
  final bool isDarkMode;
  final bool isEn;
  const LoginView({super.key, required this.isDarkMode, required this.isEn});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _matriculeCtrl = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _pinCtrl       = TextEditingController();

  bool _loading     = false;
  bool _showPass    = false;
  bool _showPin     = false;
  String? _error;

  Color get _green  => const Color(0xFF006A4E);
  Color get _accent => const Color(0xFF34D399);
  Color get _bg     => widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white;
  Color get _text   => widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => widget.isDarkMode ? Colors.white60 : const Color(0xFF475569);
  Color get _fill   => widget.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
  Color get _border => widget.isDarkMode ? const Color(0x33FFFFFF) : const Color(0xFFE2E8F0);
  bool  get _isEn   => widget.isEn;

  Future<void> _login() async {
    final m = _matriculeCtrl.text.trim();
    final p = _passwordCtrl.text;
    final s = _pinCtrl.text.trim();
    if (m.isEmpty || p.isEmpty || s.isEmpty) {
      setState(() => _error = _isEn ? 'All fields are required.' : 'Tous les champs sont obligatoires.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.login(matricule: m, password: p, securityCode: s);
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

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => dashboard));
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
          _isEn ? 'Sign In' : 'Connexion',
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
                      child: Icon(Icons.lock_rounded, color: _accent, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Text
                  Center(
                    child: Text(
                      _isEn ? 'Welcome Back' : 'Bon Retour',
                      style: TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      _isEn ? 'Sign in to access your dashboard' : 'Connectez-vous pour accéder à votre tableau de bord',
                      style: TextStyle(color: _sub, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error
                  if (_error != null) ...[
                    Container(
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
                          Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF4444), fontSize: 13))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Matricule
                  _label(_isEn ? 'MATRICULE / PHONE' : 'MATRICULE / TÉLÉPHONE'),
                  const SizedBox(height: 8),
                  _field(_matriculeCtrl, _isEn ? 'e.g. CM12345 or 6XXXXXXXX' : 'ex. CM12345 ou 6XXXXXXXX', Icons.badge_outlined),
                  const SizedBox(height: 16),

                  // Password
                  _label(_isEn ? 'PASSWORD' : 'MOT DE PASSE'),
                  const SizedBox(height: 8),
                  _field(_passwordCtrl, '••••••••', Icons.lock_outline,
                      obscure: !_showPass,
                      suffix: IconButton(
                        icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility, size: 18, color: _sub),
                        onPressed: () => setState(() => _showPass = !_showPass),
                      )),
                  const SizedBox(height: 16),

                  // Security PIN
                  _label(_isEn ? 'SECURITY PIN' : 'CODE PIN DE SÉCURITÉ'),
                  const SizedBox(height: 8),
                  _field(_pinCtrl, '1234', Icons.shield_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                      obscure: !_showPin,
                      suffix: IconButton(
                        icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, size: 18, color: _sub),
                        onPressed: () => setState(() => _showPin = !_showPin),
                      )),
                  const SizedBox(height: 28),

                  // Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_isEn ? 'Sign In' : 'Se Connecter',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: TextStyle(color: _sub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1));

  Widget _field(TextEditingController ctrl, String hint, IconData icon, {
    bool obscure = false, Widget? suffix,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: ctrl,
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
}
