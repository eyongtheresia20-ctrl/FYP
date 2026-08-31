php_engine_code = r'''<?php
// ============================================================
//  MINESEC LST — VARK PSYCHOMETRIC & ACADEMIC ENGINE (PHP)
//  Table 3 Standardized Evaluation & Multi-Modal Diagnostics
// ============================================================

class VarkAcademicEngine {

    public static function evaluate(
        float $auditory,
        float $visual,
        float $kinesthetic,
        float $readWrite
    ): array {
        return self::evaluateForStudent($auditory, $visual, $kinesthetic, $readWrite);
    }

    public static function evaluateForStudent(
        float $auditory,
        float $visual,
        float $kinesthetic,
        float $readWrite
    ): array {
        $scores = [
            'Auditory'    => $auditory,
            'Visual'      => $visual,
            'Kinesthetic' => $kinesthetic,
            'Read/Write'  => $readWrite,
        ];

        $maxScore = max($scores);
        $topModalities = [];

        if ($maxScore > 0) {
            foreach ($scores as $mod => $sc) {
                if (abs($sc - $maxScore) < 0.001) {
                    $topModalities[] = $mod;
                }
            }
        }

        $tiedCount = count($topModalities);
        $modalityType = 'Uni-Modal';
        if ($tiedCount === 4) $modalityType = 'Quad-Modal';
        elseif ($tiedCount === 3) $modalityType = 'Tri-Modal';
        elseif ($tiedCount === 2) $modalityType = 'Bi-Modal';
        elseif ($tiedCount === 0) $modalityType = 'Diagnostic Phase';

        $categories = [
            'Auditory'    => self::getBiModalCategory('Auditory', $auditory),
            'Visual'      => self::getBiModalCategory('Visual', $visual),
            'Kinesthetic' => self::getBiModalCategory('Kinesthetic', $kinesthetic),
            'Read/Write'  => self::getBiModalCategory('Read/Write', $readWrite),
        ];

        $primaryModality = !empty($topModalities) ? $topModalities[0] : 'Auditory';
        $primaryCategory = $categories[$primaryModality] ?? 3;

        $diagnosticsEn = [];
        $diagnosticsFr = [];

        foreach ($topModalities as $mod) {
            $cat = $categories[$mod] ?? 3;
            $t3 = self::getTable3Text($mod, $cat);
            $diagnosticsEn[] = "• $mod (" . self::getCategoryName($cat, true) . "): " . $t3['en'];
            $diagnosticsFr[] = "• " . self::getModalityNameFr($mod) . " (" . self::getCategoryName($cat, false) . ") : " . $t3['fr'];
        }

        $strategiesEn = [];
        $strategiesFr = [];
        foreach ($topModalities as $mod) {
            $strat = self::getStudentStudyStrategy($mod);
            $strategiesEn[] = $strat['en'] ?? '';
            $strategiesFr[] = $strat['fr'] ?? '';
        }

        if (empty($topModalities)) {
            $diagnosticsEn[] = "• Diagnostic Phase: Assessment in progress. Multimodal study techniques are recommended.";
            $diagnosticsFr[] = "• Phase Diagnostique : Évaluation en cours. L'adoption de techniques d'étude multimodales est recommandée.";
            $strategiesEn[] = "• Study using varied methods: combine reading notes, drawing mind maps, listening to lecture recordings, and doing practical exercises.";
            $strategiesFr[] = "• Variez vos méthodes d'étude : alternez lecture de fiches, schématisation, écoute de résumés oraux et exercices pratiques.";
        }

        $learningStyleLabel = (count($topModalities) > 1)
            ? implode('-', $topModalities) . " ($modalityType)"
            : (!empty($topModalities) ? $topModalities[0] : 'Multimodal');

        return [
            'modality_type'             => $modalityType,
            'primary_modality'          => $primaryModality,
            'learning_style'            => $learningStyleLabel,
            'primary_category'          => $primaryCategory,
            'primary_category_name_en'  => self::getCategoryName($primaryCategory, true),
            'primary_category_name_fr'  => self::getCategoryName($primaryCategory, false),
            'categories'                => $categories,
            'prospects_summary_en'      => self::getProspectsSummary($primaryCategory, true),
            'prospects_summary_fr'      => self::getProspectsSummary($primaryCategory, false),
            'academic_diagnostic_en'    => implode("\n", $diagnosticsEn),
            'academic_diagnostic_fr'    => implode("\n", $diagnosticsFr),
            'learning_strategy_en'      => implode("\n\n", $strategiesEn),
            'learning_strategy_fr'      => implode("\n\n", $strategiesFr),
            'full_recommendation_en'    => implode("\n", $diagnosticsEn) . "\n\n" . implode("\n\n", $strategiesEn),
            'full_recommendation_fr'    => implode("\n", $diagnosticsFr) . "\n\n" . implode("\n\n", $strategiesFr),
        ];
    }

    public static function evaluateForEducators(
        int $auditory,
        int $visual,
        int $kinesthetic,
        int $readWrite,
        string $contextName = '',
        bool $isSchoolLevel = false,
        bool $isNationalLevel = false,
        bool $isRegionalLevel = false
    ): array {
        $totalAssessed = $auditory + $visual + $kinesthetic + $readWrite;

        if ($totalAssessed === 0) {
            if ($isNationalLevel) {
                return [
                    'en' => "• National Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently underway nationwide across secondary and technical schools.\n\n"
                          . "• Universal Multimodal Educational Policy: All pedagogical inspectors, regional delegates, and educators must encourage and balance all 4 learning modalities equally (Visual, Auditory, Read/Write, Kinesthetic) across all academic curricula.\n\n"
                          . "• National Assessment Supervision: Mobilize regional and divisional delegations to ensure all enrolled secondary students complete their diagnostic VARK test.",
                    'fr' => "• Stratégie Multimodale Nationale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans l'ensemble des établissements secondaires et techniques du territoire.\n\n"
                          . "• Politique Éducative Multimodale Globale : L'ensemble des inspecteurs pédagogiques, délégués régionaux et enseignants doivent encourager équitablement les 4 modalités d'apprentissage (Visuel, Auditif, Lecture/Écriture, Kinesthésique).\n\n"
                          . "• Suivi National des Évaluations : Mobiliser les délégations régionales et départementales pour que l'ensemble des élèves complètent leur test diagnostique."
                ];
            } else if ($isSchoolLevel) {
                return [
                    'en' => "• Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently in progress across classes in {$contextName}.\n\n"
                          . "• School-Wide Multimodal Instruction: Head teachers and pedagogical staff should encourage all learning styles equally by ensuring every subject incorporates verbal lectures, visual diagrams, structured texts, and practical exercises.\n\n"
                          . "• Diagnostic Supervision: Coordinate with class teachers to ensure all enrolled students complete their diagnostic VARK test.",
                    'fr' => "• Stratégie Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans les classes de {$contextName}.\n\n"
                          . "• Enseignement Multimodal Global : Les équipes pédagogiques doivent encourager équitablement tous les styles d'apprentissage en combinant explications orales, supports visuels, fiches écrites et travaux pratiques.\n\n"
                          . "• Suivi Diagnostique : Coordonnez avec les professeurs principaux pour que l'ensemble des élèves complètent leur évaluation."
                ];
            } else {
                return [
                    'en' => "• Multimodal Teaching Strategy (Diagnostic Phase): No students have completed the VARK assessment in {$contextName} yet.\n\n"
                          . "• Differentiated Classroom Engagement: Encourage and stimulate all learning styles equally through multimodal instruction—combining oral explanations, whiteboard diagrams, written notes, and hands-on exercises.\n\n"
                          . "• Assessment Coordination: Encourage all students in this class to complete their diagnostic test on the platform.",
                    'fr' => "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Aucun élève n'a encore complété le test VARK en {$contextName}.\n\n"
                          . "• Enseignement Inclusif & Équilibré : Encouragez et mobilisez équitablement tous les styles d'apprentissage (explications orales, schémas au tableau, notes écrites et exercices pratiques).\n\n"
                          . "• Coordination Diagnostique : Invitez tous les élèves de cette classe à passer leur évaluation sur la plateforme."
                ];
            }
        }

        $scores = [
            'Auditory'    => $auditory,
            'Visual'      => $visual,
            'Kinesthetic' => $kinesthetic,
            'Read/Write'  => $readWrite,
        ];

        arsort($scores);

        $linesEn = [];
        $linesFr = [];
        $partsEn = [];
        $partsFr = [];

        foreach ($scores as $st => $cnt) {
            if ($cnt > 0) {
                $pct = round(($cnt / $totalAssessed) * 100);
                $partsEn[] = "{$cnt} {$st} ({$pct}%)";
                $partsFr[] = "{$cnt} " . self::getModalityNameFr($st) . " ({$pct}%)";
            }
        }

        $headerPrefixEn = '• Class Profile Overview';
        $headerPrefixFr = '• Profil de la Classe';
        if ($isNationalLevel) {
            $headerPrefixEn = '• National Evaluated Cohort Profile';
            $headerPrefixFr = '• Profil de la Cohorte Évaluée au Niveau National';
        } else if ($isRegionalLevel) {
            $headerPrefixEn = '• Regional Evaluated Cohort Profile';
            $headerPrefixFr = '• Profil de la Cohorte Évaluée au Niveau Régional';
        } else if ($isSchoolLevel) {
            $headerPrefixEn = '• School Evaluated Cohort Profile';
            $headerPrefixFr = '• Profil de la Cohorte Évaluée de l\'Établissement';
        }

        $linesEn[] = "{$headerPrefixEn}: " . implode(', ', $partsEn) . " out of {$totalAssessed} assessed students.";
        $linesFr[] = "{$headerPrefixFr} : " . implode(', ', $partsFr) . " sur {$totalAssessed} élèves évalués.";

        foreach ($scores as $st => $cnt) {
            if ($cnt <= 0) continue;

            if ($st === 'Auditory') {
                $linesEn[] = "• Recommendations for Auditory Learners ({$cnt} students):\n"
                           . "  - Classroom Instruction: Emphasize clear oral explanations, structured class discussions, verbal lecture summaries, and oral Q&A reviews.\n"
                           . "  - Institutional Support: Prioritize public address systems, audio recording tools for lesson archives, and school debate seminars.";
                $linesFr[] = "• Recommandations pour les Apprenants Auditifs ({$cnt} élèves) :\n"
                           . "  - Pratiques Pédagogiques : Privilégiez les explications orales structurées, les débats en classe, les synthèses verbales et les séances de questions/réponses.\n"
                           . "  - Soutien Institutionnel : Équipez l'établissement en matériel de sonorisation, archives audio de cours et concours d'art oratoire.";
            } elseif ($st === 'Visual') {
                $linesEn[] = "• Recommendations for Visual Learners ({$cnt} students):\n"
                           . "  - Classroom Instruction: Use structured blackboard layouts, color-coded diagrams, flowcharts, and visual mind maps to illustrate concepts.\n"
                           . "  - Institutional Support: Provide digital projectors, science chart displays, and visual educational media in classrooms.";
                $linesFr[] = "• Recommandations pour les Apprenants Visuels ({$cnt} élèves) :\n"
                           . "  - Pratiques Pédagogiques : Utilisez un agencement clair au tableau, des schémas en couleurs, des organigrammes et des cartes conceptuelles.\n"
                           . "  - Soutien Institutionnel : Mettez à disposition des vidéoprojecteurs, planches murales et supports visuels.";
            } elseif ($st === 'Kinesthetic') {
                $linesEn[] = "• Recommendations for Kinesthetic Learners ({$cnt} students):\n"
                           . "  - Classroom Instruction: Incorporate practical demonstrations, hands-on problem sets, concrete real-world case studies, and active tasks.\n"
                           . "  - Institutional Support: Equip laboratories and technical workshops with interactive kits and practical experiment supplies.";
                $linesFr[] = "• Recommandations pour les Apprenants Kinesthésiques ({$cnt} élèves) :\n"
                           . "  - Pratiques Pédagogiques : Intégrez des démonstrations pratiques, des résolutions d'exercices concrets et des cas d'application du quotidien.\n"
                           . "  - Soutien Institutionnel : Équipez les laboratoires et ateliers de kits pratiques et matériel d'expérimentation.";
            } elseif ($st === 'Read/Write') {
                $linesEn[] = "• Recommendations for Read/Write Learners ({$cnt} students):\n"
                           . "  - Classroom Instruction: Provide clear written lesson outlines, structured definitions, bulleted summaries, and guided textbook reading exercises.\n"
                           . "  - Institutional Support: Supply school libraries with updated textbooks, reference glossaries, and comprehensive revision manuals.";
                $linesFr[] = "• Recommandations pour les Apprenants Lecture/Écriture ({$cnt} élèves) :\n"
                           . "  - Pratiques Pédagogiques : Fournissez des plans de cours écrits, des résumés structurés à puces, des définitions précises et des lectures dirigées.\n"
                           . "  - Soutien Institutionnel : Approvisionnez les bibliothèques scolaires en manuels récents, glossaires et recueils d'exercices.";
            }
        }

        // Append Territorial Multimodal Directive for Unassessed Classes / Schools
        if ($isNationalLevel || $isRegionalLevel || $isSchoolLevel) {
            $scopeEn = $isNationalLevel ? "Nationwide & Across Unassessed Classes" : ($isRegionalLevel ? "Region-Wide & Across Unassessed Classes" : "School-Wide for Ongoing & Unassessed Classes");
            $scopeFr = $isNationalLevel ? "À l'Échelle Nationale & Pour les Classes Non Évaluées" : ($isRegionalLevel ? "À l'Échelle Régionale & Pour les Classes Non Évaluées" : "Pour les Classes en Cours d'Évaluation");

            $linesEn[] = "• Universal Multimodal Pedagogical Directive ({$scopeEn}):\n"
                       . "  Since diagnostic testing is progressively rolling out and several classes/schools are yet to complete their VARK assessment, educators must encourage and balance all 4 learning modalities:\n"
                       . "  - Visual: Integrate structured diagrams, schema boards, and visual summaries.\n"
                       . "  - Auditory: Maintain interactive oral lectures, verbal recaps, and structured discussions.\n"
                       . "  - Read/Write: Guide textbook readings, concise glossary notes, and written synthesis.\n"
                       . "  - Kinesthetic: Utilize lab demonstrations, practical exercises, and tangible problem sets.\n"
                       . "  - Diagnostic Action: Coordinate with teachers and delegates to ensure 100% assessment coverage across all student cohorts.";

            $linesFr[] = "• Directive Pédagogique Multimodale Globale ({$scopeFr}) :\n"
                       . "  Comme le déploiement diagnostique est en cours et que certaines classes/établissements n'ont pas encore finalisé le test VARK, les enseignants doivent encourager et équilibrer les 4 modalités d'apprentissage :\n"
                       . "  - Visuel : Intégrer des schémas clairs au tableau, des synthèses visuelles et des graphiques.\n"
                       . "  - Auditif : Maintenir des explications orales dynamiques, des récapitulatifs verbaux et des débats.\n"
                       . "  - Lecture/Écriture : Guider la lecture des manuels, les définitions structurées et les prises de notes.\n"
                       . "  - Kinesthésique : Proposer des travaux pratiques, des manipulations concrètes et des résolutions actives.\n"
                       . "  - Action Diagnostique : Coordonner avec les enseignants et délégués pour atteindre 100% de couverture de l'évaluation.";
        }

        return [
            'en' => implode("\n\n", $linesEn),
            'fr' => implode("\n\n", $linesFr),
        ];
    }

    public static function getBiModalCategory(string $modality, float $score): int {
        switch ($modality) {
            case 'Auditory':
                if ($score <= 3) return 1;
                if ($score <= 6) return 2;
                if ($score <= 10) return 3;
                return 4;
            case 'Visual':
                if ($score <= 3) return 1;
                if ($score <= 6) return 2;
                if ($score <= 9) return 3;
                return 4;
            case 'Kinesthetic':
                if ($score <= 4) return 1;
                if ($score <= 7) return 2;
                if ($score <= 11) return 3;
                return 4;
            case 'Read/Write':
            default:
                if ($score <= 3) return 1;
                if ($score <= 6) return 2;
                if ($score <= 9) return 3;
                return 4;
        }
    }

    public static function getTable3Text(string $modality, int $category): array {
        switch ($category) {
            case 1:
                return [
                    'en' => "Low $modality Preference — You occasionally benefit from $modality strategies, but rely primarily on your other learning modes.",
                    'fr' => "Faible Préférence $modality — Vous tirez occasionnellement profit des approches $modality, mais vous vous appuyez principalement sur vos autres modalités.",
                ];
            case 2:
                return [
                    'en' => "Moderate $modality Preference — You comfortably use $modality techniques when studying, but appreciate combined multi-modal instruction.",
                    'fr' => "Préférence $modality Modérée — Vous utilisez confortablement les techniques $modality, mais appréciez un enseignement multimodal combiné.",
                ];
            case 3:
                return [
                    'en' => "Strong $modality Preference — $modality is one of your primary ways of learning. Emphasizing $modality resources will significantly boost your retention.",
                    'fr' => "Forte Préférence $modality — Le canal $modality est l'un de vos modes d'apprentissage privilégiés. Mettre l'accent sur les ressources adaptées renforce considérablement votre rétention.",
                ];
            case 4:
            default:
                return [
                    'en' => "Very Strong $modality Preference — You have an exceptional $modality orientation. Tailored $modality study habits are crucial for your academic success.",
                    'fr' => "Très Forte Préférence $modality — Vous possédez une orientation $modality exceptionnelle. Des habitudes d'étude adaptées sont essentielles à votre réussite.",
                ];
        }
    }

    public static function getCategoryName(int $cat, bool $isEn): string {
        switch ($cat) {
            case 1: return $isEn ? 'Mild / Low' : 'Légère';
            case 2: return $isEn ? 'Moderate' : 'Modérée';
            case 3: return $isEn ? 'Strong' : 'Forte';
            case 4: return $isEn ? 'Very Strong' : 'Très Forte';
            default: return $isEn ? 'Moderate' : 'Modérée';
        }
    }

    public static function getProspectsSummary(int $cat, bool $isEn): string {
        switch ($cat) {
            case 1:
                return $isEn ? 'Good adaptability to varied teaching formats.' : 'Bonne adaptabilité aux formats d\'enseignement variés.';
            case 2:
                return $isEn ? 'Solid balance across learning situations.' : 'Équilibre solide entre les situations d\'apprentissage.';
            case 3:
                return $isEn ? 'High academic potential when utilizing preferred study strategies.' : 'Fort potentiel académique grâce aux stratégies d\'étude ciblées.';
            case 4:
            default:
                return $isEn ? 'Exceptional focus and high performance in tailored learning environments.' : 'Excellente concentration et performance élevée dans un environnement adapté.';
        }
    }

    public static function getStudentStudyStrategy(string $modality): array {
        switch ($modality) {
            case 'Auditory':
                return [
                    'en' => "• Auditory Study Strategy:\n  - Listen attentively to recorded lectures, podcasts, and verbal explanations.\n  - Read notes aloud and explain complex concepts to a study partner or group.\n  - Use rhythmic mnemonic phrases and oral Q&A reviews.",
                    'fr' => "• Stratégie d'Étude Auditive :\n  - Écoutez attentivement les enregistrements de cours, podcasts et explications orales.\n  - Lisez vos fiches à voix haute et réexpliquez les notions à un camarade.\n  - Utilisez des moyens mnémotechniques rythmiques et des auto-questionnaires oraux.",
                ];
            case 'Visual':
                return [
                    'en' => "• Visual Study Strategy:\n  - Use color-coded highlighters, mind maps, and structured concept diagrams.\n  - Watch educational video tutorials, animations, and visual demonstrations.\n  - Visualize notebook page layouts and key formulas in your mind during revision.",
                    'fr' => "• Stratégie d'Étude Visuelle :\n  - Utilisez des surligneurs de couleur, cartes mentales et diagrammes de concepts.\n  - Regardez des vidéos explicatives, animations et démonstrations visuelles.\n  - Visualisez la structure de vos pages et formules clés dans votre mémoire.",
                ];
            case 'Kinesthetic':
                return [
                    'en' => "• Kinesthetic Study Strategy:\n  - Connect theoretical lessons to concrete real-world applications and experiments.\n  - Study while walking or moving, using flashcards for active recall.\n  - Engage in lab sessions, practice problem sets, and practical assignments.",
                    'fr' => "• Stratégie d'Étude Kinesthésique :\n  - Reliez les cours théoriques à des applications concrètes et manipulations pratiques.\n  - Révisez en marchant ou en utilisant des flashcards pour un rappel actif.\n  - Participez activement aux travaux pratiques et exercices d'application.",
                ];
            case 'Read/Write':
            default:
                return [
                    'en' => "• Read/Write Study Strategy:\n  - Transform lectures and slides into detailed, structured bullet-point summaries.\n  - Rewrite key definitions, formulas, and vocabulary lists multiple times.\n  - Read textbooks carefully, annotate margins, and practice essay writing.",
                    'fr' => "• Stratégie d'Étude Lecture/Écriture :\n  - Transformez vos cours en fiches de synthèse structurées avec des puces claires.\n  - Réécrivez les définitions clés, formules et glossaires pour les mémoriser.\n  - Lisez attentivement les manuels, annotez les marges et rédigez des résumés.",
                ];
        }
    }

    public static function getModalityNameFr(string $modality): string {
        switch ($modality) {
            case 'Visual': return 'Visuel';
            case 'Auditory': return 'Auditif';
            case 'Read/Write': return 'Lecture/Écriture';
            case 'Kinesthetic': return 'Kinesthésique';
            default: return $modality;
        }
    }
}
'''

with open(r'backend/services/vark_academic_engine.php', 'w', encoding='utf-8') as f:
    f.write(php_engine_code)

print("SUCCESS: UPDATED backend/services/vark_academic_engine.php")
