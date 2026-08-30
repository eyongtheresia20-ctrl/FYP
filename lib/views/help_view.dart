// lib/views/help_view.dart
import 'package:flutter/material.dart';
import '../widgets/app_logo.dart';
import '../core/localization.dart';

class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  bool _isDarkMode = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);
  void _changeLanguage(String code) =>
      setState(() => AppLocalization().setLanguage(code));

  List<Map<String, String>> _getFaqs(bool isEn) {
    if (isEn) {
      return [
        {
          'category': 'Students',
          'question': 'How do I take the learning style assessment?',
          'answer':
              'Enter your student matricule on the sign-in screen to log in, navigate to "Take Assessment" in your Student Dashboard, and answer the 10 study preference questions to generate your instant VARK report.',
        },
        {
          'category': 'Students',
          'question': 'Can I retake the learning profile assessment?',
          'answer':
              'Yes! You can retake the assessment at any time from your Student Dashboard. The system updates your scores, logs your attempt history, and calculates your multi-test composite average.',
        },
        {
          'category': 'Teachers',
          'question': 'How do teachers access classroom analytics?',
          'answer':
              'Log in using your teacher matricule and password. From your Teacher Dashboard, select your assigned class to view real-time VARK pie charts, student score breakdowns, and dominant styles.',
        },
        {
          'category': 'Teachers',
          'question': 'Where can I find teaching strategies for specific profiles?',
          'answer':
              'Open any student profile or VARK score card on your dashboard to view tailored pedagogical recommendations for Visual, Auditory, Kinesthetic, and Read/Write learners.',
        },
        {
          'category': 'Administration',
          'question': 'How do administrators manage user accounts?',
          'answer':
              'Log into the Principal or Admin Dashboard using your administrative credentials to activate/deactivate accounts, issue 4-digit security PINs, and monitor school-wide participation.',
        },
        {
          'category': 'Administration',
          'question': 'How is student data protected and secured?',
          'answer':
              'All student diagnostic data is encrypted, stored locally for 100% offline access, and synced securely with the central MINESEC database in compliance with privacy regulations.',
        },
      ];
    } else {
      return [
        {
          'category': 'Students',
          'question': 'Comment passer l\'évaluation des styles d\'apprentissage ?',
          'answer':
              'Entrez votre matricule élève à la connexion, allez sur "Passer l\'évaluation" dans votre Tableau de Bord Élève, et répondez aux 10 questions pour obtenir votre rapport VARK instantané.',
        },
        {
          'category': 'Students',
          'question': 'Puis-je repasser l\'évaluation de profil ?',
          'answer':
              'Oui ! Vous pouvez repasser l\'évaluation à tout moment. Le système met à jour vos scores, conserve l\'historique des tentatives et calcule votre moyenne composite.',
        },
        {
          'category': 'Teachers',
          'question': 'Comment les enseignants accèdent-ils aux analyses de classe ?',
          'answer':
              'Connectez-vous avec votre matricule et mot de passe enseignant. Sélectionnez votre classe sur votre tableau de bord pour voir les graphiques VARK et la répartition des profils.',
        },
        {
          'category': 'Teachers',
          'question': 'Où trouver des stratégies pédagogiques adaptées ?',
          'answer':
              'Ouvrez n\'importe quel profil d\'élève ou carte de score VARK sur votre tableau de bord pour afficher des recommandations adaptées aux profils Visuel, Auditif, Kinesthésique et Lecture/Écriture.',
        },
        {
          'category': 'Administration',
          'question': 'Comment les administrateurs gèrent-ils les comptes ?',
          'answer':
              'Connectez-vous au Tableau de Bord Proviseur ou Admin pour activer/désactiver des comptes, attribuer des codes PIN de sécurité et suivre la participation globale.',
        },
        {
          'category': 'Administration',
          'question': 'Comment les données des élèves sont-elles protégées ?',
          'answer':
              'Toutes les données sont cryptées, stockées localement pour un accès 100% hors-ligne et synchronisées en toute sécurité avec la base centrale MINESEC.',
        },
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = AppLocalization.currentLanguage == 'en';
    final double w = MediaQuery.of(context).size.width;
    final bool isWide = w > 800;

    final Color bg        = _isDarkMode ? const Color(0xFF07090F) : const Color(0xFFF1F5F9);
    final Color nav       = _isDarkMode ? const Color(0xFF0D1421) : const Color(0xFF0F172A);
    final Color text      = _isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final Color sub       = _isDarkMode ? Colors.white60 : const Color(0xFF475569);
    final Color cardBg    = _isDarkMode ? const Color(0xFF111827) : Colors.white;
    final Color cardBd    = _isDarkMode ? const Color(0x22FFFFFF) : const Color(0xFFE2E8F0);
    final Color green     = const Color(0xFF006A4E);
    final Color accent    = const Color(0xFF34D399);

    final allFaqs = _getFaqs(isEn);
    final filteredFaqs = allFaqs.where((faq) {
      final matchesCat =
          _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isWide ? 76 : 68),
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
              padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  AppLogo(size: isWide ? 46 : 38, showGlow: false),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalization.translate('help_title'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 17 : 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                      color: _isDarkMode ? const Color(0xFFFCD116) : Colors.white70,
                      size: isWide ? 22 : 18,
                    ),
                    onPressed: _toggleTheme,
                  ),
                  if (isWide) ...[
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
            // Hero Banner with Search
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? w * 0.14 : 24,
                vertical: isWide ? 56 : 40,
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
                      color: text,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isEn
                        ? 'Find quick answers or search for topics below.'
                        : 'Trouvez des réponses rapides ou recherchez ci-dessous.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: sub),
                  ),
                  const SizedBox(height: 28),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(color: text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: isEn
                            ? 'Search questions or topics...'
                            : 'Rechercher des questions...',
                        hintStyle: TextStyle(color: sub),
                        prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
                        filled: true,
                        fillColor: cardBg,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cardBd),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cardBd),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: green, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? w * 0.12 : 20,
                vertical: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Students', 'Teachers', 'Administration'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        String label = cat;
                        if (!isEn) {
                          if (cat == 'All') label = 'Tous';
                          if (cat == 'Students') label = 'Élèves';
                          if (cat == 'Teachers') label = 'Enseignants';
                          if (cat == 'Administration') label = 'Administration';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(label),
                            selectedColor: green,
                            backgroundColor: cardBg,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : text,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                            side: BorderSide(
                              color: isSelected ? green : cardBd,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    isEn ? 'Frequently Asked Questions' : 'Foire Aux Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  filteredFaqs.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBd),
                          ),
                          child: Center(
                            child: Text(
                              isEn
                                  ? 'No matching questions found.'
                                  : 'Aucune question correspondante trouvée.',
                              style: TextStyle(color: sub, fontSize: 14),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredFaqs.length,
                          itemBuilder: (context, index) {
                            final item = filteredFaqs[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cardBd),
                              ),
                              child: Theme(
                                data: Theme.of(context)
                                    .copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  iconColor: accent,
                                  collapsedIconColor: sub,
                                  tilePadding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 4),
                                  title: Text(
                                    item['question']!,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: text,
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          item['answer']!,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            color: sub,
                                            height: 1.6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),

            // Footer (web only)
            if (isWide)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Column(children: [
                  Text(
                    'Republic of Cameroon  ·  République du Cameroun',
                    style: TextStyle(fontSize: 12, color: sub),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Learning Style Tracker  ·  v1.0.0  ·  2025',
                    style: TextStyle(
                        fontSize: 11, color: sub.withOpacity(0.45)),
                  ),
                ]),
              ),
          ],
        ),
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
