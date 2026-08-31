// ==============================================================================
//  MINESEC L.S.T — Standardized Pedagogical Evaluation & Strategy Engine
//  Provides:
//   1. Student Self-Study Strategies (For Student Dashboard)
//   2. Classroom & Institutional Teaching Strategies (For Teacher, Principal, Delegate, Admin)
// ==============================================================================

class VarkEvaluationResult {
  final String modalityType;
  final String primaryModality;
  final String learningStyle;
  final int primaryCategory;
  final String primaryCategoryNameEn;
  final String primaryCategoryNameFr;
  final Map<String, int> categories;
  final String prospectsSummaryEn;
  final String prospectsSummaryFr;
  final String academicDiagnosticEn;
  final String academicDiagnosticFr;
  final String learningStrategyEn;
  final String learningStrategyFr;
  final String fullRecommendationEn;
  final String fullRecommendationFr;

  VarkEvaluationResult({
    required this.modalityType,
    required this.primaryModality,
    required this.learningStyle,
    required this.primaryCategory,
    required this.primaryCategoryNameEn,
    required this.primaryCategoryNameFr,
    required this.categories,
    required this.prospectsSummaryEn,
    required this.prospectsSummaryFr,
    required this.academicDiagnosticEn,
    required this.academicDiagnosticFr,
    required this.learningStrategyEn,
    required this.learningStrategyFr,
    required this.fullRecommendationEn,
    required this.fullRecommendationFr,
  });
}

class VarkAcademicEngine {
  static VarkEvaluationResult evaluateForStudent({
    required num auditory,
    required num visual,
    required num kinesthetic,
    required num readWrite,
  }) {
    final double aud = auditory.toDouble();
    final double vis = visual.toDouble();
    final double kin = kinesthetic.toDouble();
    final double rw  = readWrite.toDouble();

    final Map<String, double> scores = {
      'Auditory': aud,
      'Visual': vis,
      'Kinesthetic': kin,
      'Read/Write': rw,
    };

    double maxScore = 0;
    scores.forEach((key, val) {
      if (val > maxScore) maxScore = val;
    });

    final List<String> topModalities = [];
    if (maxScore > 0) {
      scores.forEach((mod, sc) {
        if ((sc - maxScore).abs() < 0.001) {
          topModalities.add(mod);
        }
      });
    }

    final int tiedCount = topModalities.length;
    String modalityType = 'Uni-Modal';
    if (tiedCount == 4) modalityType = 'Quad-Modal';
    else if (tiedCount == 3) modalityType = 'Tri-Modal';
    else if (tiedCount == 2) modalityType = 'Bi-Modal';
    else if (tiedCount == 0) modalityType = 'Diagnostic Phase';

    final Map<String, int> categories = {
      'Auditory': getBiModalCategory('Auditory', aud),
      'Visual': getBiModalCategory('Visual', vis),
      'Kinesthetic': getBiModalCategory('Kinesthetic', kin),
      'Read/Write': getBiModalCategory('Read/Write', rw),
    };

    final String primaryModality = topModalities.isNotEmpty ? topModalities.first : 'Auditory';
    final int primaryCategory = categories[primaryModality] ?? 3;

    final List<String> diagnosticsEn = [];
    final List<String> diagnosticsFr = [];

    for (var mod in topModalities) {
      final cat = categories[mod] ?? 3;
      final t3 = getTable3Text(mod, cat);
      diagnosticsEn.add('• $mod (${getCategoryName(cat, isEn: true)}): ${t3['en']}');
      diagnosticsFr.add('• ${getModalityNameFr(mod)} (${getCategoryName(cat, isEn: false)}) : ${t3['fr']}');
    }

    final List<String> strategiesEn = [];
    final List<String> strategiesFr = [];
    for (var mod in topModalities) {
      final strat = getStudentStudyStrategy(mod);
      strategiesEn.add(strat['en'] ?? '');
      strategiesFr.add(strat['fr'] ?? '');
    }

    if (topModalities.isEmpty) {
      diagnosticsEn.add("• Diagnostic Phase: Assessment in progress. Multimodal study techniques are recommended.");
      diagnosticsFr.add("• Phase Diagnostique : Évaluation en cours. L'adoption de techniques d'étude multimodales est recommandée.");
      strategiesEn.add("• Study using varied methods: combine reading notes, drawing mind maps, listening to lecture recordings, and doing practical exercises.");
      strategiesFr.add("• Variez vos méthodes d'étude : alternez lecture de fiches, schématisation, écoute de résumés oraux et exercices pratiques.");
    }

    final String learningStyleLabel = topModalities.length > 1
        ? '${topModalities.join("-")} ($modalityType)'
        : (topModalities.isNotEmpty ? topModalities.first : 'Multimodal');

    return VarkEvaluationResult(
      modalityType: modalityType,
      primaryModality: primaryModality,
      learningStyle: learningStyleLabel,
      primaryCategory: primaryCategory,
      primaryCategoryNameEn: getCategoryName(primaryCategory, isEn: true),
      primaryCategoryNameFr: getCategoryName(primaryCategory, isEn: false),
      categories: categories,
      prospectsSummaryEn: getProspectsSummary(primaryCategory, isEn: true),
      prospectsSummaryFr: getProspectsSummary(primaryCategory, isEn: false),
      academicDiagnosticEn: diagnosticsEn.join('\n'),
      academicDiagnosticFr: diagnosticsFr.join('\n'),
      learningStrategyEn: strategiesEn.join('\n\n'),
      learningStrategyFr: strategiesFr.join('\n\n'),
      fullRecommendationEn: '${diagnosticsEn.join("\n")}\n\n${strategiesEn.join("\n\n")}',
      fullRecommendationFr: '${diagnosticsFr.join("\n")}\n\n${strategiesFr.join("\n\n")}',
    );
  }

