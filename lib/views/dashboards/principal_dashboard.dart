import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';

class PrincipalDashboard extends StatelessWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;
  const PrincipalDashboard({super.key, required this.user, required this.isDarkMode, required this.isEn});

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
        title: Text('EDU PROFILE', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: _sub),
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
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_green, const Color(0xFF009966)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEn ? 'Welcome,' : 'Bienvenue,', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  Text(user.fullName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(isEn ? 'Principal' : 'Proviseur / Directeur', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.domain_rounded, color: _accent, size: 22),
                      const SizedBox(width: 10),
                      Text(isEn ? 'School Learning Analytics' : 'Analyses de l\'Établissement', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.analytics_outlined, color: _sub, size: 40),
                        const SizedBox(height: 10),
                        Text(
                          isEn ? 'Overview across all classes will appear here.' : 'La vue d\'ensemble de toutes les classes apparaîtra ici.',
                          style: TextStyle(color: _sub, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
}
