<?php
// ============================================================
//  MINESEC LST — VARK ACADEMIC INTERPRETATION ENGINE (PHP)
// ============================================================

class VarkAcademicEngine {

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
