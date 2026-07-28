// lib/views/language_view.dart
import 'package:flutter/material.dart';
import '../core/localization.dart';
import 'welcome_view.dart';

class LanguageView extends StatelessWidget {
  const LanguageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/edu_background.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black87, // Premium dark overlay for readability
              BlendMode.darken,
            ),
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: const Color(0x13FFFFFF), // Ultra-glassmorphic effect
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x2BFFFFFF), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 25,
                    offset: Offset(0, 15),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Official Logo Circular Badge
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white, // White background matching the circular logo format
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF006A4E), width: 2), // Cameroon green ring
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(4), // Subtle padding border
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/minesec_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Welcome / Bienvenue',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Select your preferred language\nVeuillez choisir votre langue',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 35),
                  
                  // English Button (No Flags)
                  _buildLanguageButton(
                    context: context,
                    label: 'English',
                    langCode: 'en',
                    color: const Color(0xFF006A4E), // Cameroon Green
                  ),
                  const SizedBox(height: 15),
                  
                  // French Button (No Flags)
                  _buildLanguageButton(
                    context: context,
                    label: 'Français',
                    langCode: 'fr',
                    color: const Color(0xFFCE1126), // Cameroon Red
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageButton({
    required BuildContext context,
    required String label,
    required String langCode,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          // Set language globally
          AppLocalization().setLanguage(langCode);
          
          // Route to WelcomeView
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeView()),
          );
        },
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