  static Map<String, String> evaluateForEducators({
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
          'en': "• National Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently underway nationwide across secondary and technical schools.\n\n"
                "• Universal Multimodal Educational Policy: All pedagogical inspectors, regional delegates, and educators must encourage and balance all 4 learning modalities equally (Visual, Auditory, Read/Write, Kinesthetic) across all academic curricula.\n\n"
                "• National Assessment Supervision: Mobilize regional and divisional delegations to ensure all enrolled secondary students complete their diagnostic VARK test.",
          'fr': "• Stratégie Multimodale Nationale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans l'ensemble des établissements secondaires et techniques du territoire.\n\n"
                "• Politique Éducative Multimodale Globale : L'ensemble des inspecteurs pédagogiques, délégués régionaux et enseignants doivent encourager équitablement les 4 modalités d'apprentissage (Visuel, Auditif, Lecture/Écriture, Kinesthésique).\n\n"
                "• Suivi National des Évaluations : Mobiliser les délégations régionales et départementales pour que l'ensemble des élèves complètent leur test diagnostique.",
        };
      } else if (isSchoolLevel) {
        return {
          'en': "• Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently in progress across classes in $contextName.\n\n"
                "• School-Wide Multimodal Instruction: Head teachers and pedagogical staff should encourage all learning styles equally by ensuring every subject incorporates verbal lectures, visual diagrams, structured texts, and practical exercises.\n\n"
                "• Diagnostic Supervision: Coordinate with class teachers to ensure all enrolled students complete their diagnostic VARK test.",
          'fr': "• Stratégie Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans les classes de $contextName.\n\n"
                "• Enseignement Multimodal Global : Les équipes pédagogiques doivent encourager équitablement tous les styles d'apprentissage en combinant explications orales, supports visuels, fiches écrites et travaux pratiques.\n\n"
                "• Suivi Diagnostique : Coordonnez avec les professeurs principaux pour que l'ensemble des élèves complètent leur évaluation.",
        };
      } else {
        return {
          'en': "• Multimodal Teaching Strategy (Diagnostic Phase): No students have completed the VARK assessment in $contextName yet.\n\n"
                "• Differentiated Classroom Engagement: Encourage and stimulate all learning styles equally through multimodal instruction—combining oral explanations, whiteboard diagrams, written notes, and hands-on exercises.\n\n"
                "• Assessment Coordination: Encourage all students in this class to complete their diagnostic test on the platform.",
          'fr': "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Aucun élève n'a encore complété le test VARK en $contextName.\n\n"
                "• Enseignement Inclusif & Équilibré : Encouragez et mobilisez équitablement tous les styles d'apprentissage (explications orales, schémas au tableau, notes écrites et exercices pratiques).\n\n"
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
      headerPrefixFr = '• Profil de la Cohorte Évaluée de l\'Établissement';
    }

    linesEn.add("$headerPrefixEn: ${partsEn.join(', ')} out of $totalAssessed assessed students.");
    linesFr.add("$headerPrefixFr : ${partsFr.join(', ')} sur $totalAssessed élèves évalués.");

    for (var entry in sorted) {
      final st = entry.key;
      final cnt = entry.value;

      if (st == 'Auditory') {
        linesEn.add("• Recommendations for Auditory Learners ($cnt students):\n"
                     "  - Classroom Instruction: Emphasize clear oral explanations, structured class discussions, verbal lecture summaries, and oral Q&A reviews.\n"
                     "  - Institutional Support: Prioritize public address systems, audio recording tools for lesson archives, and school debate seminars.");

        linesFr.add("• Recommandations pour les Apprenants Auditifs ($cnt élèves) :\n"
                     "  - Pratiques Pédagogiques : Privilégiez les explications orales structurées, les débats en classe, les synthèses verbales et les séances de questions/réponses.\n"
                     "  - Soutien Institutionnel : Équipez l'établissement en matériel de sonorisation, archives audio de cours et concours d'art oratoire.");
      } else if (st == 'Visual') {
        linesEn.add("• Recommendations for Visual Learners ($cnt students):\n"
                     "  - Classroom Instruction: Use structured blackboard layouts, color-coded diagrams, flowcharts, and visual mind maps to illustrate concepts.\n"
                     "  - Institutional Support: Provide digital projectors, science chart displays, and visual educational media in classrooms.");

        linesFr.add("• Recommandations pour les Apprenants Visuels ($cnt élèves) :\n"
                     "  - Pratiques Pédagogiques : Utilisez un agencement clair au tableau, des schémas en couleurs, des organigrammes et des cartes conceptuelles.\n"
                     "  - Soutien Institutionnel : Mettez à disposition des vidéoprojecteurs, planches murales et supports visuels.");
      } else if (st == 'Kinesthetic') {
        linesEn.add("• Recommendations for Kinesthetic Learners ($cnt students):\n"
                     "  - Classroom Instruction: Incorporate practical demonstrations, hands-on problem sets, concrete real-world case studies, and active tasks.\n"
                     "  - Institutional Support: Equip laboratories and technical workshops with interactive kits and practical experiment supplies.");

        linesFr.add("• Recommandations pour les Apprenants Kinesthésiques ($cnt élèves) :\n"
                     "  - Pratiques Pédagogiques : Intégrez des démonstrations pratiques, des résolutions d'exercices concrets et des cas d'application du quotidien.\n"
                     "  - Soutien Institutionnel : Équipez les laboratoires et ateliers de kits pratiques et matériel d'expérimentation.");
      } else if (st == 'Read/Write') {
        linesEn.add("• Recommendations for Read/Write Learners ($cnt students):\n"
                     "  - Classroom Instruction: Provide clear written lesson outlines, structured definitions, bulleted summaries, and guided textbook reading exercises.\n"
                     "  - Institutional Support: Supply school libraries with updated textbooks, reference glossaries, and comprehensive revision manuals.");

        linesFr.add("• Recommandations pour les Apprenants Lecture/Écriture ($cnt élèves) :\n"
                     "  - Pratiques Pédagogiques : Fournissez des plans de cours écrits, des résumés structurés à puces, des définitions précises et des lectures dirigées.\n"
                     "  - Soutien Institutionnel : Approvisionnez les bibliothèques scolaires en manuels récents, glossaires et recueils d'exercices.");
      }
    }

    // Append Territorial Multimodal Directive for Unassessed Classes / Schools
    if (isNationalLevel || isRegionalLevel || isSchoolLevel) {
      final scopeEn = isNationalLevel ? "Nationwide & Across Unassessed Classes" : (isRegionalLevel ? "Region-Wide & Across Unassessed Classes" : "School-Wide for Ongoing & Unassessed Classes");
      final scopeFr = isNationalLevel ? "À l'Échelle Nationale & Pour les Classes Non Évaluées" : (isRegionalLevel ? "À l'Échelle Régionale & Pour les Classes Non Évaluées" : "Pour les Classes en Cours d'Évaluation");

      linesEn.add("• Universal Multimodal Pedagogical Directive ($scopeEn):\n"
                  "  Since diagnostic testing is progressively rolling out and several classes/schools are yet to complete their VARK assessment, educators must encourage and balance all 4 learning modalities:\n"
                  "  - Visual: Integrate structured diagrams, schema boards, and visual summaries.\n"
                  "  - Auditory: Maintain interactive oral lectures, verbal recaps, and structured discussions.\n"
                  "  - Read/Write: Guide textbook readings, concise glossary notes, and written synthesis.\n"
                  "  - Kinesthetic: Utilize lab demonstrations, practical exercises, and tangible problem sets.\n"
                  "  - Diagnostic Action: Coordinate with teachers and delegates to ensure 100% assessment coverage across all student cohorts.");

      linesFr.add("• Directive Pédagogique Multimodale Globale ($scopeFr) :\n"
                  "  Comme le déploiement diagnostique est en cours et que certaines classes/établissements n'ont pas encore finalisé le test VARK, les enseignants doivent encourager et équilibrer les 4 modalités d'apprentissage :\n"
                  "  - Visuel : Intégrer des schémas clairs au tableau, des synthèses visuelles et des graphiques.\n"
                  "  - Auditif : Maintenir des explications orales dynamiques, des récapitulatifs verbaux et des débats.\n"
                  "  - Lecture/Écriture : Guider la lecture des manuels, les définitions structurées et les prises de notes.\n"
                  "  - Kinesthésique : Proposer des travaux pratiques, des manipulations concrètes et des résolutions actives.\n"
                  "  - Action Diagnostique : Coordonner avec les enseignants et délégués pour atteindre 100% de couverture de l'évaluation.");
    }

    return {
      'en': linesEn.join('\n\n'),
      'fr': linesFr.join('\n\n'),
    };
  }

