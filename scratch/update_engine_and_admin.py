# Update vark_academic_engine.dart

with open(r'lib/services/vark_academic_engine.dart', 'r', encoding='utf-8') as f:
    engine_code = f.read()

# Replace evaluateForEducators in vark_academic_engine.dart
old_eval_educators_start = "  static Map<String, String> evaluateForEducators({"
idx_eval_start = engine_code.find(old_eval_educators_start)
idx_eval_end = engine_code.find("  static VarkEvaluationResult evaluate({", idx_eval_start)

new_eval_educators = '''  static Map<String, String> evaluateForEducators({
    required num auditory,
    required num visual,
    required num kinesthetic,
    required num readWrite,
    String contextName = '',
    bool isSchoolLevel = false,
    bool isNationalLevel = false,
    bool isRegionalLevel = false,
  }) {
    final int aud = auditory.toInt();
    final int vis = visual.toInt();
    final int kin = kinesthetic.toInt();
    final int rw  = readWrite.toInt();
    final int totalAssessed = aud + vis + kin + rw;

    if (totalAssessed == 0) {
      if (isNationalLevel) {
        return {
          'en': "• National Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently underway nationwide across secondary and technical schools.\\n\\n"
                "• Universal Multimodal Educational Policy: All pedagogical inspectors, regional delegates, and educators must encourage and balance all 4 learning modalities equally (Visual, Auditory, Read/Write, Kinesthetic) across all academic curricula.\\n\\n"
                "• National Assessment Supervision: Mobilize regional and divisional delegations to ensure all enrolled secondary students complete their diagnostic VARK test.",
          'fr': "• Stratégie Multimodale Nationale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans l'ensemble des établissements secondaires et techniques du territoire.\\n\\n"
                "• Politique Éducative Multimodale Globale : L'ensemble des inspecteurs pédagogiques, délégués régionaux et enseignants doivent encourager équitablement les 4 modalités d'apprentissage (Visuel, Auditif, Lecture/Écriture, Kinesthésique).\\n\\n"
                "• Suivi National des Évaluations : Mobiliser les délégations régionales et départementales pour que l'ensemble des élèves complètent leur test diagnostique.",
        };
      } else if (isSchoolLevel) {
        return {
          'en': "• Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently in progress across classes in $contextName.\\n\\n"
                "• School-Wide Multimodal Instruction: Head teachers and pedagogical staff should encourage all learning styles equally by ensuring every subject incorporates verbal lectures, visual diagrams, structured texts, and practical exercises.\\n\\n"
                "• Diagnostic Supervision: Coordinate with class teachers to ensure all enrolled students complete their diagnostic VARK test.",
          'fr': "• Stratégie Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans les classes de $contextName.\\n\\n"
                "• Enseignement Multimodal Global : Les équipes pédagogiques doivent encourager équitablement tous les styles d'apprentissage en combinant explications orales, supports visuels, fiches écrites et travaux pratiques.\\n\\n"
                "• Suivi Diagnostique : Coordonnez avec les professeurs principaux pour que l'ensemble des élèves complètent leur évaluation.",
        };
      } else {
        return {
          'en': "• Multimodal Teaching Strategy (Diagnostic Phase): No students have completed the VARK assessment in $contextName yet.\\n\\n"
                "• Differentiated Classroom Engagement: Encourage and stimulate all learning styles equally through multimodal instruction—combining oral explanations, whiteboard diagrams, written notes, and hands-on exercises.\\n\\n"
                "• Assessment Coordination: Encourage all students in this class to complete their diagnostic test on the platform.",
          'fr': "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Aucun élève n'a encore complété le test VARK en $contextName.\\n\\n"
                "• Enseignement Inclusif & Équilibré : Encouragez et mobilisez équitablement tous les styles d'apprentissage (explications orales, schémas au tableau, notes écrites et exercices pratiques).\\n\\n"
                "• Coordination Diagnostique : Invitez tous les élèves de cette classe à passer leur évaluation sur la plateforme.",
        };
      }
    }

    final Map<String, int> scores = {
      'Auditory': aud,
      'Visual': vis,
      'Kinesthetic': kin,
      'Read/Write': rw,
    };

    final Map<String, int> presentStyles = {};
    scores.forEach((st, count) {
      if (count > 0) {
        presentStyles[st] = count;
      }
    });

    final sorted = presentStyles.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final List<String> linesEn = [];
    final List<String> linesFr = [];

    final List<String> partsEn = [];
    final List<String> partsFr = [];
    for (var entry in sorted) {
      final pct = ((entry.value / totalAssessed) * 100).round();
      partsEn.add('${entry.value} ${entry.key} ($pct%)');
      partsFr.add('${entry.value} ${getModalityNameFr(entry.key)} ($pct%)');
    }

    String headerPrefixEn = '• Class Profile Overview';
    String headerPrefixFr = '• Profil de la Classe';
    if (isNationalLevel) {
      headerPrefixEn = '• National Evaluated Cohort Profile';
      headerPrefixFr = '• Profil de la Cohorte Évaluée au Niveau National';
    } else if (isRegionalLevel) {
      headerPrefixEn = '• Regional Evaluated Cohort Profile';
      headerPrefixFr = '• Profil de la Cohorte Évaluée au Niveau Régional';
    } else if (isSchoolLevel) {
      headerPrefixEn = '• School Evaluated Cohort Profile';
      headerPrefixFr = '• Profil de la Cohorte Évaluée de l\\'Établissement';
    }

    linesEn.add("$headerPrefixEn: ${partsEn.join(', ')} out of $totalAssessed assessed students.");
    linesFr.add("$headerPrefixFr : ${partsFr.join(', ')} sur $totalAssessed élèves évalués.");

    for (var entry in sorted) {
      final st = entry.key;
      final cnt = entry.value;

      if (st == 'Auditory') {
        linesEn.add("• Recommendations for Auditory Learners ($cnt students):\\n"
                     "  - Classroom Instruction: Emphasize clear oral explanations, structured class discussions, verbal lecture summaries, and oral Q&A reviews.\\n"
                     "  - Institutional Support: Prioritize public address systems, audio recording tools for lesson archives, and school debate seminars.");

        linesFr.add("• Recommandations pour les Apprenants Auditifs ($cnt élèves) :\\n"
                     "  - Pratiques Pédagogiques : Privilégiez les explications orales structurées, les débats en classe, les synthèses verbales et les séances de questions/réponses.\\n"
                     "  - Soutien Institutionnel : Équipez l'établissement en matériel de sonorisation, archives audio de cours et concours d'art oratoire.");
      } else if (st == 'Visual') {
        linesEn.add("• Recommendations for Visual Learners ($cnt students):\\n"
                     "  - Classroom Instruction: Use structured blackboard layouts, color-coded diagrams, flowcharts, and visual mind maps to illustrate concepts.\\n"
                     "  - Institutional Support: Provide digital projectors, science chart displays, and visual educational media in classrooms.");

        linesFr.add("• Recommandations pour les Apprenants Visuels ($cnt élèves) :\\n"
                     "  - Pratiques Pédagogiques : Utilisez un agencement clair au tableau, des schémas en couleurs, des organigrammes et des cartes conceptuelles.\\n"
                     "  - Soutien Institutionnel : Mettez à disposition des vidéoprojecteurs, planches murales et supports visuels.");
      } else if (st == 'Kinesthetic') {
        linesEn.add("• Recommendations for Kinesthetic Learners ($cnt students):\\n"
                     "  - Classroom Instruction: Incorporate practical demonstrations, hands-on problem sets, concrete real-world case studies, and active tasks.\\n"
                     "  - Institutional Support: Equip laboratories and technical workshops with interactive kits and practical experiment supplies.");

        linesFr.add("• Recommandations pour les Apprenants Kinesthésiques ($cnt élèves) :\\n"
                     "  - Pratiques Pédagogiques : Intégrez des démonstrations pratiques, des résolutions d'exercices concrets et des cas d'application du quotidien.\\n"
                     "  - Soutien Institutionnel : Équipez les laboratoires et ateliers de kits pratiques et matériel d'expérimentation.");
      } else if (st == 'Read/Write') {
        linesEn.add("• Recommendations for Read/Write Learners ($cnt students):\\n"
                     "  - Classroom Instruction: Provide clear written lesson outlines, structured definitions, bulleted summaries, and guided textbook reading exercises.\\n"
                     "  - Institutional Support: Supply school libraries with updated textbooks, reference glossaries, and comprehensive revision manuals.");

        linesFr.add("• Recommandations pour les Apprenants Lecture/Écriture ($cnt élèves) :\\n"
                     "  - Pratiques Pédagogiques : Fournissez des plans de cours écrits, des résumés structurés à puces, des définitions précises et des lectures dirigées.\\n"
                     "  - Soutien Institutionnel : Approvisionnez les bibliothèques scolaires en manuels récents, glossaires et recueils d'exercices.");
      }
    }

    // Append Territorial Multimodal Directive for Unassessed Classes / Schools
    if (isNationalLevel || isRegionalLevel || isSchoolLevel) {
      final scopeEn = isNationalLevel ? "Nationwide & Across Unassessed Classes" : (isRegionalLevel ? "Region-Wide & Across Unassessed Classes" : "School-Wide for Ongoing & Unassessed Classes");
      final scopeFr = isNationalLevel ? "À l'Échelle Nationale & Pour les Classes Non Évaluées" : (isRegionalLevel ? "À l'Échelle Régionale & Pour les Classes Non Évaluées" : "Pour les Classes en Cours d'Évaluation");

      linesEn.add("• Universal Multimodal Pedagogical Directive ($scopeEn):\\n"
                  "  Since diagnostic testing is progressively rolling out and several classes/schools are yet to complete their VARK assessment, educators must encourage and balance all 4 learning modalities:\\n"
                  "  - Visual: Integrate structured diagrams, schema boards, and visual summaries.\\n"
                  "  - Auditory: Maintain interactive oral lectures, verbal recaps, and structured discussions.\\n"
                  "  - Read/Write: Guide textbook readings, concise glossary notes, and written synthesis.\\n"
                  "  - Kinesthetic: Utilize lab demonstrations, practical exercises, and tangible problem sets.\\n"
                  "  - Diagnostic Action: Coordinate with teachers and delegates to ensure 100% assessment coverage across all student cohorts.");

      linesFr.add("• Directive Pédagogique Multimodale Globale ($scopeFr) :\\n"
                  "  Comme le déploiement diagnostique est en cours et que certaines classes/établissements n'ont pas encore finalisé le test VARK, les enseignants doivent encourager et équilibrer les 4 modalités d'apprentissage :\\n"
                  "  - Visuel : Intégrer des schémas clairs au tableau, des synthèses visuelles et des graphiques.\\n"
                  "  - Auditif : Maintenir des explications orales dynamiques, des récapitulatifs verbaux et des débats.\\n"
                  "  - Lecture/Écriture : Guider la lecture des manuels, les définitions structurées et les prises de notes.\\n"
                  "  - Kinesthésique : Proposer des travaux pratiques, des manipulations concrètes et des résolutions actives.\\n"
                  "  - Action Diagnostique : Coordonner avec les enseignants et délégués pour atteindre 100% de couverture de l'évaluation.");
    }

    return {
      'en': linesEn.join('\\n\\n'),
      'fr': linesFr.join('\\n\\n'),
    };
  }'''

engine_code = engine_code[:idx_eval_start] + new_eval_educators + "\n\n" + engine_code[idx_eval_end:]

with open(r'lib/services/vark_academic_engine.dart', 'w', encoding='utf-8') as f:
    f.write(engine_code)

print("SUCCESS: UPDATED vark_academic_engine.dart")
