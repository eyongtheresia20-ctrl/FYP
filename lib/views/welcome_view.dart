// lib/views/welcome_view.dart
import 'package:flutter/material.dart';
import '../core/localization.dart';
import 'auth/activation_view.dart';
import 'auth/login_view.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _isDarkMode = true; // Theme mode state
  String _currentPage = 'home'; // 'home' | 'about' | 'help' | 'settings'

  void _changeLanguage(String langCode) {
    setState(() {
      AppLocalization().setLanguage(langCode);
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLocalization.currentLanguage == 'en';
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;

    // Dynamic Theme Colors
    final Color bgColor = _isDarkMode ? const Color(0xFF07090F) : const Color(0xFFF1F5F9);
    final Color navBgColor = _isDarkMode ? const Color(0xFF0D1421) : const Color(0xFF0F172A);
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subTextColor = _isDarkMode ? Colors.white60 : const Color(0xFF475569);
    final Color cardBgColor = _isDarkMode
        ? const Color(0x0EFFFFFF)
        : Colors.white;
    final Color cardBorderColor = _isDarkMode
        ? const Color(0x28FFFFFF)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildNavBar(context, isEn, isWide, navBgColor),

      // ── Mobile bottom navigation bar ──────────────────────────────────────
      bottomNavigationBar: isWide
          ? null
          : _buildBottomNav(isEn, navBgColor),

      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          image: _isDarkMode
              ? const DecorationImage(
                  image: AssetImage('assets/images/edu_background.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Color(0xF4050810),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(
          children: [
            // Ambient background glows
            if (_isDarkMode) ...[
              Positioned(
                left: screenWidth * 0.05,
                top: 80,
                child: _glowBlob(const Color(0xFF006A4E), 380, 0.08),
              ),
              Positioned(
                right: screenWidth * 0.05,
                bottom: 60,
                child: _glowBlob(const Color(0xFFFCD116), 280, 0.06),
              ),
            ],

            // Main scrollable content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: _currentPage == 'about'
                  ? _buildAboutInline(
                      key: const ValueKey('about'),
                      isEn: isEn,
                      isWide: isWide,
                      textColor: textColor,
                      subTextColor: subTextColor,
                      cardBgColor: cardBgColor,
                      cardBorderColor: cardBorderColor,
                    )
                  : _currentPage == 'help'
                      ? _buildHelpInline(
                          key: const ValueKey('help'),
                          isEn: isEn,
                          isWide: isWide,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          cardBgColor: cardBgColor,
                          cardBorderColor: cardBorderColor,
                        )
                      : _currentPage == 'settings'
                          ? _buildSettingsInline(
                              key: const ValueKey('settings'),
                              isEn: isEn,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              cardBgColor: cardBgColor,
                              cardBorderColor: cardBorderColor,
                            )
                          : FadeTransition(
                              key: const ValueKey('home'),
                              opacity: _fadeAnim,
                              child: SlideTransition(
                                position: _slideAnim,
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _buildHeroSection(context, isEn, isWide, textColor, subTextColor),
                                      _buildBriefSection(isEn, isWide, textColor, subTextColor, cardBgColor, cardBorderColor),
                                      _buildFooter(isEn, subTextColor),
                                    ],
                                  ),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile Bottom Navigation Bar ────────────────────────────────────────────
  Widget _buildBottomNav(bool isEn, Color navBgColor) {
    final Color activeColor = const Color(0xFF34D399);
    final Color idleColor   = Colors.white38;
    final Color bgColor     = navBgColor;

    final items = [
      {'page': 'home',     'icon': Icons.home_outlined,     'activeIcon': Icons.home_rounded,         'label': isEn ? 'Home'     : 'Accueil'},
      {'page': 'about',    'icon': Icons.info_outline,      'activeIcon': Icons.info_rounded,          'label': isEn ? 'About'    : 'À propos'},
      {'page': 'help',     'icon': Icons.help_outline,      'activeIcon': Icons.help_rounded,          'label': isEn ? 'Help'     : 'Aide'},
      {'page': 'settings', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings_rounded,      'label': isEn ? 'Settings' : 'Paramètres'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: Colors.white12, width: 0.8)),
        boxShadow: [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.map((item) {
              final bool active = _currentPage == item['page'];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _currentPage = item['page'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: active ? activeColor : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active
                              ? item['activeIcon'] as IconData
                              : item['icon'] as IconData,
                          color: active ? activeColor : idleColor,
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: active ? activeColor : idleColor,
                            fontSize: 10.5,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─── NAVBAR ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildNavBar(
      BuildContext context, bool isEn, bool isWide, Color navBgColor) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(68),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            bottom: BorderSide(
              color: _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFF1E293B),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16),
            child: Row(
              children: [
                // 1. LEFT SECTION (Logo + Title)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWide) ...[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/minesec_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EDU PROFILE',
                          style: TextStyle(
                            color: Color(0xFFFCD116),
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          isEn
                              ? 'Learning Style Tracker'
                              : 'Traqueur de Style d\'Apprentissage',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // 2. MIDDLE SECTION (Nav Links)
                if (isWide) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _navLink(isEn ? 'Home' : 'Accueil', Icons.home_outlined,
                          _currentPage == 'home',
                          onPressed: () => setState(() => _currentPage = 'home')),
                      const SizedBox(width: 8),
                      _navLink(isEn ? 'About' : 'À propos', Icons.info_outline,
                          _currentPage == 'about',
                          onPressed: () => setState(() => _currentPage = 'about')),
                      const SizedBox(width: 8),
                      _navLink(isEn ? 'Help' : 'Aide', Icons.help_outline,
                          _currentPage == 'help',
                          onPressed: () => setState(() => _currentPage = 'help')),
                    ],
                  ),
                  const Spacer(),
                ],

                // 3. FAR RIGHT END SECTION (Theme + Language + Sign In)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWide) ...[
                      // Theme Switch
                      Tooltip(
                        message: _isDarkMode
                            ? (isEn ? 'Switch to Light Mode' : 'Passer au Mode Clair')
                            : (isEn ? 'Switch to Dark Mode' : 'Passer au Mode Sombre'),
                        child: InkWell(
                          onTap: _toggleTheme,
                          borderRadius: BorderRadius.circular(30),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1E293B),
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                              color: _isDarkMode ? const Color(0xFFFCD116) : Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Language Switch
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _topLangBtn('EN', isEn),
                            _topLangBtn('FR', !isEn),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                    ],

                    // Hi + Sign In Button (FAR RIGHT END)
                    _buildSignInArea(context, isEn),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topLangBtn(String lang, bool selected) {
    return GestureDetector(
      onTap: () => _changeLanguage(lang.toLowerCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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

  Widget _navLink(String label, IconData icon, bool active, {VoidCallback? onPressed}) {
    return _HoverNavLink(
      label: label,
      icon: icon,
      active: active,
      onPressed: onPressed,
    );
  }



  // ── Profile Icon & Auth Dropdown Menu ─────────────────────────────────────────
  Widget _buildSignInArea(BuildContext context, bool isEn) {
    final Color green = const Color(0xFF006A4E);
    final Color accent = const Color(0xFF34D399);

    return PopupMenuButton<String>(
      tooltip: isEn ? 'Account Menu' : 'Menu Compte',
      offset: const Offset(0, 48),
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.4),
      color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: _isDarkMode ? const Color(0x33FFFFFF) : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      onSelected: (value) {
        if (value == 'login') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LoginView(
                isDarkMode: _isDarkMode,
                isEn: isEn,
              ),
            ),
          );
        } else if (value == 'activate') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ActivationView(
                isDarkMode: _isDarkMode,
                isEn: isEn,
              ),
            ),
          );
        }
      },
      itemBuilder: (ctx) => [
        // Option 1: Sign In
        PopupMenuItem<String>(
          value: 'login',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.login_rounded, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEn ? 'Sign In' : 'Connexion',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isEn ? 'Already activated account' : 'Compte déjà activé',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        // Option 2: Activate Account
        PopupMenuItem<String>(
          value: 'activate',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.flash_on_rounded, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEn ? 'Activate Account' : 'Activer le Compte',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isEn ? 'First-time setup with matricule' : 'Première fois avec matricule',
                    style: TextStyle(
                      color: _isDarkMode ? Colors.white54 : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF006A4E), Color(0xFF009966)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006A4E).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              isEn ? 'Account' : 'Compte',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  // ── Clean Minimal Sign In Dialog ───────────────────────────────────────────
  void _showSignInDialog(BuildContext context, bool isEn) {
    final TextEditingController idController = TextEditingController();
    final Color green = const Color(0xFF006A4E);
    final Color accent = const Color(0xFF34D399);
    final Color dialogBg = _isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color subColor = _isDarkMode ? Colors.white60 : const Color(0xFF475569);
    final Color borderColor = _isDarkMode ? const Color(0x33FFFFFF) : const Color(0xFFE2E8F0);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
          decoration: BoxDecoration(
            color: dialogBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Close button top-right
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Icon(Icons.close_rounded, color: subColor, size: 20),
                ),
              ),
              const SizedBox(height: 8),

              // Input field
              TextField(
                controller: idController,
                style: TextStyle(color: textColor, fontSize: 14.5, fontWeight: FontWeight.w500),
                keyboardType: TextInputType.text,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: isEn ? 'Matricule or Phone Number' : 'Matricule ou Numéro de téléphone',
                  hintStyle: TextStyle(color: subColor, fontSize: 13.5),
                  prefixIcon: Icon(Icons.badge_outlined, color: accent, size: 20),
                  filled: true,
                  fillColor: _isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: accent, width: 1.8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sign In button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final id = idController.text.trim();
                    if (id.isEmpty) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEn ? 'Signing in as: $id' : 'Connexion : $id'),
                        backgroundColor: green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text(
                    isEn ? 'Sign In' : 'Connexion',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HERO SECTION ────────────────────────────────────────────────────────────
  Widget _buildHeroSection(
      BuildContext context, bool isEn, bool isWide, Color textColor, Color subTextColor) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: isWide ? 60 : 36),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _heroText(isEn, textColor, subTextColor)),
                const SizedBox(width: 60),
                _buildExecutiveOverviewCard(isEn),
              ],
            )
          : Column(
              children: [
                _heroText(isEn, textColor, subTextColor),
                const SizedBox(height: 36),
                _buildExecutiveOverviewCard(isEn),
              ],
            ),
    );
  }

  Widget _heroText(bool isEn, Color textColor, Color subTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          isEn
              ? 'Shaping the Future\nof Learning in Cameroon'
              : 'Façonner l\'Avenir\nde l\'Éducation au Cameroun',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: textColor,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isEn
              ? 'An intelligent learning style assessment system built for educational excellence. Students discover their unique learning profiles while educators gain powerful insights to personalize teaching and improve outcomes across Cameroon.'
              : 'Un système intelligent d\'évaluation des styles d\'apprentissage conçu pour l\'excellence éducative. Les élèves découvrent leurs profils d\'apprentissage uniques tandis que les enseignants obtiennent des insights pour personnaliser l\'enseignement au Cameroun.',
          style: TextStyle(
            color: subTextColor,
            fontSize: 15,
            height: 1.75,
          ),
        ),
      ],
    );
  }


  Widget _buildExecutiveOverviewCard(bool isEn) {
    final styles = [
      {
        'icon': Icons.headphones_rounded,
        'title': isEn ? 'Auditory Style' : 'Style Auditif',
        'desc': isEn ? 'Lectures, Audio & Discussions' : 'Cours, Écoute & Débats',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Icons.visibility_rounded,
        'title': isEn ? 'Visual Style' : 'Style Visuel',
        'desc': isEn ? 'Diagrams & Mind Maps' : 'Schémas & Cartes Mentales',
        'color': const Color(0xFF10B981),
      },
      {
        'icon': Icons.touch_app_rounded,
        'title': isEn ? 'Kinesthetic Style' : 'Style Kinesthésique',
        'desc': isEn ? 'Hands-on Science Labs' : 'Pratique & Expérimentation',
        'color': const Color(0xFFF59E0B),
      },
      {
        'icon': Icons.menu_book_rounded,
        'title': isEn ? 'Read / Write Style' : 'Style Lecture / Écriture',
        'desc': isEn ? 'Textbooks & Note-Taking' : 'Manuels & Prise de Notes',
        'color': const Color(0xFFE11D48),
      },
    ];

    return Container(
      width: 370,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isDarkMode ? const Color(0x35FFFFFF) : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF006A4E).withOpacity(_isDarkMode ? 0.25 : 0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
  
          Text(
            isEn ? '4 Core Learning Modalities' : '4 Modalités d\'Apprentissage',
            style: TextStyle(
              color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 18),
          Column(
            children: styles.map((item) {
              final color = item['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isDarkMode
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white12
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item['icon'] as IconData, color: color, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          Text(
                            item['desc'] as String,
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white54 : const Color(0xFF64748B),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_outline_rounded, color: color, size: 15),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── BRIEF SECTION ───────────────────────────────────────────────────────────
  Widget _buildBriefSection(bool isEn, bool isWide, Color textColor,
      Color subTextColor, Color cardBgColor, Color cardBorderColor) {
    final items = isEn
        ? [
            _briefItem(
                Icons.psychology_outlined,
                'Learning Style Assessment',
                'Students complete an AI-guided questionnaire that identifies their dominant learning style — visual, auditory, or kinesthetic.',
                cardBgColor,
                cardBorderColor),
            _briefItem(
                Icons.analytics_outlined,
                'Personalized Insights',
                'Educators receive data-driven recommendations to tailor their teaching methods and improve student outcomes.',
                cardBgColor,
                cardBorderColor),
            _briefItem(
                Icons.bar_chart_outlined,
                'National Analytics',
                'Delegates and ministry officials access aggregated statistics to guide education policy across all regions of Cameroon.',
                cardBgColor,
                cardBorderColor),
          ]
        : [
            _briefItem(
                Icons.psychology_outlined,
                'Évaluation du Style d\'Apprentissage',
                'Les élèves complètent un questionnaire guidé par IA qui identifie leur style dominant — visuel, auditif ou kinesthésique.',
                cardBgColor,
                cardBorderColor),
            _briefItem(
                Icons.analytics_outlined,
                'Perspectives Personnalisées',
                'Les enseignants reçoivent des recommandations basées sur les données pour adapter leur pédagogie et améliorer les résultats.',
                cardBgColor,
                cardBorderColor),
            _briefItem(
                Icons.bar_chart_outlined,
                'Analytiques Nationales',
                'Les délégués et responsables ministériels accèdent aux statistiques agrégées pour orienter la politique éducative nationale.',
                cardBgColor,
                cardBorderColor),
          ];

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: 20),
      child: Column(
        children: [
          Text(
            isEn ? 'How It Works' : 'Comment ça Marche',
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? 'A complete ecosystem for educational management'
                : 'Un écosystème complet pour la gestion éducative',
            style: TextStyle(color: subTextColor, fontSize: 14),
          ),
          const SizedBox(height: 36),
          isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map((e) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: e,
                            ),
                          ))
                      .toList(),
                )
              : Column(
                  children: items
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: e,
                          ))
                      .toList()),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _briefItem(IconData icon, String title, String desc, Color cardBg, Color cardBorder) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder),
        boxShadow: _isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF006A4E).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF006A4E), size: 24),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: TextStyle(
                  color: _isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),
          Text(desc,
              style: TextStyle(
                  color: _isDarkMode ? Colors.white54 : const Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.6)),
        ],
      ),
    );
  }


  // ─── INLINE ABOUT PAGE ───────────────────────────────────────────────────────
  Widget _buildAboutInline({
    Key? key,
    required bool isEn,
    required bool isWide,
    required Color textColor,
    required Color subTextColor,
    required Color cardBgColor,
    required Color cardBorderColor,
  }) {
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

    return SizedBox(
      key: key,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 28,
                vertical: isWide ? 60 : 44,
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
                                  color: textColor,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                isEn
                                    ? 'We use learning analytics to understand how each student learns best — so teachers can teach smarter and schools can perform better.'
                                    : 'Nous utilisons des analyses d\'apprentissage pour comprendre comment chaque élève apprend — afin que les enseignants enseignent mieux.',
                                style: TextStyle(fontSize: 15, color: subTextColor, height: 1.7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 64),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: green.withOpacity(0.07),
                                border: Border.all(color: green.withOpacity(0.18), width: 1.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: green.withOpacity(0.12),
                                  ),
                                  child: Center(
                                    child: Icon(Icons.school_outlined, size: 56, color: accent),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                            color: textColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          isEn
                              ? 'We use learning analytics to understand how each student learns best.'
                              : 'Nous utilisons des analyses d\'apprentissage pour comprendre comment chaque élève apprend.',
                          style: TextStyle(fontSize: 14, color: subTextColor, height: 1.7),
                        ),
                      ],
                    ),
            ),

            // Who it's for
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 20, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Who it\'s for' : 'Pour qui',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 20),
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: highlights
                              .map((h) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: _aboutCard(h, cardBgColor, cardBorderColor, textColor, subTextColor),
                                    ),
                                  ))
                              .toList(),
                        )
                      : Column(
                          children: highlights
                              .map((h) => Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _aboutCard(h, cardBgColor, cardBorderColor, textColor, subTextColor),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),

            _buildFooter(isEn, subTextColor),
          ],
        ),
      ),
    );
  }

  Widget _aboutCard(Map<String, dynamic> h, Color cardBg, Color cardBd, Color textColor, Color subTextColor) {
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            h['desc'] as String,
            style: TextStyle(fontSize: 13, color: subTextColor, height: 1.55),
          ),
        ],
      ),
    );
  }

  // ─── INLINE HELP PAGE ────────────────────────────────────────────────────────
  Widget _buildHelpInline({
    Key? key,
    required bool isEn,
    required bool isWide,
    required Color textColor,
    required Color subTextColor,
    required Color cardBgColor,
    required Color cardBorderColor,
  }) {
    final Color green  = const Color(0xFF006A4E);
    final Color accent = const Color(0xFF34D399);

    final faqs = isEn
        ? [
            {'q': 'How do I take the learning style assessment?', 'a': 'Select your role from the Home page, choose your portal, enter your identifier, and answer the profiling questions regarding your study preferences.'},
            {'q': 'Can I retake the assessment?', 'a': 'Yes, once per academic term to track changes in preferred learning styles over time.'},
            {'q': 'How do teachers access classroom analytics?', 'a': 'Log into the Teacher Portal with your school credentials. Your dashboard displays real-time charts comparing learning profiles for your classes.'},
            {'q': 'Where can I find teaching strategies?', 'a': 'Click on any profile card in your classroom analytics dashboard to expand recommended teaching techniques.'},
            {'q': 'How do administrators manage user accounts?', 'a': 'Administrators can issue activation codes, reset access credentials, and monitor school-wide participation through the Admin Portal.'},
            {'q': 'How is student data protected?', 'a': 'All platform data is encrypted and handled in compliance with national educational privacy standards.'},
          ]
        : [
            {'q': 'Comment passer l\'évaluation des styles d\'apprentissage ?', 'a': 'Sélectionnez votre rôle sur la page d\'accueil, choisissez votre portail, entrez votre identifiant et répondez aux questions sur vos préférences d\'étude.'},
            {'q': 'Puis-je repasser l\'évaluation de profil ?', 'a': 'Oui, les élèves peuvent repasser l\'évaluation une fois par trimestre.'},
            {'q': 'Comment les enseignants accèdent-ils aux analyses de classe ?', 'a': 'Connectez-vous au Portail Enseignant. Votre tableau de bord affiche des graphiques en temps réel comparant les profils d\'apprentissage.'},
            {'q': 'Où trouver des stratégies pédagogiques adaptées ?', 'a': 'Cliquez sur n\'importe quelle carte de profil dans le tableau de bord pour afficher des techniques d\'enseignement recommandées.'},
            {'q': 'Comment les administrateurs gèrent-ils les comptes ?', 'a': 'Les administrateurs peuvent générer des codes d\'activation, réinitialiser des identifiants et suivre la participation depuis le Portail Admin.'},
            {'q': 'Comment les données des élèves sont-elles protégées ?', 'a': 'Toutes les données sont cryptées et gérées conformément aux normes nationales de protection.'},
          ];

    return SizedBox(
      key: key,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero banner
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 80 : 24,
                vertical: isWide ? 52 : 38,
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
              child: Column(
                children: [
                  Text(
                    isEn ? 'How can we help you?' : 'Comment pouvons-nous vous aider ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isWide ? 34 : 26,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEn
                        ? 'Find quick answers to common questions below.'
                        : 'Trouvez des réponses rapides aux questions courantes ci-dessous.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: subTextColor),
                  ),
                ],
              ),
            ),

            // FAQ list
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Frequently Asked Questions' : 'Foire Aux Questions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      final item = faqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: cardBorderColor),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            iconColor: accent,
                            collapsedIconColor: subTextColor,
                            tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                            title: Text(
                              item['q']!,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item['a']!,
                                    style: TextStyle(fontSize: 13.5, color: subTextColor, height: 1.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 36),

                  // Support card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: green.withOpacity(0.35)),
                    ),
                    child: isWide
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: green.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.support_agent_rounded, color: accent, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEn ? 'Still have questions?' : 'Vous avez d\'autres questions ?',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isEn ? 'Contact our support team for assistance.' : 'Contactez notre équipe de support pour toute assistance.',
                                      style: TextStyle(fontSize: 13, color: subTextColor),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                                onPressed: () {},
                                icon: const Icon(Icons.email_outlined, size: 16),
                                label: Text(isEn ? 'Email Support' : 'Contacter par Email'),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: green.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.support_agent_rounded, color: accent, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isEn ? 'Still have questions?' : 'Vous avez d\'autres questions ?',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                isEn ? 'Contact our support team for assistance.' : 'Contactez notre équipe de support pour toute assistance.',
                                style: TextStyle(fontSize: 13, color: subTextColor),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                ),
                                onPressed: () {},
                                icon: const Icon(Icons.email_outlined, size: 16),
                                label: Text(isEn ? 'Email Support' : 'Contacter par Email'),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            _buildFooter(isEn, subTextColor),
          ],
        ),
      ),
    );
  }

  // ─── INLINE SETTINGS PAGE ────────────────────────────────────────────────────
  Widget _buildSettingsInline({
    Key? key,
    required bool isEn,
    required Color textColor,
    required Color subTextColor,
    required Color cardBgColor,
    required Color cardBorderColor,
  }) {
    final Color green  = const Color(0xFF006A4E);
    final Color accent = const Color(0xFF34D399);

    return SizedBox(
      key: key,
      width: double.infinity,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isDarkMode
                      ? [const Color(0xFF0D1421), const Color(0xFF091A10)]
                      : [const Color(0xFFEAF7F1), const Color(0xFFF1F5F9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings_outlined, color: accent, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        isEn ? 'Settings' : 'Paramètres',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn
                        ? 'Customise your experience'
                        : 'Personnalisez votre expérience',
                    style: TextStyle(fontSize: 13, color: subTextColor),
                  ),
                ],
              ),
            ),

            // Settings cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Appearance section ──────────────────────────────────────
                  Text(
                    isEn ? 'APPEARANCE' : 'APPARENCE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: subTextColor,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dark / Light mode toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _isDarkMode
                                ? Icons.nightlight_round_outlined
                                : Icons.wb_sunny_outlined,
                            color: _isDarkMode ? const Color(0xFF818CF8) : const Color(0xFFFCD116),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEn ? 'Display Theme' : 'Thème d\'affichage',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                _isDarkMode
                                    ? (isEn ? 'Dark Mode' : 'Mode Sombre')
                                    : (isEn ? 'Light Mode' : 'Mode Clair'),
                                style: TextStyle(fontSize: 12, color: subTextColor),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isDarkMode,
                          onChanged: (_) => _toggleTheme(),
                          activeColor: accent,
                          activeTrackColor: green.withOpacity(0.4),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Language section ────────────────────────────────────────
                  Text(
                    isEn ? 'LANGUAGE' : 'LANGUE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: subTextColor,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF60A5FA).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.language_rounded,
                                  color: Color(0xFF60A5FA), size: 20),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              isEn ? 'App Language' : 'Langue de l\'application',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Language option buttons
                        Row(
                          children: [
                            _settingsLangOption(
                              label: 'English',
                              flag: '🇬🇧',
                              selected: AppLocalization.currentLanguage == 'en',
                              onTap: () => setState(() => AppLocalization().setLanguage('en')),
                              textColor: textColor,
                              subTextColor: subTextColor,
                              green: green,
                              accent: accent,
                            ),
                            const SizedBox(width: 12),
                            _settingsLangOption(
                              label: 'Français',
                              flag: '🇫🇷',
                              selected: AppLocalization.currentLanguage == 'fr',
                              onTap: () => setState(() => AppLocalization().setLanguage('fr')),
                              textColor: textColor,
                              subTextColor: subTextColor,
                              green: green,
                              accent: accent,
                            ),
                          ],
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

  Widget _settingsLangOption({
    required String label,
    required String flag,
    required bool selected,
    required VoidCallback onTap,
    required Color textColor,
    required Color subTextColor,
    required Color green,
    required Color accent,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? green.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? green : Colors.white12,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                  color: selected ? accent : subTextColor,
                ),
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle_rounded, color: accent, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── FOOTER ──────────────────────────────────────────────────────────────────
  Widget _buildFooter(bool isEn, Color subTextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: _isDarkMode ? const Color(0x15FFFFFF) : const Color(0xFFE2E8F0))),
        color: _isDarkMode ? const Color(0x0A000000) : const Color(0xFFE2E8F0).withOpacity(0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCameroonFlag(),
              const SizedBox(width: 10),
              Text(
                isEn
                    ? 'Republic of Cameroon · MINESEC'
                    : 'République du Cameroun · MINESEC',
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isEn
                ? '© 2025 AI-Learning Style Tracker System. All rights reserved.'
                : '© 2025 Système de Suivi des Styles d\'Apprentissage par IA. Tous droits réservés.',
            style: TextStyle(
                color: _isDarkMode ? Colors.white24 : const Color(0xFF94A3B8),
                fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCameroonFlag() {
    return Container(
      width: 22,
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Row(
          children: [
            // Green Stripe (Left)
            Expanded(
              child: Container(color: const Color(0xFF007A5E)),
            ),
            // Red Stripe with Yellow Star (Middle)
            Expanded(
              child: Container(
                color: const Color(0xFFCE1126),
                child: const Center(
                  child: Icon(
                    Icons.star_rounded,
                    size: 6,
                    color: Color(0xFFFCD116),
                  ),
                ),
              ),
            ),
            // Yellow Stripe (Right)
            Expanded(
              child: Container(color: const Color(0xFFFCD116)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────
  Widget _glowBlob(Color color, double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity),
            blurRadius: size * 0.8,
            spreadRadius: size * 0.4,
          )
        ],
      ),
    );
  }



}

// ─── HOVER NAV LINK ──────────────────────────────────────────────────────────
class _HoverNavLink extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onPressed;

  const _HoverNavLink({
    required this.label,
    required this.icon,
    required this.active,
    this.onPressed,
  });

  @override
  State<_HoverNavLink> createState() => _HoverNavLinkState();
}

class _HoverNavLinkState extends State<_HoverNavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = const Color(0xFFFCD116);
    final Color hoverColor  = Colors.white;
    final Color idleColor   = Colors.white70;

    final Color labelColor = widget.active
        ? activeColor
        : _hovered
            ? hoverColor
            : idleColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: widget.active
                ? const Color(0xFFFCD116).withOpacity(0.08)
                : _hovered
                    ? Colors.white.withOpacity(0.06)
                    : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: widget.active
                    ? activeColor
                    : _hovered
                        ? Colors.white38
                        : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: labelColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: widget.active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


