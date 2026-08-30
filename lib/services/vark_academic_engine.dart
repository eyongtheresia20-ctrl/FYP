// ==============================================================================
//  MINESEC L.S.T — Neil Fleming Standardized Academic Interpretation Engine
//  Based on Neil Fleming's (1987) Learning Style Test (L.S.T / T.S.A)
//  Includes: Table 3, Table 4, Table 5, Table 6, and Section 4.5.1 Strategies
// ==============================================================================

class VarkEvaluationResult {
  final String modalityType; // 'Uni-Modal', 'Bi-Modal', 'Tri-Modal', 'Quad-Modal', 'Diagnostic Phase'
  final String primaryModality; // 'Auditory', 'Visual', 'Kinesthetic', 'Read/Write'
  final String learningStyle; // E.g., 'Auditory (Uni-Modal)', 'Auditory-Visual (Bi-Modal)'
  final int primaryCategory; // 1 to 5
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
  /// Evaluates raw scores for Auditory, Visual, Kinesthetic, and Read/Write.
  static VarkEvaluationResult evaluate({
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

    // Find maximum score and tied modalities
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
    if (tiedCount == 4) {
      modalityType = 'Quad-Modal';
    } else if (tiedCount == 3) {
      modalityType = 'Tri-Modal';
    } else if (tiedCount == 2) {
      modalityType = 'Bi-Modal';
    } else if (tiedCount == 0) {
      modalityType = 'Diagnostic Phase';
    }

    // Determine Category for each modality
    final Map<String, int> categories = {};
    if (modalityType == 'Quad-Modal') {
      categories['Auditory']    = getQuadCategory('Auditory', aud);
      categories['Visual']      = getQuadCategory('Visual', vis);
      categories['Kinesthetic'] = getQuadCategory('Kinesthetic', kin);
      categories['Read/Write']  = getQuadCategory('Read/Write', rw);
    } else if (modalityType == 'Tri-Modal') {
      categories['Auditory']    = getBiModalCategory('Auditory', aud);
      categories['Visual']      = getTriCategory('Visual', vis);
      categories['Kinesthetic'] = getTriCategory('Kinesthetic', kin);
      categories['Read/Write']  = getTriCategory('Read/Write', rw);
    } else {
      categories['Auditory']    = getBiModalCategory('Auditory', aud);
      categories['Visual']      = getBiModalCategory('Visual', vis);
      categories['Kinesthetic'] = getBiModalCategory('Kinesthetic', kin);
      categories['Read/Write']  = getBiModalCategory('Read/Write', rw);
    }

    final String primaryModality = topModalities.isNotEmpty ? topModalities.first : 'Auditory';
    final int primaryCategory = categories[primaryModality] ?? 3;

    // Build Table 3 Academic Diagnostics
    final List<String> diagnosticsEn = [];
    final List<String> diagnosticsFr = [];

    bool allLowPreference = true;
    scores.forEach((mod, sc) {
      final cat = categories[mod] ?? 3;
      if (cat >= 3) allLowPreference = false;
    });

    for (var mod in topModalities) {
      final cat = categories[mod] ?? 3;
      final t3 = getTable3Text(mod, cat);
      diagnosticsEn.add('• $mod (Category $cat — ${getCategoryName(cat, isEn: true)}): ${t3['en']}');
      diagnosticsFr.add('• ${getModalityNameFr(mod)} (Catégorie $cat — ${getCategoryName(cat, isEn: false)}) : ${t3['fr']}');
    }

    if (allLowPreference && maxScore > 0) {
      const counselorNoteEn = "N.B.: Category I and II learners for all modalities are recommended for follow-up by a Guidance Counsellor.";
      const counselorNoteFr = "N.B. : Les apprenants de Catégorie I et II pour toutes les modalités sont recommandés pour un suivi par un Conseiller d'Orientation.";
      diagnosticsEn.add(counselorNoteEn);
      diagnosticsFr.add(counselorNoteFr);
    }

    // Build Section 4.5.1 Learning Strategy
    final List<String> strategiesEn = [];
    final List<String> strategiesFr = [];
    for (var mod in topModalities) {
      final strat = getSection451Strategy(mod);
      strategiesEn.add(strat['en'] ?? '');
      strategiesFr.add(strat['fr'] ?? '');
    }

    if (topModalities.isEmpty) {
      diagnosticsEn.add("• Multimodal Diagnostic Phase: Baseline academic assessment is in progress. Balanced sensory engagement across visual, auditory, kinesthetic, and text modalities is recommended.");
      diagnosticsFr.add("• Phase Diagnostique Multimodale : L'évaluation académique initiale est en cours. Une mobilisation équilibrée des modalités visuelle, auditive, kinesthésique et textuelle est recommandée.");
      strategiesEn.add("• Engage in multimodal study: alternate between reading notes, drawing conceptual diagrams, listening to lecture summaries, and completing practical exercises.");
      strategiesFr.add("• Adoptez un apprentissage multimodal : alternez lecture de fiches, schématisation visuelle, écoute de résumés oraux et exercices pratiques.");
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

  /// Table 4: Bi-modal / Uni-modal standardized grading scale (Neil Fleming)
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

  /// Table 5: Summary Table for Tri-Modal Learners Scale
  static int getTriCategory(String modality, double score) {
    switch (modality) {
      case 'Visual':
        if (score < 0.58) return 2;
        if (score <= 2.04) return 3;
        if (score <= 4.96) return 4;
        return 5;
      case 'Kinesthetic':
        if (score < 0.04) return 2;
        if (score <= 1.11) return 3;
        if (score <= 3.25) return 4;
        return 5;
      case 'Read/Write':
        if (score < 1.98) return 2;
        if (score <= 3.83) return 3;
        if (score <= 7.53) return 4;
        return 5;
      default:
        return getBiModalCategory(modality, score);
    }
  }

  /// Table 6: Quad Graded Summary Table
  static int getQuadCategory(String modality, double score) {
    switch (modality) {
      case 'Auditory':
        if (score < 1.4) return 2;
        if (score <= 3.0) return 3;
        if (score <= 6.0) return 4;
        return 5;
      case 'Visual':
        if (score < 0.6) return 2;
        if (score <= 2.0) return 3;
        if (score <= 4.96) return 4;
        return 5;
      case 'Kinesthetic':
        if (score < 0.04) return 2;
        if (score <= 1.0) return 3;
        if (score <= 3.0) return 4;
        return 5;
      case 'Read/Write':
        if (score < 1.98) return 2;
        if (score <= 3.38) return 3;
        if (score <= 7.53) return 4;
        return 5;
      default:
        return getBiModalCategory(modality, score);
    }
  }

  static String getCategoryName(int cat, {required bool isEn}) {
    if (!isEn) {
      switch (cat) {
        case 1: return 'Préférence Très Faible';
        case 2: return 'Préférence Faible';
        case 3: return 'Préférence Modérée';
        case 4: return 'Forte Préférence';
        case 5: return 'Très Forte Préférence';
        default: return 'Modérée';
      }
    } else {
      switch (cat) {
        case 1: return 'Very Low Preference';
        case 2: return 'Low Preference';
        case 3: return 'Mild / Moderate Preference';
        case 4: return 'High / Strong Preference';
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
          ? "Perspectives élevées d'assimilation de l'information et d'engagement dans l'apprentissage. Fort potentiel d'adaptation et de résilience aux études."
          : "High prospects of capturing information and engaging in learning. High prospects for adaptation and resilience to studies.";
    } else if (cat == 3) {
      return !isEn
          ? "Capacité équilibrée d'assimilation de l'information avec une flexibilité d'adaptation entre les différents modes d'apprentissage."
          : "Balanced information intake with flexible adaptation across blended learning modalities.";
    } else {
      return !isEn
          ? "Apprenant à faible réceptivité sur ce mode sensoriel. Un accompagnement ou une diversification des méthodes est recommandé."
          : "Low reliance on this intake mechanism. Methodological reinforcement and multimodal support recommended.";
    }
  }

  /// Table 3: Academic Interpretation of L.S.T Results
  static Map<String, String> getTable3Text(String modality, int category) {
    switch (modality) {
      case 'Auditory':
        switch (category) {
          case 1:
            return {
              'en': "Almost no reliance on auditory intake mechanisms.",
              'fr': "Quasi-absence de recours aux mécanismes de réception auditive."
            };
          case 2:
            return {
              'en': "Minor (weak) auditory reliance. Rarely benefits from pure lectures or discussions.",
              'fr': "Faible recours à l'auditif. Tire rarement profit des cours magistraux ou discussions pures."
            };
          case 3:
            return {
              'en': "Balances auditory learning with other modalities.",
              'fr': "Équilibre l'apprentissage auditif avec les autres modalités pédagogiques."
            };
          case 4:
            return {
              'en': "Strong leaning towards verbal lectures and discussion. High prospects of capturing information and engaging in learning.",
              'fr': "Forte orientation vers les cours oraux et les discussions. Perspectives élevées d'assimilation."
            };
          case 5:
          default:
            return {
              'en': "Extreme reliance on hearing and spoken words. High prospects of capturing information and high resilience to studies.",
              'fr': "Dépendance extrême à l'écoute et à la parole. Fort potentiel d'adaptation et de résilience aux études."
            };
        }

      case 'Visual':
        switch (category) {
          case 1:
            return {
              'en': "Virtually no reliance on visual intake mechanisms.",
              'fr': "Quasi-absence de recours aux mécanismes de réception visuelle."
            };
          case 2:
            return {
              'en': "Below average preference for charts, diagrams or graphs.",
              'fr': "Préférence inférieure à la moyenne pour les graphiques, schémas ou diagrammes."
            };
          case 3:
            return {
              'en': "Regular and flexible use of visual layout when paired with other styles.",
              'fr': "Utilisation régulière et flexible des supports visuels combinés à d'autres styles."
            };
          case 4:
            return {
              'en': "Clear, distinct reliance on spatial design, underlining and charts. High prospects for adaptation and resilience.",
              'fr': "Recours net et distinct à l'agencement spatial, au surlignage et aux graphiques. Fort potentiel de réussite."
            };
          case 5:
          default:
            return {
              'en': "Critical dependence on visual media. Struggles without spatial structure. High prospects of capturing information.",
              'fr': "Dépendance critique aux supports visuels. Difficultés sans repères spatiaux. Très forte assimilation visuelle."
            };
        }

      case 'Kinesthetic':
        switch (category) {
          case 1:
            return {
              'en': "Total absence of physical or experiential reliance.",
              'fr': "Absence totale de recours physique ou expérientiel."
            };
          case 2:
            return {
              'en': "Rarely benefits from hands-on practice, concrete examples or trials.",
              'fr': "Tire rarement profit des travaux pratiques, exemples concrets ou essais."
            };
          case 3:
            return {
              'en': "Regular use of real world examples when blended with other modes.",
              'fr': "Recours régulier aux exemples du monde réel lorsqu'ils sont associés à d'autres modes."
            };
          case 4:
            return {
              'en': "Distinct need for physical manipulation and real life situations. High prospects of engagement.",
              'fr': "Besoin manifeste de manipulation physique et de situations concrètes du quotidien."
            };
          case 5:
          default:
            return {
              'en': "Critical dependency on direct experience. Struggles with pure abstraction. High prospects of capturing practical information.",
              'fr': "Dépendance critique à l'expérience directe. Difficultés avec la pure abstraction. Réussite par la pratique."
            };
        }

      case 'Read/Write':
      default:
        switch (category) {
          case 1:
            return {
              'en': "Complete avoidance of text-heavy or written instruction material.",
              'fr': "Évitement complet des supports d'instruction denses en texte ou purement écrits."
            };
          case 2:
            return {
              'en': "Minimal reliance on text; prefers interactive or visual delivery modes.",
              'fr': "Recours minimal au texte ; préfère les modes de transmission interactifs ou visuels."
            };
          case 3:
            return {
              'en': "Baseline text-literacy. Balances reading / writing with other modalities.",
              'fr': "Alphabétisation textuelle de base. Équilibre la lecture/écriture avec d'autres modalités."
            };
          case 4:
            return {
              'en': "Highly efficient in text processing. Relies heavily on essays, glossaries and manuals. High academic resilience.",
              'fr': "Grande efficacité dans le traitement du texte. S'appuie fortement sur les dissertations et manuels."
            };
          case 5:
          default:
            return {
              'en': "Extreme preference for printed words; critical need for lists and notes. High prospects of capturing structured information.",
              'fr': "Préférence extrême pour les mots imprimés ; besoin critique de listes, notes et fiches de synthèse."
            };
        }
    }
  }

  /// Section 4.5.1: Tailored Academic & Pedagogical Strategies by Neil Fleming (1987)
  static Map<String, String> getSection451Strategy(String modality) {
    switch (modality) {
      case 'Auditory':
        return {
          'en': "🎯 Neil Fleming Academic Strategy for Auditory Learners:\n"
              "• Learns easily by listening to others speak. Benefits greatly from lectures, verbal explanations, and structured discussions.\n"
              "• Speaking Aloud: Speak aloud when studying and reformulate lesson notes in your own words.\n"
              "• Recitation: Reciting lessons to classmates or a study partner reinforces memory, checks knowledge, and sharpens precision.\n"
              "• Auditory Tools: Record key lectures and use phonetic memory aids, songs, rhymes, and oral Q&A sessions.\n"
              "• Freedom of Movement: If needed, walk or mime with book/notes in hand while verbalizing concepts.",

          'fr': "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Auditifs :\n"
              "• Apprend facilement en écoutant parler. Tire un grand bénéfice des cours magistraux, explications orales et débats.\n"
              "• Verbalisation à voix haute : Parlez à voix haute pour apprendre et reformulez vos notes avec vos propres mots.\n"
              "• Récitation active : Réciter vos leçons à un pair aide à mémoriser, vérifier vos connaissances et gagner en précision.\n"
              "• Outils auditifs : Enregistrez les cours importants et utilisez des moyens mnémotechniques phonétiques, rimes et séances de questions/réponses.\n"
              "• Liberté de mouvement : Si nécessaire, marchez ou mimez avec votre cahier en main tout en récitant."
        };

      case 'Visual':
        return {
          'en': "🎯 Neil Fleming Academic Strategy for Visual Learners:\n"
              "• Grasps knowledge through color differentiation, shapes, illustrations, mind maps, flash cards, charts, and diagrams.\n"
              "• Structured Presentation: Pay close attention to notes layout—underline and color-code chapter headings and key paragraphs.\n"
              "• Visual Index Cards: Create index summary cards featuring essential data, diagrams, and visual tables for each chapter.\n"
              "• Visual Mnemonics: Prioritize visual patterns, flowcharts, infographics, and instructional videos.\n"
              "• Active Reading: Always read new or difficult texts with a pencil in hand to sketch diagrams, highlight keywords, and map concepts.",

          'fr': "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Visuels :\n"
              "• Assimile aisément par la différenciation des couleurs, les formes, cartes mentales, fiches, schémas et graphiques.\n"
              "• Présentation soignée : Soignez la mise en page de vos notes—surlignez et codez par couleur les titres et notions clés.\n"
              "• Fiches bristol visuelles : Élaborez des fiches synthétiques claires intégrant les schémas et tableaux essentiels de chaque chapitre.\n"
              "• Mnémotechnique visuelle : Privilégiez les organigrammes, infographies et supports multimédias.\n"
              "• Lecture active : Lisez toujours les textes difficiles avec un crayon en main pour schématiser et noter les mots essentiels."
        };

      case 'Kinesthetic':
        return {
          'en': "🎯 Neil Fleming Academic Strategy for Kinesthetic Learners:\n"
              "• Learns best when actively participating: touching, practicing, experimenting, exploring, and imitating real-world applications.\n"
              "• Physical Activity: Walk back and forth while memorizing; physical movement enhances focus and clears emotional blocks.\n"
              "• Practical Applications: Use hands-on problem sets, laboratory experiments, code implementations, and physical model building.\n"
              "• Recreating Concepts: Translate abstract textbook theories into concrete physical examples and task-based simulations.\n"
              "• Reinforce natural strengths: Structure study sessions around short, active intervals with tangible problem solving.",

          'fr': "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Kinesthésiques :\n"
              "• Apprend au mieux en participant activement : manipuler, pratiquer, expérimenter et imiter des applications concrètes.\n"
              "• Mouvement physique : Marchez d'avant en arrière pendant l'apprentissage ; le mouvement stimule la concentration.\n"
              "• Applications pratiques : Travaillez avec des exercices concrets, travaux pratiques de laboratoire, codage et maquettes.\n"
              "• Reconstitution concrète : Transformez les théories abstraites en exemples physiques et simulations de cas réels.\n"
              "• Renforcement stratégique : Structurez vos révisions en sessions dynamiques rythmées par la résolution d'exercices concrets."
        };

      case 'Read/Write':
      default:
        return {
          'en': "🎯 Neil Fleming Academic Strategy for Read/Write Learners:\n"
              "• Prefers learning through reading, organizing, and summarizing textbooks, handouts, and structured written materials.\n"
              "• Silent Rewriting: Benefit immensely from re-reading and re-writing comprehensive notes silently again and again.\n"
              "• Textual Description: Translate charts, graphs, and visual diagrams into bulleted text descriptions to memorize them.\n"
              "• Reference Materials: Make frequent use of dictionaries, glossaries, encyclopedias, and detailed bibliographies.\n"
              "• Structured Note-Taking: Build organized bulleted lists, essay summaries, and structured revision binders.",

          'fr': "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Lecture / Écriture :\n"
              "• Apprend principalement en lisant, structurant et résumant manuels, polycopiés et documents écrits.\n"
              "• Réécriture silencieuse : Tirez un immense profit de la relecture et de la réécriture silencieuse répétée de vos synthèses.\n"
              "• Description textuelle : Décrivez littéralement par écrit les graphiques et schémas pour mieux les mémoriser.\n"
              "• Matériel de référence : Utilisez activement dictionnaires, glossaires de termes et manuels de cours détaillés.\n"
              "• Prise de notes structurée : Rédigez des fiches organisées en listes à puces, résumés de dissertations et synthèses soignées."
        };
    }
  }
}
