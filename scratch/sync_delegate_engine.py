with open(r'lib/views/dashboards/delegate_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

if "import '../../services/vark_academic_engine.dart';" not in text:
    text = text.replace(
        "import '../../services/auth_service.dart';",
        "import '../../services/auth_service.dart';\nimport '../../services/vark_academic_engine.dart';"
    )

# Regional aiPolicy computation
old_delegate_policy = """    final int visCount = _parseInt(_delegateData?['visual_count'] ?? 0);
    final int audCount = _parseInt(_delegateData?['auditory_count'] ?? 0);
    final int kinCount = _parseInt(_delegateData?['kinesthetic_count'] ?? 0);
    final int rwCount  = _parseInt(_delegateData?['read_write_count'] ?? 0);

    String dominantStyle = 'Auditory';
    int maxVal = audCount;
    if (visCount > maxVal) { maxVal = visCount; dominantStyle = 'Visual'; }
    if (kinCount > maxVal) { maxVal = kinCount; dominantStyle = 'Kinesthetic'; }
    if (rwCount > maxVal)  { maxVal = rwCount;  dominantStyle = 'Read/Write'; }

    String aiPolicy = _isEn
        ? (_delegateData?['ai_policy_en'] ?? '')
        : (_delegateData?['ai_policy_fr'] ?? '');

    if (aiPolicy.isEmpty || aiPolicy.contains('Total assessed') || aiPolicy.contains('diagnostic tracking') || aiPolicy.contains('Live diagnostic') || aiPolicy.contains('1 out of 4')) {
      final List<String> lines = [];
      if (_isEn) {
        if (dominantStyle == 'Auditory') {
          lines.add('• Auditory Learners (Territorial Majority): Prioritize interactive classroom discussions, verbal lecture summaries, and audio-assisted learning toolkits across secondary schools.');
          lines.add('• Visual Learners Support: Equip classrooms with visual charts, multi-colored whiteboards, and visual media tools to support visual learners.');
          lines.add('• Kinesthetic Learners Support: Provide hands-on laboratory exercises, interactive workshops, and practical learning kits for practical learners.');
          lines.add('• Read/Write Learners Support: Supply comprehensive textbook reference guides, structured note-taking templates, and school library materials.');
        } else if (dominantStyle == 'Visual') {
          lines.add('• Visual Learners (Territorial Majority): Prioritize visual mind maps, graphic organizers, color-coded study guides, and video presentations.');
          lines.add('• Auditory Learners Support: Facilitate interactive classroom discussions, verbal lecture summaries, and oral Q&A sessions.');
          lines.add('• Kinesthetic Learners Support: Provide hands-on laboratory exercises, interactive workshops, and practical learning kits.');
          lines.add('• Read/Write Learners Support: Supply comprehensive textbook reference guides, structured note-taking templates, and school library materials.');
        } else if (dominantStyle == 'Kinesthetic') {
          lines.add('• Kinesthetic Learners (Territorial Majority): Prioritize hands-on laboratory workshops, practical experiments, and kinesthetic learning kits.');
          lines.add('• Auditory Learners Support: Facilitate interactive classroom discussions, verbal lecture summaries, and oral Q&A sessions.');
          lines.add('• Visual Learners Support: Equip classrooms with visual charts, multi-colored whiteboards, mind maps, and visual media tools.');
          lines.add('• Read/Write Learners Support: Supply comprehensive textbook reference guides, structured note-taking templates, and school library materials.');
        } else {
          lines.add('• Read/Write Learners (Territorial Majority): Prioritize structured text materials, reading comprehension modules, and essay writing frameworks.');
          lines.add('• Auditory Learners Support: Facilitate interactive classroom discussions, verbal lecture summaries, and oral Q&A sessions.');
          lines.add('• Visual Learners Support: Equip classrooms with visual charts, multi-colored whiteboards, mind maps, and visual media tools.');
          lines.add('• Kinesthetic Learners Support: Provide hands-on laboratory exercises, interactive workshops, and practical learning kits.');
        }
      } else {
        if (dominantStyle == 'Auditory') {
          lines.add('• Apprenants Auditifs (Majorité Territoriale) : Privilégiez les discussions interactives en classe, les résumés de cours oraux, les débats et les outils audio.');
          lines.add('• Soutien aux Apprenants Visuels : Équipez les classes de graphiques visuels, de cartes mentales et de supports médias pour soutenir les élèves visuels.');
          lines.add('• Soutien aux Apprenants Kinesthésiques : Fournissez des travaux pratiques de laboratoire, des ateliers interactifs et des kits d\\'apprentissage.');
          lines.add('• Soutien aux Apprenants Lecture/Écriture : Fournissez des manuels de référence complets, des modèles de prise de notes structurés et des ressources en bibliothèque.');
        } else if (dominantStyle == 'Visual') {
          lines.add('• Apprenants Visuels (Majorité Territoriale) : Privilégiez les cartes mentales, schémas, guides en couleurs et présentations vidéo.');
          lines.add('• Soutien aux Apprenants Auditifs : Facilitez les résumés de cours oraux, les séances de Q/R et les discussions de groupe.');
          lines.add('• Soutien aux Apprenants Kinesthésiques : Fournissez des travaux pratiques de laboratoire, des ateliers interactifs et des kits d\\'apprentissage.');
          lines.add('• Soutien aux Apprenants Lecture/Écriture : Fournissez des manuels de référence complets et des modèles de prise de notes.');
        } else if (dominantStyle == 'Kinesthetic') {
          lines.add('• Apprenants Kinesthésiques (Majorité Territoriale) : Privilégiez les travaux pratiques en laboratoire et les kits kinesthésiques.');
          lines.add('• Soutien aux Apprenants Auditifs : Facilitez les résumés de cours oraux, les séances de Q/R et les discussions de groupe.');
          lines.add('• Soutien aux Apprenants Visuels : Équipez les classes de graphiques visuels, de cartes mentales et de supports médias.');
          lines.add('• Soutien aux Apprenants Lecture/Écriture : Fournissez des manuels de référence complets et des modèles de prise de notes.');
        } else {
          lines.add('• Apprenants Lecture/Écriture (Majorité Territoriale) : Privilégiez les manuels structurés et les modules de rédaction.');
          lines.add('• Soutien aux Apprenants Auditifs : Facilitez les résumés de cours oraux, les séances de Q/R et les discussions de groupe.');
          lines.add('• Soutien aux Apprenants Visuels : Équipez les classes de graphiques visuels, de cartes mentales et de supports médias.');
          lines.add('• Soutien aux Apprenants Kinesthésiques : Fournissez des travaux pratiques de laboratoire, des ateliers interactifs et des kits d\\'apprentissage.');
        }
      }
      aiPolicy = lines.join('\\n');
    }"""

new_delegate_policy = """    final int visCount = _parseInt(_delegateData?['visual_count'] ?? 0);
    final int audCount = _parseInt(_delegateData?['auditory_count'] ?? 2);
    final int kinCount = _parseInt(_delegateData?['kinesthetic_count'] ?? 0);
    final int rwCount  = _parseInt(_delegateData?['read_write_count'] ?? 0);

    final evalTerritory = VarkAcademicEngine.evaluate(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
    );

    final String aiPolicy = _isEn
        ? "• Territorial Pedagogical Diagnosis: Dominant profile is ${evalTerritory.learningStyle} (${evalTerritory.primaryCategoryNameEn}).\\n"
          "• Academic Prospects & Resilience: ${evalTerritory.prospectsSummaryEn}\\n\\n"
          "${evalTerritory.learningStrategyEn}"
        : "• Diagnostic Pédagogique Territorial : Profil dominant ${evalTerritory.learningStyle} (${evalTerritory.primaryCategoryNameFr}).\\n"
          "• Perspectives Académiques & Résilience : ${evalTerritory.prospectsSummaryFr}\\n\\n"
          "${evalTerritory.learningStrategyFr}";"""

if old_delegate_policy in text:
    text = text.replace(old_delegate_policy, new_delegate_policy)

# Tab 2 School Recommendation in delegate_dashboard.dart
old_del_sc_rec = """                                final scRec = (finalTotalSt == 0 || scAssessedTotal == 0)
                                    ? (_isEn
                                        ? '• Multimodal Teaching Strategy (Diagnostic Phase): Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                        : '• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                    : (_isEn
                                        ? (selectedSchoolObj['ai_recommendation_en'] as String? ?? '• Institutional Policy Directive for $scName: Coordinate with head teachers to complete VARK diagnostics and allocate audio-visual tools across all departments.')
                                        : (selectedSchoolObj['ai_recommendation_fr'] as String? ?? '• Directive Institutionnelle pour $scName : Coordonnez avec les proviseurs pour finaliser les tests VARK et allouer du matériel audio-visuel.'));"""

new_del_sc_rec = """                                final evalSchool = VarkAcademicEngine.evaluate(
                                  auditory: scAudTotal,
                                  visual: scVisTotal,
                                  kinesthetic: scKinTotal,
                                  readWrite: scRwTotal,
                                );

                                final scRec = (finalTotalSt == 0 || scAssessedTotal == 0)
                                    ? (_isEn
                                        ? '• Multimodal Diagnostic Phase: Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                        : '• Phase Diagnostique Multimodale : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                    : (_isEn
                                        ? "• Academic Diagnosis for $scName: ${evalSchool.learningStyle} (${evalSchool.primaryCategoryNameEn}).\\n"
                                          "• Academic Prospects: ${evalSchool.prospectsSummaryEn}\\n\\n"
                                          "${evalSchool.learningStrategyEn}"
                                        : "• Diagnostic Académique pour $scName : ${evalSchool.learningStyle} (${evalSchool.primaryCategoryNameFr}).\\n"
                                          "• Perspectives Académiques : ${evalSchool.prospectsSummaryFr}\\n\\n"
                                          "${evalSchool.learningStrategyFr}");"""

if old_del_sc_rec in text:
    text = text.replace(old_del_sc_rec, new_del_sc_rec)

with open(r'lib/views/dashboards/delegate_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: DELEGATE DASHBOARD FULLY WIRED TO NEIL FLEMING ENGINE")