  static VarkEvaluationResult evaluate({
    required num auditory,
    required num visual,
    required num kinesthetic,
    required num readWrite,
  }) {
    return evaluateForStudent(
      auditory: auditory,
      visual: visual,
      kinesthetic: kinesthetic,
      readWrite: readWrite,
    );
  }

  static int getBiModalCategory(String modality, double score) {
    switch (modality) {
      case 'Auditory':
        if (score <= 1) return 1;
        if (score <= 2) return 2;
        if (score <= 3) return 3;
        if (score <= 4) return 4;
        return 5;
      case 'Visual':
        if (score <= 0) return 1;
        if (score <= 1) return 2;
        if (score <= 2) return 3;
        if (score <= 3) return 4;
        return 5;
      case 'Kinesthetic':
        if (score <= 0) return 1;
        if (score <= 1.0) return 2;
        if (score <= 1.5) return 3;
        if (score <= 2.0) return 4;
        return 5;
      case 'Read/Write':
        if (score <= 2) return 1;
        if (score <= 3) return 2;
        if (score <= 4) return 3;
        if (score <= 5) return 4;
        return 5;
      default:
        return 3;
    }
  }

  static String getCategoryName(int cat, {required bool isEn}) {
    if (!isEn) {
      switch (cat) {
        case 1: return 'Préférence Faible';
        case 2: return 'Préférence Faible';
        case 3: return 'Préférence Modérée';
        case 4: return 'Forte Préférence';
        case 5: return 'Très Forte Préférence';
        default: return 'Modérée';
      }
    } else {
      switch (cat) {
        case 1: return 'Low Preference';
        case 2: return 'Low Preference';
        case 3: return 'Moderate Preference';
        case 4: return 'Strong Preference';
        case 5: return 'Very Strong Preference';
        default: return 'Moderate';
      }
    }
  }

