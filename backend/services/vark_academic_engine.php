<?php
// ==============================================================================
//  MINESEC L.S.T — Neil Fleming Standardized Academic Interpretation Engine
//  Based on Neil Fleming's (1987) Learning Style Test (L.S.T / T.S.A)
//  Includes: Table 3, Table 4, Table 5, Table 6, and Section 4.5.1 Strategies
// ==============================================================================

class VarkAcademicEngine {

    /**
     * Evaluates raw scores for Auditory, Visual, Kinesthetic, and Read/Write.
     * Returns full academic classification, category breakdown, Table 3 diagnostics, and 4.5.1 strategies.
     */
    public static function evaluate($auditory, $visual, $kinesthetic, $readWrite, $lang = 'en') {
        $auditory    = floatval($auditory);
        $visual      = floatval($visual);
        $kinesthetic = floatval($kinesthetic);
        $readWrite   = floatval($readWrite);

        $scores = [
            'Auditory'    => $auditory,
            'Visual'      => $visual,
            'Kinesthetic' => $kinesthetic,
            'Read/Write'  => $readWrite,
        ];

        // Find maximum score and tied modalities
        $maxScore = max($scores);
        $topModalities = [];
        foreach ($scores as $mod => $sc) {
            if (abs($sc - $maxScore) < 0.001 && $sc > 0) {
                $topModalities[] = $mod;
            }
        }

        $tiedCount = count($topModalities);
        $modalityType = 'Uni-Modal';
        if ($tiedCount === 4) {
            $modalityType = 'Quad-Modal';
        } elseif ($tiedCount === 3) {
            $modalityType = 'Tri-Modal';
        } elseif ($tiedCount === 2) {
            $modalityType = 'Bi-Modal';
        } elseif ($tiedCount === 0) {
            // All zeros
            $modalityType = 'Diagnostic Phase';
        }

        // Determine Category for each modality
        $categories = [];
        if ($modalityType === 'Quad-Modal') {
            // Table 6: Quad Graded Summary Table
            $categories['Auditory']    = self::getQuadCategory('Auditory', $auditory);
            $categories['Visual']      = self::getQuadCategory('Visual', $visual);
            $categories['Kinesthetic'] = self::getQuadCategory('Kinesthetic', $kinesthetic);
            $categories['Read/Write']  = self::getQuadCategory('Read/Write', $readWrite);
        } elseif ($modalityType === 'Tri-Modal') {
            // Table 5: Tri-Modal Scale
            $categories['Auditory']    = self::getBiModalCategory('Auditory', $auditory);
            $categories['Visual']      = self::getTriCategory('Visual', $visual);
            $categories['Kinesthetic'] = self::getTriCategory('Kinesthetic', $kinesthetic);
            $categories['Read/Write']  = self::getTriCategory('Read/Write', $readWrite);
        } else {
            // Table 4: Uni-Modal & Bi-Modal Standardized Scale
            $categories['Auditory']    = self::getBiModalCategory('Auditory', $auditory);
            $categories['Visual']      = self::getBiModalCategory('Visual', $visual);
            $categories['Kinesthetic'] = self::getBiModalCategory('Kinesthetic', $kinesthetic);
            $categories['Read/Write']  = self::getBiModalCategory('Read/Write', $readWrite);
        }

        // Determine primary dominant category
        $primaryModality = !empty($topModalities) ? $topModalities[0] : 'Auditory';
        $primaryCategory = $categories[$primaryModality] ?? 3;

        // Build Table 3 Academic Diagnostic Interpretation
        $diagnosticsEn = [];
        $diagnosticsFr = [];

        $allLowPreference = true;
        foreach ($scores as $mod => $sc) {
            $cat = $categories[$mod];
            if ($cat >= 3) $allLowPreference = false;
        }

        foreach ($topModalities as $mod) {
            $cat = $categories[$mod];
            $t3 = self::getTable3Text($mod, $cat);
            $diagnosticsEn[] = "• {$mod} (Category {$cat} — " . self::getCategoryName($cat, 'en') . "): {$t3['en']}";
            $diagnosticsFr[] = "• " . self::getModalityNameFr($mod) . " (Catégorie {$cat} — " . self::getCategoryName($cat, 'fr') . ") : {$t3['fr']}";
        }

        if ($allLowPreference && $maxScore > 0) {
            $counselorNoteEn = "N.B.: Category I and II learners for all modalities are recommended for follow-up by a Guidance Counsellor.";
            $counselorNoteFr = "N.B. : Les apprenants de Catégorie I et II pour toutes les modalités sont recommandés pour un suivi par un Conseiller d'Orientation.";
            $diagnosticsEn[] = $counselorNoteEn;
            $diagnosticsFr[] = $counselorNoteFr;
        }

        // Build Section 4.5.1 Learning Strategy
        $strategiesEn = [];
        $strategiesFr = [];
        foreach ($topModalities as $mod) {
            $strat = self::getSection451Strategy($mod);
            $strategiesEn[] = $strat['en'];
            $strategiesFr[] = $strat['fr'];
        }

        // If diagnostic phase / no score
        if (empty($topModalities)) {
            $diagnosticsEn = ["• Multimodal Diagnostic Phase: Baseline academic assessment is in progress. Balanced sensory engagement across visual, auditory, kinesthetic, and text modalities is recommended."];
            $diagnosticsFr = ["• Phase Diagnostique Multimodale : L'évaluation académique initiale est en cours. Une mobilisation équilibrée des modalités visuelle, auditive, kinesthésique et textuelle est recommandée."];
            $strategiesEn = ["• Engage in multimodal study: alternate between reading notes, drawing conceptual diagrams, listening to lecture summaries, and completing practical exercises."];
            $strategiesFr = ["• Adoptez un apprentissage multimodal : alternez lecture de fiches, schématisation visuelle, écoute de résumés oraux et exercices pratiques."];
        }

        $learningStyleLabel = count($topModalities) > 1 
            ? implode('-', $topModalities) . " ({$modalityType})"
            : ($topModalities[0] ?? 'Multimodal');

        return [
            'modality_type'       => $modalityType,
            'primary_modality'    => $primaryModality,
            'learning_style'      => $learningStyleLabel,
            'primary_category'    => $primaryCategory,
            'primary_category_name_en' => self::getCategoryName($primaryCategory, 'en'),
            'primary_category_name_fr' => self::getCategoryName($primaryCategory, 'fr'),
            'categories'          => $categories,
            'prospects_summary_en' => self::getProspectsSummary($primaryCategory, 'en'),
            'prospects_summary_fr' => self::getProspectsSummary($primaryCategory, 'fr'),
            'academic_diagnostic_en' => implode("\n", $diagnosticsEn),
            'academic_diagnostic_fr' => implode("\n", $diagnosticsFr),
            'learning_strategy_en'   => implode("\n\n", $strategiesEn),
            'learning_strategy_fr'   => implode("\n\n", $strategiesFr),
            'full_recommendation_en' => implode("\n", $diagnosticsEn) . "\n\n" . implode("\n\n", $strategiesEn),
            'full_recommendation_fr' => implode("\n", $diagnosticsFr) . "\n\n" . implode("\n\n", $strategiesFr),
        ];
    }

