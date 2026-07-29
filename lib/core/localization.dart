// lib/core/localization.dart
import 'package:flutter/material.dart';

class AppLocalization extends ChangeNotifier {
  static final AppLocalization _instance = AppLocalization._internal();
  factory AppLocalization() => _instance;
  AppLocalization._internal();

  static String currentLanguage = 'en'; // 'en' or 'fr'

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'AI-Powered Learning Profile System',
      'minesec': 'NATIONAL EDUCATION PORTAL',
      'republic': 'REPUBLIC OF CAMEROON',
      'motto': 'Peace - Work - Fatherland',
      'welcome_title': 'Welcome / Bienvenue',
      'welcome_sub': 'Please select your preferred language / Choisir votre langue',
      'portal_title': 'Educational Portal',
      'portal_sub': 'Access your learning profile or administrative dashboard',
      'role_student': 'Student',
      'desc_student': 'Take the assessment, view recommendations & download reports.',
      'role_teacher': 'Teacher',
      'desc_teacher': 'View students, monitor classroom learning styles, and adapt methodologies.',
      'role_principal': 'Principal',
      'desc_principal': 'Access school analytics, compare classes, and download statistics.',
      'role_div_delegate': 'Divisional Delegate',
      'desc_div_delegate': 'Monitor schools and learning trends in the division.',
      'role_reg_delegate': 'Regional Delegate',
      'desc_reg_delegate': 'Analyze regional data distribution and compare divisions.',
      'role_ministry': 'Ministry Official',
      'desc_ministry': 'Access national reports, search registry, and monitor system KPIs.',
      'role_admin': 'System Administrator',
      'desc_admin': 'Manage access permissions and audit security event logs.',
      'enter_portal': 'Enter Portal →',
      'nav_home': 'Home',
      'nav_about': 'About',
      'nav_help': 'Help',
      'back_home': 'Back to Home',
      'about_title': 'About the Platform',
      'about_sub': 'AI-driven VARK learning style assessment & educational analytics framework',
      'about_mission_title': 'Our Core Mission',
      'about_mission_desc': 'Empowering learners and educators across Cameroon by utilizing AI data insights to personalize learning styles, optimize teaching methodologies, and improve academic performance.',
      'vark_title': 'VARK Learning Modalities',
      'vark_desc': 'The VARK model classifies learning preferences into four distinct sensory channels: Visual (V), Auditory (A), Read/Write (R), and Kinesthetic (K).',
      'vark_v_title': 'Visual Learners',
      'vark_v_desc': 'Understand best through diagrams, charts, mind maps, and visual demonstrations.',
      'vark_a_title': 'Auditory Learners',
      'vark_a_desc': 'Excel through listening to lectures, group discussions, and oral explanations.',
      'vark_r_title': 'Read/Write Learners',
      'vark_r_desc': 'Prefer text-based inputs, comprehensive reading, note-taking, and written reports.',
      'vark_k_title': 'Kinesthetic Learners',
      'vark_k_desc': 'Learn effectively via hands-on practice, physical experiments, and real-world application.',
      'help_title': 'Help & Support Center',
      'help_sub': 'Find quick answers, user manuals, and technical assistance',
      'faq_title': 'Frequently Asked Questions',
      'contact_support': 'Need Technical Assistance?',
      'contact_support_sub': 'Contact system administration for login issues or system inquiries.',
      'support_email': 'support@learningtracker.edu.cm',
    },
    'fr': {
      'app_title': 'Système d\'Évaluation des Profils par IA',
      'minesec': 'PORTAIL NATIONAL DE L\'ÉDUCATION',
      'republic': 'RÉPUBLIQUE DU CAMEROUN',
      'motto': 'Paix - Travail - Patrie',
      'welcome_title': 'Bienvenue / Welcome',
      'welcome_sub': 'Veuillez choisir votre langue / Please select your language',
      'portal_title': 'Portail Éducatif',
      'portal_sub': 'Accédez à votre profil d\'apprentissage ou tableau de bord',
      'role_student': 'Élève',
      'desc_student': 'Faire l\'évaluation, voir les recommandations et rapports.',
      'role_teacher': 'Enseignant',
      'desc_teacher': 'Suivre les styles d\'apprentissage et adapter la pédagogie.',
      'role_principal': 'Proviseur',
      'desc_principal': 'Accéder aux statistiques de l\'école et comparer les classes.',
      'role_div_delegate': 'Délégué Départemental',
      'desc_div_delegate': 'Suivre les écoles et tendances d\'apprentissage du département.',
      'role_reg_delegate': 'Délégué Régional',
      'desc_reg_delegate': 'Analyser les données de la région et comparer les départements.',
      'role_ministry': 'Délégué Ministériel',
      'desc_ministry': 'Accéder aux statistiques nationales et rechercher dans le registre.',
      'role_admin': 'Administrateur',
      'desc_admin': 'Gérer les autorisations d\'accès et consulter les journaux d\'audit.',
      'enter_portal': 'Entrer dans le Portail →',
      'nav_home': 'Accueil',
      'nav_about': 'À propos',
      'nav_help': 'Aide',
      'back_home': 'Retour à l\'accueil',
      'about_title': 'À propos de la Plateforme',
      'about_sub': 'Évaluation des profils d\'apprentissage VARK par IA et cadre analytique éducatif',
      'about_mission_title': 'Notre Mission Principale',
      'about_mission_desc': 'Autonomiser les élèves et les enseignants au Cameroun grâce aux analyses de données par IA afin de personnaliser les styles d\'apprentissage et optimiser les méthodes d\'enseignement.',
      'vark_title': 'Modalités d\'Apprentissage VARK',
      'vark_desc': 'Le modèle VARK classe les préférences d\'apprentissage en quatre canaux sensoriels : Visuel (V), Auditif (A), Lecture/Écriture (R) et Kinesthésique (K).',
      'vark_v_title': 'Apprenants Visuels',
      'vark_v_desc': 'Comprennent mieux grâce aux schémas, graphiques, cartes mentales et démonstrations visuelles.',
      'vark_a_title': 'Apprenants Auditifs',
      'vark_a_desc': 'Excellent par l\'écoute des cours, les discussions de groupe et les explications orales.',
      'vark_r_title': 'Apprenants Lecture/Écriture',
      'vark_r_desc': 'Préfèrent les supports textuels, la lecture approfondie, la prise de notes et les rapports rédigés.',
      'vark_k_title': 'Apprenants Kinesthésiques',
      'vark_k_desc': 'Apprennent efficacement par la pratique sur le terrain, les expériences et l\'application réelle.',
      'help_title': 'Centre d\'Aide & Support',
      'help_sub': 'Trouvez des réponses rapides, des guides d\'utilisation et une assistance technique',
      'faq_title': 'Foire Aux Questions',
      'contact_support': 'Besoin d\'Assistance Technique ?',
      'contact_support_sub': 'Contactez l\'administration système pour tout problème de connexion ou demande.',
      'support_email': 'support@learningtracker.edu.cm',
    }
  };

  void setLanguage(String lang) {
    if (currentLanguage != lang) {
      currentLanguage = lang;
      notifyListeners();
    }
  }

  static String translate(String key) {
    return _localizedValues[currentLanguage]?[key] ?? key;
  }
}