  static String getModalityNameFr(String mod) {
    switch (mod) {
      case 'Auditory': return 'Auditif';
      case 'Visual': return 'Visuel';
      case 'Kinesthetic': return 'Kinesthésique';
      case 'Read/Write': return 'Lecture / Écriture';
      default: return mod;
    }
  }

  static String getProspectsSummary(int cat, {required bool isEn}) {
    if (cat >= 4) {
      return !isEn
          ? "Perspectives élevées d'assimilation de l'information et d'engagement dans l'apprentissage."
          : "High prospects of capturing information and engaging in learning.";
    } else if (cat == 3) {
      return !isEn
          ? "Capacité équilibrée d'assimilation avec une bonne adaptabilité."
          : "Balanced information intake with good learning adaptability.";
    } else {
      return !isEn
          ? "Faible recours à ce mode. Un accompagnement multimodal est conseillé."
          : "Low reliance on this mode. Multimodal learning support recommended.";
    }
  }

  static Map<String, String> getTable3Text(String modality, int category) {
    switch (modality) {
      case 'Auditory':
        switch (category) {
          case 1: return {'en': "Almost no reliance on auditory intake.", 'fr': "Quasi-absence de recours à l'écoute."};
          case 2: return {'en': "Minor auditory reliance. Rarely benefits from pure lectures.", 'fr': "Faible recours à l'auditif. Tire peu profit des cours magistraux."};
          case 3: return {'en': "Balances auditory learning with other modalities.", 'fr': "Équilibre l'écoute avec les autres styles."};
          case 4: return {'en': "Strong leaning towards verbal explanations and discussions.", 'fr': "Forte orientation vers les explications orales et discussions."};
          case 5:
          default: return {'en': "Extreme reliance on hearing and spoken words.", 'fr': "Forte prédominance de l'écoute et de l'expression orale."};
        }
      case 'Visual':
        switch (category) {
          case 1: return {'en': "Virtually no reliance on visual intake.", 'fr': "Quasi-absence de recours au visuel."};
          case 2: return {'en': "Below average preference for charts and diagrams.", 'fr': "Préférence faible pour les graphiques et schémas."};
          case 3: return {'en': "Regular and flexible use of visual layouts.", 'fr': "Utilisation équilibrée des supports visuels."};
          case 4: return {'en': "Clear reliance on spatial design, underlining, and diagrams.", 'fr': "Recours marqué à l'organisation spatiale et aux schémas."};
          case 5:
          default: return {'en': "Critical dependence on visual media and spatial structure.", 'fr': "Dépendance élevée aux supports visuels et structurés."};
        }
      case 'Kinesthetic':
        switch (category) {
          case 1: return {'en': "Total absence of physical or experiential reliance.", 'fr': "Absence de recours aux activités pratiques."};
          case 2: return {'en': "Rarely benefits from hands-on trials.", 'fr': "Tire peu profit des manipulations physiques."};
          case 3: return {'en': "Regular use of real-world examples with other modes.", 'fr': "Recours équilibré aux exemples concrets."};
          case 4: return {'en': "Distinct need for physical manipulation and practical situations.", 'fr': "Besoin net de pratique et de situations concrètes."};
          case 5:
          default: return {'en': "Critical dependency on direct hands-on experience.", 'fr': "Apprentissage optimal par l'expérience et la pratique."};
        }
      case 'Read/Write':
      default:
        switch (category) {
          case 1: return {'en': "Complete avoidance of text-heavy material.", 'fr': "Évitement des textes longs."};
          case 2: return {'en': "Minimal reliance on text; prefers interactive delivery.", 'fr': "Recours limité à l'écrit seul."};
          case 3: return {'en': "Baseline text literacy balanced with other modalities.", 'fr': "Bon équilibre entre lecture/écriture et autres styles."};
          case 4: return {'en': "Highly efficient in text processing and note-taking.", 'fr': "Grande aisance dans la prise de notes et la lecture."};
          case 5:
          default: return {'en': "Extreme preference for printed words and structured notes.", 'fr': "Préférence marquée pour les synthèses écrites et listes."};
        }
    }
  }