    /**
     * Table 4: Bi-modal / Uni-modal standardized grading scale (Neil Fleming)
     */
    public static function getBiModalCategory($modality, $score) {
        $score = floatval($score);
        switch ($modality) {
            case 'Auditory':
                if ($score <= 1) return 1;
                if ($score <= 2) return 2;
                if ($score <= 3) return 3;
                if ($score <= 4) return 4;
                return 5; // >= 5
            case 'Visual':
                if ($score <= 0) return 1;
                if ($score <= 1) return 2;
                if ($score <= 2) return 3;
                if ($score <= 3) return 4;
                return 5; // >= 4
            case 'Kinesthetic':
                if ($score <= 0) return 1;
                if ($score <= 1.0) return 2;
                if ($score <= 1.5) return 3;
                if ($score <= 2.0) return 4;
                return 5; // > 2
            case 'Read/Write':
                if ($score <= 2) return 1;
                if ($score <= 3) return 2;
                if ($score <= 4) return 3;
                if ($score <= 5) return 4;
                return 5; // > 5
            default:
                return 3;
        }
    }

    /**
     * Table 5: Summary Table for Tri-Modal Learners Scale
     */
    public static function getTriCategory($modality, $score) {
        $score = floatval($score);
        switch ($modality) {
            case 'Visual':
                if ($score < 0.58) return 2;
                if ($score <= 2.04) return 3;
                if ($score <= 4.96) return 4;
                return 5;
            case 'Kinesthetic':
                if ($score < 0.04) return 2;
                if ($score <= 1.11) return 3;
                if ($score <= 3.25) return 4;
                return 5;
            case 'Read/Write':
                if ($score < 1.98) return 2;
                if ($score <= 3.83) return 3;
                if ($score <= 7.53) return 4;
                return 5;
            default:
                return self::getBiModalCategory($modality, $score);
        }
    }

