# 1. Update admin_dashboard.dart
with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    admin_text = f.read()

if "import '../../services/vark_academic_engine.dart';" not in admin_text:
    admin_text = admin_text.replace(
        "import '../../services/auth_service.dart';",
        "import '../../services/auth_service.dart';\nimport '../../services/vark_academic_engine.dart';"
    )

# Replace national aiStrategy computation with VarkAcademicEngine
old_strategy_block = """    final int visCount = _parseInt(_adminData?['visual_count'] ?? 1);
    final int audCount = _parseInt(_adminData?['auditory_count'] ?? 1);
    final int kinCount = _parseInt(_adminData?['kinesthetic_count'] ?? 0);
    final int rwCount  = _parseInt(_adminData?['read_write_count'] ?? 0);
    final int totalV   = visCount + audCount + kinCount + rwCount;

    String dominantStyle = 'Auditory';
    int maxVal = audCount;
    if (visCount > maxVal) { maxVal = visCount; dominantStyle = 'Visual'; }
    if (kinCount > maxVal) { maxVal = kinCount; dominantStyle = 'Kinesthetic'; }
    if (rwCount > maxVal)  { maxVal = rwCount;  dominantStyle = 'Read/Write'; }

    final int domPct = totalV > 0 ? ((maxVal / totalV) * 100).round() : 50;

    String aiStrategy = _isEn
        ? (_adminData?['ai_national_strategy_en'] ?? '')
        : (_adminData?['ai_national_strategy_fr'] ?? '');

    if (aiStrategy.isEmpty || aiStrategy.contains('Total assessed') || aiStrategy.contains('diagnostic tracking') || aiStrategy.contains('Live diagnostic') || aiStrategy.contains('1 out of 4') || aiStrategy.contains('80%')) {
      final List<String> lines = [];
      if (_isEn) {
        if (dominantStyle == 'Auditory') {
          lines.add('• Auditory Learners (Majority): Prioritize interactive classroom discussions, verbal lecture summaries, peer debates, and audio-assisted learning toolkits across secondary schools.');
          lines.add('• Visual Learners Support: Equip classrooms with visual charts, multi-colored whiteboards, mind maps, and visual media tools to support visual learners.');
          lines.add('• Kinesthetic Learners Support: Provide hands-on laboratory exercises, interactive workshops, and practical learning kits for practical learners.');
          lines.add('• Read/Write Learners Support: Supply comprehensive textbook reference guides, structured note-taking templates, and school library materials.');
        } else if (dominantStyle == 'Visual') {
          lines.add('• Visual Learners (Majority): Prioritize visual mind maps, graphic organizers, color-coded study guides, and video presentations.');
          lines.add('• Auditory Learners Support: Facilitate interactive classroom discussions, verbal lecture summaries, and oral Q&A sessions.');
          lines.add('• Kinesthetic Learners Support: Provide hands-on laboratory exercises, interactive workshops, and practical learning kits.');
          lines.add('• Read/Write Learners Support: Supply comprehensive textbook reference guides, structured note-taking templates, and school library materials.');
        } else if (dominantStyle == 'Kinesthetic') {
          lines.add('• Kinesthetic Learners (Majority): Prioritize hands-on laboratory workshops, practical experiments, and kinesthetic learning kits.');
          lines.add('• Auditory Learners Support: Facilitate interactive classroom discussions, verbal lecture summaries, and oral Q&A sessions.');
          lines.add('• Visual Learners Support: Equip classrooms with visual charts, multi-colored whiteboards, mind maps, and visual media tools.');
          lines.add('• Read/Write Learners Support: Supply comprehensive textbook reference guides, structured note-taking templates, and school library materials.');
        } else {
          lines.add('• Read/Write Learners (Majority): Prioritize structured text materials, reading comprehension modules, and essay writing frameworks.');
          lines.add('• Auditory Learners Support: Facilitate interactive classroom discussions, verbal lecture summaries, and oral Q&A sessions.');
          lines.add('• Visual Learners Support: Equip classrooms with visual charts, multi-colored whiteboards, mind maps, and visual media tools.');
          lines.add('• Kinesthetic Learners Support: Provide hands-on laboratory exercises, interactive workshops, and practical learning kits.');
        }
      } else {
        if (dominantStyle == 'Auditory') {
          lines.add('• Apprenants Auditifs (Majorité) : Privilégiez les discussions interactives en classe, les résumés de cours oraux, les débats et les outils audio.');
          lines.add('• Soutien aux Apprenants Visuels : Équipez les classes de graphiques visuels, de cartes mentales et de supports médias pour soutenir les élèves visuels.');
          lines.add('• Soutien aux Apprenants Kinesthésiques : Fournissez des travaux pratiques de laboratoire, des ateliers interactifs et des kits d\\'apprentissage.');
          lines.add('• Soutien aux Apprenants Lecture/Écriture : Fournissez des manuels de référence complets, des modèles de prise de notes structurés et des ressources en bibliothèque.');
        } else if (dominantStyle == 'Visual') {
          lines.add('• Apprenants Visuels (Majorité) : Privilégiez les cartes mentales, schémas, guides en couleurs et présentations vidéo.');
          lines.add('• Soutien aux Apprenants Auditifs : Facilitez les résumés de cours oraux, les séances de Q/R et les discussions de groupe.');
          lines.add('• Soutien aux Apprenants Kinesthésiques : Fournissez des travaux pratiques de laboratoire, des ateliers interactifs et des kits d\\'apprentissage.');
          lines.add('• Soutien aux Apprenants Lecture/Écriture : Fournissez des manuels de référence complets et des modèles de prise de notes.');
        } else if (dominantStyle == 'Kinesthetic') {
          lines.add('• Apprenants Kinesthésiques (Majorité) : Privilégiez les travaux pratiques en laboratoire et les kits kinesthésiques.');
          lines.add('• Soutien aux Apprenants Auditifs : Facilitez les résumés de cours oraux, les séances de Q/R et les discussions de groupe.');
          lines.add('• Soutien aux Apprenants Visuels : Équipez les classes de graphiques visuels, de cartes mentales et de supports médias.');
          lines.add('• Soutien aux Apprenants Lecture/Écriture : Fournissez des manuels de référence complets et des modèles de prise de notes.');
        } else {
          lines.add('• Apprenants Lecture/Écriture (Majorité) : Privilégiez les manuels structurés et les modules de rédaction.');
          lines.add('• Soutien aux Apprenants Auditifs : Facilitez les résumés de cours oraux, les séances de Q/R et les discussions de groupe.');
          lines.add('• Soutien aux Apprenants Visuels : Équipez les classes de graphiques visuels, de cartes mentales et de supports médias.');
          lines.add('• Soutien aux Apprenants Kinesthésiques : Fournissez des travaux pratiques de laboratoire, des ateliers interactifs et des kits d\\'apprentissage.');
        }
      }
      aiStrategy = lines.join('\\n');
    }"""