  static Map<String, String> getStudentStudyStrategy(String modality) {
    switch (modality) {
      case 'Auditory':
        return {
          'en': "• Speaking Aloud: Read notes aloud when studying and rephrase concepts in your own words.\n"
              "• Discussion: Explain lessons to classmates or study partners to check understanding.\n"
              "• Audio Tools: Listen to recorded lecture summaries, rhymes, and oral Q&A reviews.",

          'fr': "• Verbalisation à voix haute : Lisez vos résumés à voix haute et reformulez les leçons avec vos mots.\n"
              "• Échange : Expliquez le cours à un camarade pour tester votre compréhension.\n"
              "• Outils audio : Écoutez des résumés oraux et enregistrements de cours."
        };

      case 'Visual':
        return {
          'en': "• Color-Coded Notes: Underline and highlight key headings and terms with distinct colors.\n"
              "• Mind Maps & Diagrams: Create flowcharts, diagrams, and flashcards to visualize concepts.\n"
              "• Active Reading: Sketch key points and diagrams in the margin while reading.",

          'fr': "• Notes en couleur : Surlignez les titres et notions clés avec des couleurs variées.\n"
              "• Schémas & Cartes : Dessinez des cartes mentales, organigrammes et fiches synthétiques.\n"
              "• Lecture active : Dessinez les points essentiels dans la marge lors de la lecture."
        };

      case 'Kinesthetic':
        return {
          'en': "• Hands-on Practice: Solve plenty of practical exercises, laboratory problems, and real-world cases.\n"
              "• Active Movement: Walk around while memorizing to maintain high focus.\n"
              "• Task Simulation: Relate textbook theories to concrete everyday applications.",

          'fr': "• Pratique active : Résolvez de nombreux exercices d'application et cas concrets.\n"
              "• Mouvement : Marchez pendant la mémorisation pour maintenir une concentration élevée.\n"
              "• Exemples réels : Reliez les théories du cours à des situations concrètes du quotidien."
        };

      case 'Read/Write':
      default:
        return {
          'en': "• Silent Rewriting: Re-read and rewrite comprehensive summary notes silently.\n"
              "• Textual Descriptions: Turn diagrams and charts into structured bulleted text.\n"
              "• Glossaries & Manuals: Keep organized lists of definitions and textbook references.",

          'fr': "• Réécriture silencieuse : Relisez et réécrivez vos fiches de synthèse en silence.\n"
              "• Synthèse textuelle : Décrivez par écrit les schémas et graphiques.\n"
              "• Glossaires : Maintenez des listes organisées de définitions et formules."
        };
    }
  }
}