    /**
     * Table 6: Quad Graded Summary Table
     */
    public static function getQuadCategory($modality, $score) {
        $score = floatval($score);
        switch ($modality) {
            case 'Auditory':
                if ($score < 1.4) return 2;
                if ($score <= 3.0) return 3;
                if ($score <= 6.0) return 4;
                return 5;
            case 'Visual':
                if ($score < 0.6) return 2;
                if ($score <= 2.0) return 3;
                if ($score <= 4.96) return 4;
                return 5;
            case 'Kinesthetic':
                if ($score < 0.04) return 2;
                if ($score <= 1.0) return 3;
                if ($score <= 3.0) return 4;
                return 5;
            case 'Read/Write':
                if ($score < 1.98) return 2;
                if ($score <= 3.38) return 3;
                if ($score <= 7.53) return 4;
                return 5;
            default:
                return self::getBiModalCategory($modality, $score);
        }
    }

    /**
     * Category Name Lookup
     */
    public static function getCategoryName($cat, $lang = 'en') {
        if ($lang === 'fr') {
            switch ($cat) {
                case 1: return 'Préférence Très Faible';
                case 2: return 'Préférence Faible';
                case 3: return 'Préférence Modérée';
                case 4: return 'Forte Préférence';
                case 5: return 'Très Forte Préférence';
                default: return 'Modérée';
            }
        } else {
            switch ($cat) {
                case 1: return 'Very Low Preference';
                case 2: return 'Low Preference';
                case 3: return 'Mild / Moderate Preference';
                case 4: return 'High / Strong Preference';
                case 5: return 'Very Strong Preference';
                default: return 'Moderate';
            }
        }
    }

    public static function getModalityNameFr($mod) {
        switch ($mod) {
            case 'Auditory': return 'Auditif';
            case 'Visual': return 'Visuel';
            case 'Kinesthetic': return 'Kinesthésique';
            case 'Read/Write': return 'Lecture / Écriture';
            default: return $mod;
        }
    }

    /**
     * Prospects and Academic Resilience Summary (Table 3 Headers)
     */
    public static function getProspectsSummary($cat, $lang = 'en') {
        if ($cat >= 4) {
            return ($lang === 'fr')
                ? "Perspectives élevées d'assimilation de l'information et d'engagement dans l'apprentissage. Fort potentiel d'adaptation et de résilience aux études."
                : "High prospects of capturing information and engaging in learning. High prospects for adaptation and resilience to studies.";
        } elseif ($cat === 3) {
            return ($lang === 'fr')
                ? "Capacité équilibrée d'assimilation de l'information avec une flexibilité d'adaptation entre les différents modes d'apprentissage."
                : "Balanced information intake with flexible adaptation across blended learning modalities.";
        } else {
            return ($lang === 'fr')
                ? "Apprenant à faible réceptivité sur ce mode sensoriel. Un accompagnement ou une diversification des méthodes est recommandé."
                : "Low reliance on this intake mechanism. Methodological reinforcement and multimodal support recommended.";
        }
    }

