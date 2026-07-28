import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class StudentDashboard extends StatelessWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;
  const StudentDashboard({super.key, required this.user, required this.isDarkMode, required this.isEn});

  Color get _green  => const Color(0xFF006A4E);
  Color get _accent => const Color(0xFF34D399);
  Color get _bg     => isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get _card   => isDarkMode ? const Color(0xFF1E293B) : Colors.white;
  Color get _text   => isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => isDarkMode ? Colors.white60 : const Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.school_outlined, color: Colors.white, size: 20)),
            const SizedBox(width: 10),
            Text('EDU PROFILE', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: _sub),
            tooltip: isEn ? 'Sign Out' : 'Déconnexion',
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_green, const Color(0xFF009966)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: _green.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isEn ? 'Welcome,' : 'Bienvenue,',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(isEn ? 'Student' : 'Élève', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Take Assessment
            _DashCard(card: _card, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Icon(Icons.quiz_outlined, color: _accent, size: 22),
                const SizedBox(width: 10),
                Text(isEn ? 'VARK Assessment' : 'Évaluation VARK',
                    style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
              const SizedBox(height: 8),
              Text(isEn ? 'Discover your learning style by completing the VARK questionnaire.'
                        : 'Découvrez votre style d\'apprentissage en complétant le questionnaire VARK.',
                  style: TextStyle(color: _sub, fontSize: 13)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(isEn ? 'Start Assessment' : 'Commencer l\'évaluation',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ])),
            const SizedBox(height: 16),

            // My Result placeholder
            _DashCard(card: _card, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.bar_chart_rounded, color: _accent, size: 22),
                const SizedBox(width: 10),
                Text(isEn ? 'My Result' : 'Mon Résultat',
                    style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
              const SizedBox(height: 16),
              Center(child: Column(children: [
                Icon(Icons.hourglass_empty_rounded, color: _sub, size: 40),
                const SizedBox(height: 10),
                Text(isEn ? 'No assessment completed yet.' : 'Aucune évaluation complétée.',
                    style: TextStyle(color: _sub, fontSize: 13)),
              ])),
            ])),
          ],
        ),
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final Color card;
  final Widget child;
  const _DashCard({required this.card, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))]),
    child: child,
  );
}
