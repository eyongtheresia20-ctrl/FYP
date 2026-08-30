// lib/views/about_view.dart
import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../core/localization.dart';

class AboutView extends StatefulWidget {
  const AboutView({super.key});

  @override
  State<AboutView> createState() => _AboutViewState();
}

class _AboutViewState extends State<AboutView> {
  bool _isDarkMode = true;

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);
  void _changeLanguage(String code) =>
      setState(() => AppLocalization().setLanguage(code));

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLocalization.currentLanguage == 'en';
    final double w = MediaQuery.of(context).size.width;
    final bool isWide = w > 800;

    final Color bg     = _isDarkMode ? const Color(0xFF07090F) : const Color(0xFFF1F5F9);
    final Color nav    = _isDarkMode ? const Color(0xFF0D1421) : const Color(0xFF0F172A);
    final Color text   = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color sub    = _isDarkMode ? Colors.white60 : const Color(0xFF475569);
    final Color cardBg = _isDarkMode ? const Color(0xFF111827) : Colors.white;
    final Color cardBd = _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFFE2E8F0);
    final Color green  = const Color(0xFF006A4E);
    final Color accent = const Color(0xFF34D399);

    final highlights = [
      {
        'icon': Icons.school_outlined,
        'color': accent,
        'title': isEn ? 'Students' : 'Élèves',
        'desc': isEn
            ? 'Discover your learning profile and get personalised study guidance.'
            : 'Découvrez votre profil et recevez des recommandations personnalisées.',
      },
      {
        'icon': Icons.person_outline_rounded,
        'color': const Color(0xFF60A5FA),
        'title': isEn ? 'Teachers' : 'Enseignants',
        'desc': isEn
            ? 'See how your class learns and adapt your approach for every student.'
            : 'Comprenez votre classe et adaptez votre enseignement à chaque élève.',
      },
      {
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFFA78BFA),
        'title': isEn ? 'Administrators' : 'Administrateurs',
        'desc': isEn
            ? 'Track school performance with data-driven reports and analytics.'
            : 'Suivez les performances avec des rapports et analyses basés sur les données.',
      },
    ];

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: Container(
          decoration: BoxDecoration(
            color: nav,
            border: Border(
              bottom: BorderSide(
                color: _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFF1E293B),
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const AppLogo(size: 46, showGlow: false),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalization.translate('about_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                      color: _isDarkMode ? const Color(0xFFFCD116) : Colors.white70,
                    ),
                    onPressed: _toggleTheme,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [_langBtn('EN', isEn), _langBtn('FR', !isEn)],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? w * 0.10 : 28,
                vertical: isWide ? 68 : 48,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode
                      ? [const Color(0xFF0D1421), const Color(0xFF091A10)]
                      : [const Color(0xFFEAF7F1), const Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn
                                    ? 'Personalised learning\nfor every student.'
                                    : 'Un apprentissage\npersonnalisé pour chaque élève.',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: text,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                isEn
                                    ? 'We use AI to understand how each student learns best — so teachers can teach smarter and schools can perform better.'
                                    : 'Nous utilisons l\'IA pour comprendre comment chaque élève apprend — afin que les enseignants enseignent mieux et que les établissements performent davantage.',
                                style: TextStyle(fontSize: 15, color: sub, height: 1.7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 64),
                        Expanded(
                          flex: 2,
                          child: _heroIllustration(accent, green),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEn
                              ? 'Personalised learning for every student.'
                              : 'Un apprentissage personnalisé pour chaque élève.',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: text,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isEn
                              ? 'We use AI to understand how each student learns best — so teachers can teach smarter and schools can perform better.'
                              : 'Nous utilisons l\'IA pour comprendre comment chaque élève apprend — afin que les enseignants enseignent mieux.',
                          style: TextStyle(fontSize: 14, color: sub, height: 1.7),
                        ),
                      ],
                    ),
            ),

            // Who it's for section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? w * 0.10 : 20,
                vertical: 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Who it\'s for' : 'Pour qui',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: text),
                  ),
                  const SizedBox(height: 20),
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: highlights
                              .map((h) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: _card(h, cardBg, cardBd, text, sub),
                                    ),
                                  ))
                              .toList(),
                        )
                      : Column(
                          children: highlights
                              .map((h) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _card(h, cardBg, cardBd, text, sub),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? w * 0.10 : 20),
              child: Divider(color: cardBd),
            ),

            // Footer (web only)
            if (isWide)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(children: [
                  Text(
                    'Republic of Cameroon  ·  République du Cameroun',
                    style: TextStyle(fontSize: 12, color: sub),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learning Style Tracker  ·  v1.0.0  ·  2025',
                    style: TextStyle(fontSize: 11, color: sub.withOpacity(0.45)),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heroIllustration(Color accent, Color green) {
    return Center(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: green.withOpacity(0.07),
          border: Border.all(color: green.withOpacity(0.18), width: 1.5),
        ),
        child: Center(
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withOpacity(0.12),
            ),
            child: Center(
              child: Icon(Icons.school_outlined, size: 60, color: accent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(Map<String, dynamic> h, Color cardBg, Color cardBd, Color text, Color sub) {
    final color = h['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(h['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(
            h['title'] as String,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: text),
          ),
          const SizedBox(height: 8),
          Text(
            h['desc'] as String,
            style: TextStyle(fontSize: 13, color: sub, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String lang, bool selected) => GestureDetector(
        onTap: () => _changeLanguage(lang.toLowerCase()),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF006A4E) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            lang,
            style: TextStyle(
              color: selected ? Colors.white : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      );
}