    /**
     * Table 3: Academic Interpretation of L.S.T Results
     */
    public static function getTable3Text($modality, $category) {
        switch ($modality) {
            case 'Auditory':
                switch ($category) {
                    case 1:
                        return [
                            'en' => "Almost no reliance on auditory intake mechanisms.",
                            'fr' => "Quasi-absence de recours aux mécanismes de réception auditive."
                        ];
                    case 2:
                        return [
                            'en' => "Minor (weak) auditory reliance. Rarely benefits from pure lectures or discussions.",
                            'fr' => "Faible recours à l'auditif. Tire rarement profit des cours magistraux ou discussions pures."
                        ];
                    case 3:
                        return [
                            'en' => "Balances auditory learning with other modalities.",
                            'fr' => "Équilibre l'apprentissage auditif avec les autres modalités pédagogiques."
                        ];
                    case 4:
                        return [
                            'en' => "Strong leaning towards verbal lectures and discussion. High prospects of capturing information and engaging in learning.",
                            'fr' => "Forte orientation vers les cours oraux et les discussions. Perspectives élevées d'assimilation."
                        ];
                    case 5:
                    default:
                        return [
                            'en' => "Extreme reliance on hearing and spoken words. High prospects of capturing information and high resilience to studies.",
                            'fr' => "Dépendance extrême à l'écoute et à la parole. Fort potentiel d'adaptation et de résilience aux études."
                        ];
                }

            case 'Visual':
                switch ($category) {
                    case 1:
                        return [
                            'en' => "Virtually no reliance on visual intake mechanisms.",
                            'fr' => "Quasi-absence de recours aux mécanismes de réception visuelle."
                        ];
                    case 2:
                        return [
                            'en' => "Below average preference for charts, diagrams or graphs.",
                            'fr' => "Préférence inférieure à la moyenne pour les graphiques, schémas ou diagrammes."
                        ];
                    case 3:
                        return [
                            'en' => "Regular and flexible use of visual layout when paired with other styles.",
                            'fr' => "Utilisation régulière et flexible des supports visuels combinés à d'autres styles."
                        ];
                    case 4:
                        return [
                            'en' => "Clear, distinct reliance on spatial design, underlining and charts. High prospects for adaptation and resilience.",
                            'fr' => "Recours net et distinct à l'agencement spatial, au surlignage et aux graphiques. Fort potentiel de réussite."
                        ];
                    case 5:
                    default:
                        return [
                            'en' => "Critical dependence on visual media. Struggles without spatial structure. High prospects of capturing information.",
                            'fr' => "Dépendance critique aux supports visuels. Difficultés sans repères spatiaux. Très forte assimilation visuelle."
                        ];
                }

            case 'Kinesthetic':
                switch ($category) {
                    case 1:
                        return [
                            'en' => "Total absence of physical or experiential reliance.",
                            'fr' => "Absence totale de recours physique ou expérientiel."
                        ];
                    case 2:
                        return [
                            'en' => "Rarely benefits from hands-on practice, concrete examples or trials.",
                            'fr' => "Tire rarement profit des travaux pratiques, exemples concrets ou essais."
                        ];
                    case 3:
                        return [
                            'en' => "Regular use of real world examples when blended with other modes.",
                            'fr' => "Recours régulier aux exemples du monde réel lorsqu'ils sont associés à d'autres modes."
                        ];
                    case 4:
                        return [
                            'en' => "Distinct need for physical manipulation and real life situations. High prospects of engagement.",
                            'fr' => "Besoin manifeste de manipulation physique et de situations concrètes du quotidien."
                        ];
                    case 5:
                    default:
                        return [
                            'en' => "Critical dependency on direct experience. Struggles with pure abstraction. High prospects of capturing practical information.",
                            'fr' => "Dépendance critique à l'expérience directe. Difficultés avec la pure abstraction. Réussite par la pratique."
                        ];
                }

            case 'Read/Write':
            default:
                switch ($category) {
                    case 1:
                        return [
                            'en' => "Complete avoidance of text-heavy or written instruction material.",
                            'fr' => "Évitement complet des supports d'instruction denses en texte ou purement écrits."
                        ];
                    case 2:
                        return [
                            'en' => "Minimal reliance on text; prefers interactive or visual delivery modes.",
                            'fr' => "Recours minimal au texte ; préfère les modes de transmission interactifs ou visuels."
                        ];
                    case 3:
                        return [
                            'en' => "Baseline text-literacy. Balances reading / writing with other modalities.",
                            'fr' => "Alphabétisation textuelle de base. Équilibre la lecture/écriture avec d'autres modalités."
                        ];
                    case 4:
                        return [
                            'en' => "Highly efficient in text processing. Relies heavily on essays, glossaries and manuals. High academic resilience.",
                            'fr' => "Grande efficacité dans le traitement du texte. S'appuie fortement sur les dissertations et manuels."
                        ];
                    case 5:
                    default:
                        return [
                            'en' => "Extreme preference for printed words; critical need for lists and notes. High prospects of capturing structured information.",
                            'fr' => "Préférence extrême pour les mots imprimés ; besoin critique de listes, notes et fiches de synthèse."
                        ];
                }
        }
    }