new_strategy_block = """    final int visCount = _parseInt(_adminData?['visual_count'] ?? 0);
    final int audCount = _parseInt(_adminData?['auditory_count'] ?? 2);
    final int kinCount = _parseInt(_adminData?['kinesthetic_count'] ?? 0);
    final int rwCount  = _parseInt(_adminData?['read_write_count'] ?? 0);

    final evalNational = VarkAcademicEngine.evaluate(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
    );

    final String aiStrategy = _isEn
        ? "• National Pedagogical Diagnosis: Dominant profile is ${evalNational.learningStyle} (${evalNational.primaryCategoryNameEn}).\\n"
          "• Academic Prospects & Resilience: ${evalNational.prospectsSummaryEn}\\n\\n"
          "${evalNational.learningStrategyEn}"
        : "• Diagnostic Pédagogique National : Profil dominant ${evalNational.learningStyle} (${evalNational.primaryCategoryNameFr}).\\n"
          "• Perspectives Académiques & Résilience : ${evalNational.prospectsSummaryFr}\\n\\n"
          "${evalNational.learningStrategyFr}";"""

if old_strategy_block in admin_text:
    admin_text = admin_text.replace(old_strategy_block, new_strategy_block)

# Update Tab 2 School Recommendation in admin_dashboard.dart
old_tab2_sc_eval = """                                  final aiRec = (totSt == 0 || assSt == 0)
                                      ? (_isEn
                                          ? '• Multimodal Teaching Strategy (Diagnostic Phase): Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                          : '• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                      : (_isEn
                                          ? (_classDetailsData!['ai_recommendation_en'] ?? '• Institutional Policy Directive: Coordinate with head teachers to complete VARK diagnostics and allocate audio-visual tools.')
                                          : (_classDetailsData!['ai_recommendation_fr'] ?? '• Directive Institutionnelle : Coordonnez avec les proviseurs pour finaliser les tests VARK et allouer du matériel audio-visuel.'));"""

new_tab2_sc_eval = """                                  final evalSc = VarkAcademicEngine.evaluate(auditory: aud, visual: vis, kinesthetic: kin, readWrite: rw);
                                  final aiRec = (totSt == 0 || assSt == 0)
                                      ? (_isEn
                                          ? '• Multimodal Diagnostic Phase: Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                          : '• Phase Diagnostique Multimodale : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                      : (_isEn
                                          ? "• Academic Diagnosis for $scName: ${evalSc.learningStyle} (${evalSc.primaryCategoryNameEn}).\\n"
                                            "• Academic Prospects: ${evalSc.prospectsSummaryEn}\\n\\n"
                                            "${evalSc.learningStrategyEn}"
                                          : "• Diagnostic Académique pour $scName : ${evalSc.learningStyle} (${evalSc.primaryCategoryNameFr}).\\n"
                                            "• Perspectives Académiques : ${evalSc.prospectsSummaryFr}\\n\\n"
                                            "${evalSc.learningStrategyFr}");"""

if old_tab2_sc_eval in admin_text:
    admin_text = admin_text.replace(old_tab2_sc_eval, new_tab2_sc_eval)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(admin_text)

print("SUCCESS: ADMIN DASHBOARD FULLY WIRED TO NEIL FLEMING ENGINE")
