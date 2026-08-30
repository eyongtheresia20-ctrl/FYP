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
  /// Evaluates scores for individual Student Self-Study.
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

  /// Evaluates scores for TEACHERS, DEANS, PRINCIPALS, DELEGATES, and ADMINS.
  /// Tells educators HOW TO TEACH THE CLASS / SCHOOL so that EVERY SINGLE STUDENT UNDERSTANDS.
  static Map<String, String> evaluateForEducators({
    required num auditory,
    required num visual,
    required num kinesthetic,
    required num readWrite,
    String contextName = '',
  }) {
    final int aud = auditory.toInt();
    final int vis = visual.toInt();
    final int kin = kinesthetic.toInt();
    final int rw  = readWrite.toInt();
    final int totalAssessed = aud + vis + kin + rw;

    if (totalAssessed == 0) {
      final nameSuffix = contextName.isNotEmpty ? ' for $contextName' : '';
      final nameSuffixFr = contextName.isNotEmpty ? ' pour $contextName' : '';
      return {
        'en': "• Diagnostic Phase: Student evaluations are in progress$nameSuffix.\n\n"
              "• Inclusive Multimodal Teaching: Structure every lesson to integrate verbal explanations, blackboard diagrams, structured notes, and practical exercises so every student is engaged.\n\n"
              "• Diagnostic Tracking: Coordinate with teachers and school heads to ensure all enrolled students complete their diagnostic test.",
        'fr': "• Phase Diagnostique : Les évaluations des élèves sont en cours$nameSuffixFr.\n\n"
              "• Enseignement Inclusif Multimodal : Veillez à ce que chaque cours intègre explications orales, schémas au tableau, notes écrites et exercices pratiques pour toucher tous les élèves.\n\n"
              "• Suivi Diagnostique : Coordonnez avec les enseignants et proviseurs pour que l'ensemble des élèves complètent leur test.",
      };
    }

    final Map<String, int> scores = {
      'Auditory': aud,
      'Visual': vis,
      'Kinesthetic': kin,
      'Read/Write': rw,
    };
    final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final dominant = sorted.first.key;
    final domCount = sorted.first.value;
    final domPct = ((domCount / totalAssessed) * 100).round();

    final List<String> linesEn = [];
    final List<String> linesFr = [];

    // 1. Cohort Profile Summary
    linesEn.add("• Class Cohort Profile: $domPct% of assessed students are $dominant learners ($domCount out of $totalAssessed).");
    linesFr.add("• Profil de la Classe : $domPct% des élèves évalués sont de profil ${getModalityNameFr(dominant)} ($domCount sur $totalAssessed).");

    // 2. Primary Instructional Focus for the majority
    if (dominant == 'Auditory') {
      linesEn.add("• Primary Instructional Focus (Auditory): Emphasize clear oral explanations, teacher-led discussions, and verbal summaries. Ask questions aloud and encourage students to explain concepts in their own words.");
      linesFr.add("• Axe Pédagogique Principal (Auditif) : Privilégiez des explications orales claires, des débats guidés et des synthèses verbales. Posez des questions à voix haute et invitez les élèves à reformuler les notions clés.");
    } else if (dominant == 'Visual') {
      linesEn.add("• Primary Instructional Focus (Visual): Use the blackboard effectively with color-coded chalk, visual mind maps, diagrams, and flowcharts. Highlight key lesson headings and structured outlines.");
      linesFr.add("• Axe Pédagogique Principal (Visuel) : Utilisez le tableau avec des craies de couleur, des cartes conceptuelles et des schémas. Mettez en valeur les titres et le plan structuré du cours.");
    } else if (dominant == 'Kinesthetic') {
      linesEn.add("• Primary Instructional Focus (Kinesthetic): Incorporate practical demonstrations, hands-on problem sets, concrete real-world examples, and interactive classroom activities.");
      linesFr.add("• Axe Pédagogique Principal (Kinesthésique) : Intégrez des démonstrations pratiques, des résolutions concrètes d'exercices, des exemples du quotidien et des activités interactives.");
    } else {
      linesEn.add("• Primary Instructional Focus (Read/Write): Provide well-organized written summaries, bulleted board notes, clear definitions, and structured textbook reading exercises.");
      linesFr.add("• Axe Pédagogique Principal (Lecture/Écriture) : Fournissez des résumés écrits clairs, des notes structurées au tableau, des définitions précises et des lectures guidées.");
    }

    // 3. Inclusive Differentiated Instruction (For ALL students in the class)
    linesEn.add("• Inclusive Teaching for All Students:\n"
                 "  - For Visual Learners ($vis students): Draw diagrams, charts, and summary mind maps on the board.\n"
                 "  - For Auditory Learners ($aud students): Read key points aloud, facilitate peer discussion, and summarize verbally.\n"
                 "  - For Kinesthetic Learners ($kin students): Relate abstract formulas to real-life situations and step-by-step problem solving.\n"
                 "  - For Read/Write Learners ($rw students): Ensure students have sufficient time to copy structured notes and review textbook references.");

    linesFr.add("• Enseignement Inclusif pour Tous les Élèves :\n"
                 "  - Pour les élèves Visuels ($vis élèves) : Dessinez des schémas, graphiques et cartes conceptuelles au tableau.\n"
                 "  - Pour les élèves Auditifs ($aud élèves) : Énoncez clairement les points clés, animez des échanges oraux et récapitulez verbalement.\n"
                 "  - Pour les élèves Kinesthésiques ($kin élèves) : Reliez les formules abstraites à des applications concrètes et résolutions pas-à-pas.\n"
                 "  - Pour les élèves Lecture/Écriture ($rw élèves) : Laissez le temps nécessaire pour recopier des notes structurées et référencer les manuels.");

    return {
      'en': linesEn.join('\n\n'),
      'fr': linesFr.join('\n\n'),
    };
  }

  /// Backward-compatible evaluate method
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