    /**
     * Section 4.5.1: Tailored Academic & Pedagogical Strategies by Neil Fleming (1987)
     */
    public static function getSection451Strategy($modality) {
        switch ($modality) {
            case 'Auditory':
                return [
                    'en' => "🎯 Neil Fleming Academic Strategy for Auditory Learners:\n" .
                            "• Learns easily by listening to others speak. Benefits greatly from lectures, verbal explanations, and structured discussions.\n" .
                            "• Speaking Aloud: Speak aloud when studying and reformulate lesson notes in your own words.\n" .
                            "• Recitation: Reciting lessons to classmates or a study partner reinforces memory, checks knowledge, and sharpens precision.\n" .
                            "• Auditory Tools: Record key lectures and use phonetic memory aids, songs, rhymes, and oral Q&A sessions.\n" .
                            "• Freedom of Movement: If needed, walk or mime with book/notes in hand while verbalizing concepts.",

                    'fr' => "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Auditifs :\n" .
                            "• Apprend facilement en écoutant parler. Tire un grand bénéfice des cours magistraux, explications orales et débats.\n" .
                            "• Verbalisation à voix haute : Parlez à voix haute pour apprendre et reformulez vos notes avec vos propres mots.\n" .
                            "• Récitation active : Réciter vos leçons à un pair aide à mémoriser, vérifier vos connaissances et gagner en précision.\n" .
                            "• Outils auditifs : Enregistrez les cours importants et utilisez des moyens mnémotechniques phonétiques, rimes et séances de questions/réponses.\n" .
                            "• Liberté de mouvement : Si nécessaire, marchez ou mimez avec votre cahier en main tout en récitant."
                ];

            case 'Visual':
                return [
                    'en' => "🎯 Neil Fleming Academic Strategy for Visual Learners:\n" .
                            "• Grasps knowledge through color differentiation, shapes, illustrations, mind maps, flash cards, charts, and diagrams.\n" .
                            "• Structured Presentation: Pay close attention to notes layout—underline and color-code chapter headings and key paragraphs.\n" .
                            "• Visual Index Cards: Create index summary cards featuring essential data, diagrams, and visual tables for each chapter.\n" .
                            "• Visual Mnemonics: Prioritize visual patterns, flowcharts, infographics, and instructional videos.\n" .
                            "• Active Reading: Always read new or difficult texts with a pencil in hand to sketch diagrams, highlight keywords, and map concepts.",

                    'fr' => "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Visuels :\n" .
                            "• Assimile aisément par la différenciation des couleurs, les formes, cartes mentales, fiches, schémas et graphiques.\n" .
                            "• Présentation soignée : Soignez la mise en page de vos notes—surlignez et codez par couleur les titres et notions clés.\n" .
                            "• Fiches bristol visuelles : Élaborez des fiches synthétiques claires intégrant les schémas et tableaux essentiels de chaque chapitre.\n" .
                            "• Mnémotechnique visuelle : Privilégiez les organigrammes, infographies et supports multimédias.\n" .
                            "• Lecture active : Lisez toujours les textes difficiles avec un crayon en main pour schématiser et noter les mots essentiels."
                ];

            case 'Kinesthetic':
                return [
                    'en' => "🎯 Neil Fleming Academic Strategy for Kinesthetic Learners:\n" .
                            "• Learns best when actively participating: touching, practicing, experimenting, exploring, and imitating real-world applications.\n" .
                            "• Physical Activity: Walk back and forth while memorizing; physical movement enhances focus and clears emotional blocks.\n" .
                            "• Practical Applications: Use hands-on problem sets, laboratory experiments, code implementations, and physical model building.\n" .
                            "• Recreating Concepts: Translate abstract textbook theories into concrete physical examples and task-based simulations.\n" .
                            "• Reinforce natural strengths: Structure study sessions around short, active intervals with tangible problem solving.",

                    'fr' => "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Kinesthésiques :\n" .
                            "• Apprend au mieux en participant activement : manipuler, pratiquer, expérimenter et imiter des applications concrètes.\n" .
                            "• Mouvement physique : Marchez d'avant en arrière pendant l'apprentissage ; le mouvement stimule la concentration.\n" .
                            "• Applications pratiques : Travaillez avec des exercices concrets, travaux pratiques de laboratoire, codage et maquettes.\n" .
                            "• Reconstitution concrète : Transformez les théories abstraites en exemples physiques et simulations de cas réels.\n" .
                            "• Renforcement stratégique : Structurez vos révisions en sessions dynamiques rythmées par la résolution d'exercices concrets."
                ];

            case 'Read/Write':
            default:
                return [
                    'en' => "🎯 Neil Fleming Academic Strategy for Read/Write Learners:\n" .
                            "• Prefers learning through reading, organizing, and summarizing textbooks, handouts, and structured written materials.\n" .
                            "• Silent Rewriting: Benefit immensely from re-reading and re-writing comprehensive notes silently again and again.\n" .
                            "• Textual Description: Translate charts, graphs, and visual diagrams into bulleted text descriptions to memorize them.\n" .
                            "• Reference Materials: Make frequent use of dictionaries, glossaries, encyclopedias, and detailed bibliographies.\n" .
                            "• Structured Note-Taking: Build organized bulleted lists, essay summaries, and structured revision binders.",

                    'fr' => "🎯 Stratégie Pédagogique de Neil Fleming pour Apprenants Lecture / Écriture :\n" .
                            "• Apprend principalement en lisant, structurant et résumant manuels, polycopiés et documents écrits.\n" .
                            "• Réécriture silencieuse : Tirez un immense profit de la relecture et de la réécriture silencieuse répétée de vos synthèses.\n" .
                            "• Description textuelle : Décrivez littéralement par écrit les graphiques et schémas pour mieux les mémoriser.\n" .
                            "• Matériel de référence : Utilisez activement dictionnaires, glossaires de termes et manuels de cours détaillés.\n" .
                            "• Prise de notes structurée : Rédigez des fiches organisées en listes à puces, résumés de dissertations et synthèses soignées."
                ];
        }
    }
}
