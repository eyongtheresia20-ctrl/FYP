<?php
// ============================================================
//  MINESEC LST — Dashboard API
// ============================================================

require_once __DIR__ . '/../config/helpers.php';
require_once __DIR__ . '/../config/database.php';

$action = $_GET['action'] ?? '';
$body   = getBody();
$pdo    = getDB();

function getSchoolClassBreakdownAndRoster($pdo, $schoolId, $clsName) {
    $stmtStList = $pdo->prepare("
        SELECT 
            st.id AS student_id,
            u.full_name,
            st.mat_number,
            st.class_name,
            COALESCE(
                (SELECT a.learning_style 
                 FROM assessments a 
                 WHERE a.student_id = st.id 
                 ORDER BY a.id DESC LIMIT 1),
                'Not Assessed'
            ) AS learning_style
        FROM students st
        JOIN users u ON u.id = st.user_id
        WHERE u.school_id = ? AND st.class_name = ?
        ORDER BY u.full_name ASC
    ");
    $stmtStList->execute([$schoolId, $clsName]);
    $stRows = $stmtStList->fetchAll(PDO::FETCH_ASSOC);

    $tot = count($stRows);
    $ass = 0;
    $vis = 0; $aud = 0; $kin = 0; $rw = 0;

    foreach ($stRows as $st) {
        $style = $st['learning_style'];
        if ($style !== 'Not Assessed') {
            $ass++;
            if (strpos($style, 'Visual') !== false) $vis++;
            if (strpos($style, 'Auditory') !== false) $aud++;
            if (strpos($style, 'Kinesthetic') !== false) $kin++;
            if (strpos($style, 'Read') !== false) $rw++;
        }
    }

    return [
        'total_students' => $tot,
        'assessed'       => $ass,
        'visual'         => $vis,
        'auditory'       => $aud,
        'kinesthetic'   => $kin,
        'read_write'     => $rw,
        'students'       => $stRows,
    ];
}

function generateClassroomRecommendation($vis, $aud, $kin, $rw, $clsName) {
    $total = $vis + $aud + $kin + $rw;
    if ($total == 0) {
        return [
            'en' => "• Multimodal Teaching Strategy (Diagnostic Phase): Diagnostic VARK assessments are in progress. Encourage all learning styles equally through multimodal instruction.\n" .
                    "• Auditory Recommendation: Integrate interactive class discussions, verbal lecture summaries, audio recordings, and peer Q&A sessions.\n" .
                    "• Visual Recommendation: Utilize color-coded visual board diagrams, mind maps, graphic organizers, and video demonstrations.\n" .
                    "• Kinesthetic Recommendation: Incorporate hands-on problem-solving exercises, practical lab demonstrations, and interactive group activities.\n" .
                    "• Read/Write Recommendation: Supply structured printed handouts, comprehensive reading glossaries, and bulleted note-taking frameworks.",
            'fr' => "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Les évaluations VARK sont en cours. Encouragez équitablement tous les styles d'apprentissage.\n" .
                    "• Recommandation Auditive : Intégrez des discussions interactives en classe, des synthèses orales de cours et des enregistrements audio.\n" .
                    "• Recommandation Visuelle : Utilisez des schémas visuels en couleurs, des cartes mentales et des diaporamas résumés.\n" .
                    "• Recommandation Kinesthésique : Proposez des exercices pratiques de résolution de problèmes et des travaux en groupe.\n" .
                    "• Recommandation Lecture/Écriture : Fournissez des fiches de cours imprimées structurées et des glossaires détaillés."
        ];
    }

    $dominant = 'Auditory';
    $maxVal = $aud;
    if ($vis > $maxVal) { $maxVal = $vis; $dominant = 'Visual'; }
    if ($kin > $maxVal) { $maxVal = $kin; $dominant = 'Kinesthetic'; }
    if ($rw > $maxVal)  { $maxVal = $rw;  $dominant = 'Read/Write'; }

    $pct = $total > 0 ? round(($maxVal / $total) * 100) : 0;

    $recsEn = [];
    $recsFr = [];

    if ($dominant == 'Auditory') {
        $recsEn[] = "• Auditory Learning Strategy (Primary Focus): Integrate interactive class discussions, verbal lecture summaries, audio recordings, and peer debates to maximize retention.";
        $recsFr[] = "• Stratégie d'Apprentissage Auditif (Focus Principal) : Intégrez des discussions interactives en classe, des synthèses orales de cours, des enregistrements audio et des débats.";
    } elseif ($dominant == 'Visual') {
        $recsEn[] = "• Visual Learning Strategy (Primary Focus): Utilize color-coded visual charts, mind maps, graphic organizers, and video demonstrations to boost comprehension.";
        $recsFr[] = "• Stratégie d'Apprentissage Visuel (Focus Principal) : Utilisez des schémas visuels en couleurs, des cartes mentales, des organisateurs graphiques et des démonstrations vidéo.";
    } elseif ($dominant == 'Kinesthetic') {
        $recsEn[] = "• Kinesthetic Learning Strategy (Primary Focus): Structure lessons around hands-on laboratory experiments, interactive coding, and practical exercises.";
        $recsFr[] = "• Stratégie d'Apprentissage Kinesthésique (Focus Principal) : Structurez les cours autour de travaux pratiques en laboratoire, du codage interactif et d'exercices pratiques.";
    } else {
        $recsEn[] = "• Read/Write Learning Strategy (Primary Focus): Provide structured printed handouts, comprehensive reading glossaries, and detailed note-taking frameworks.";
        $recsFr[] = "• Stratégie d'Apprentissage Lecture/Écriture (Focus Principal) : Fournissez des fiches de cours imprimées, des glossaires détaillés et des guides de prise de notes.";
    }

    $recsEn[] = "• Visual Support: Provide color-coded summary charts, mind maps, and key visual diagrams on the board.";
    $recsFr[] = "• Support Visuel : Fournissez des schémas résumés en couleurs, des cartes mentales et des diagrammes clés au tableau.";

    $recsEn[] = "• Kinesthetic Support: Incorporate hands-on problem-solving exercises, interactive group activities, and practical demonstrations.";
    $recsFr[] = "• Support Kinesthésique : Intégrez des exercices pratiques de résolution de problèmes, des activités de groupe et des démonstrations.";

    $recsEn[] = "• Read/Write Support: Supply structured reading handouts, written vocabulary lists, and guided note-taking frameworks.";
    $recsFr[] = "• Support Lecture/Écriture : Proposez des fiches de cours imprimées structurées, des listes de vocabulaire récapitulatives et des guides de prise de notes.";

    return [
        'en' => implode("\n", $recsEn),
        'fr' => implode("\n", $recsFr)
    ];
}

function generateSchoolPolicyRecommendation($vis, $aud, $kin, $rw, $schoolName) {
    $total = $vis + $aud + $kin + $rw;
    if ($total == 0) {
        return [
            'en' => "• Strategic Institutional Directive for $schoolName: Student diagnostic assessment coverage in progress. Coordinate with department heads to complete student VARK testing.",
            'fr' => "• Directive Stratégique Institutionnelle pour $schoolName : Couverture des évaluations diagnostiques en cours. Coordonnez avec les chefs de travaux pour finaliser les tests VARK."
        ];
    }

    $counts = ['Visual' => $vis, 'Auditory' => $aud, 'Kinesthetic' => $kin, 'Read/Write' => $rw];
    $maxCount = max($counts);
    $topStyles = [];
    foreach ($counts as $style => $val) {
        if ($val == $maxCount && $val > 0) $topStyles[] = $style;
    }

    $recsEn = [];
    $recsFr = [];

    if (in_array('Auditory', $topStyles)) {
        $recsEn[] = "• Prioritize audio-visual equipment, public address systems, and recorded lecture archives.";
        $recsEn[] = "• Organize school-wide debate competitions and verbal presentation seminars.";
        $recsFr[] = "• Priorisez les équipements audio, les systèmes de sonorisation et les cours enregistrés.";
        $recsFr[] = "• Organisez des concours de débat et des séminaires de présentation orale à l'échelle du lycée.";
    }
    if (in_array('Visual', $topStyles)) {
        $recsEn[] = "• Allocate digital projectors, interactive smartboards, and visual simulation software across all classrooms.";
        $recsEn[] = "• Provide teachers with graphic design and visual diagramming training.";
        $recsFr[] = "• Allouez des vidéoprojecteurs, des tableaux interactifs et des logiciels de simulation visuelle.";
        $recsFr[] = "• Offrez aux enseignants une formation aux supports graphiques et cartes mentales.";
    }
    if (in_array('Kinesthetic', $topStyles)) {
        $recsEn[] = "• Expand practical ICT laboratory resources, computer hardware workshops, and technical lab equipment.";
        $recsEn[] = "• Integrate active learning, hands-on demonstrations, and field practicals into the curriculum.";
        $recsFr[] = "• Développez les laboratoires informatiques pratiques, ateliers de maintenance et équipements TP.";
        $recsFr[] = "• Intégrez l'apprentissage actif, les démonstrations pratiques et les travaux de terrain.";
    }
    if (in_array('Read/Write', $topStyles)) {
        $recsEn[] = "• Enrich the school library with updated textbooks, digital reference manuals, and printed study guides.";
        $recsEn[] = "• Conduct essay-writing and structured documentation workshops for technical students.";
        $recsFr[] = "• Enrichissez la bibliothèque en manuels scolaires, répertoires numériques et fiches de révision.";
        $recsFr[] = "• Organisez des ateliers de rédaction et de documentation structurée pour les élèves.";
    }

    return [
        'en' => implode("\n", $recsEn),
        'fr' => implode("\n", $recsFr)
    ];
}

function generateDelegatePolicyRecommendation($vis, $aud, $kin, $rw, $entityName, $isRegional = false) {
    $total = $vis + $aud + $kin + $rw;
    $entityTypeEn = $isRegional ? 'Regional' : 'Divisional';
    $entityTypeFr = $isRegional ? 'Régionale' : 'Départementale';

    if ($total == 0) {
        return [
            'en' => "• $entityTypeEn VARK Diagnostic Directive for $entityName:\n• Coordinate inspection visits with school principals across $entityName to accelerate student VARK diagnostic completion.\n• Ensure all secondary lycées establish offline diagnostic stations for unassessed classes.",
            'fr' => "• Directive de Diagnostic $entityTypeFr pour le $entityName :\n• Coordonnez les visites d'inspection avec les proviseurs du $entityName pour accélérer la réalisation des tests VARK.\n• Veillez à ce que tous les lycées installent des stations de diagnostic hors-ligne."
        ];
    }

    $counts = ['Visual' => $vis, 'Auditory' => $aud, 'Kinesthetic' => $kin, 'Read/Write' => $rw];
    $maxCount = max($counts);
    $topStyles = [];
    foreach ($counts as $style => $val) {
        if ($val == $maxCount && $val > 0) $topStyles[] = $style;
    }

    $recsEn = [];
    $recsFr = [];

    if (in_array('Auditory', $topStyles)) {
        $recsEn[] = "• Prioritize audio-visual equipment, public address systems, and recorded lecture archives across lycées in $entityName.";
        $recsEn[] = "• Organize $entityTypeEn debate competitions and verbal presentation seminars for secondary students.";
        $recsEn[] = "• Conduct pedagogical inspection visits focused on interactive verbal instruction and auditory teaching methods.";
        $recsFr[] = "• Priorisez les équipements audio-visuels, sonorisations et archives audio dans les lycées du $entityName.";
        $recsFr[] = "• Organisez des concours de débat et séminaires d'expression orale à l'échelle $entityTypeFr.";
        $recsFr[] = "• Coordonnez des visites d'inspection axées sur l'enseignement verbal interactif et les débats.";
    }
    if (in_array('Visual', $topStyles)) {
        $recsEn[] = "• Allocate digital projectors, interactive smartboards, and visual simulation software across all lycées in $entityName.";
        $recsEn[] = "• Provide secondary teachers with graphic design and visual diagramming training.";
        $recsEn[] = "• Inspect computer laboratories to ensure visual teaching aids and mind-mapping tools are operational.";
        $recsFr[] = "• Allouez des vidéoprojecteurs, des tableaux interactifs et logiciels de simulation visuelle dans le $entityName.";
        $recsFr[] = "• Offrez aux enseignants une formation aux supports graphiques et cartes mentales.";
        $recsFr[] = "• Inspectez les laboratoires informatiques pour vérifier la disponibilité des outils visuels.";
    }
    if (in_array('Kinesthetic', $topStyles)) {
        $recsEn[] = "• Expand practical ICT laboratory resources, computer hardware workshops, and technical lab equipment in $entityName.";
        $recsEn[] = "• Strengthen partnerships with technical industries and integrate practical field internships into the curriculum.";
        $recsEn[] = "• Inspect technical workshops to verify safety protocols and practical hands-on training execution.";
        $recsFr[] = "• Développez les laboratoires informatiques pratiques, ateliers de maintenance et équipements TP dans le $entityName.";
        $recsFr[] = "• Renforcez les partenariats industriels et intégrez des stages pratiques dans le calendrier scolaire.";
        $recsFr[] = "• Inspectez les ateliers techniques pour vérifier les protocoles de sécurité et la réalisation des TP.";
    }
    if (in_array('Read/Write', $topStyles)) {
        $recsEn[] = "• Enrich secondary school libraries with updated textbooks, digital reference manuals, and printed study guides in $entityName.";
        $recsEn[] = "• Establish digital e-libraries and subscription access to educational journals and technical reading materials.";
        $recsEn[] = "• Conduct $entityTypeEn essay-writing competitions and structured documentation workshops.";
        $recsFr[] = "• Enrichissez les bibliothèques scolaires en manuels, répertoires numériques et fiches dans le $entityName.";
        $recsFr[] = "• Mettez en place une bibliothèque numérique avec accès aux revues éducatives et manuels techniques.";
        $recsFr[] = "• Organisez des concours de rédaction académique et des ateliers de documentation technique.";
    }

    return [
        'en' => implode("\n", $recsEn),
        'fr' => implode("\n", $recsFr)
    ];
}

$userId = intval($body['user_id'] ?? $_GET['user_id'] ?? $_GET['principal_id'] ?? 0);

// If user_id provided, fetch user details
$authUser = null;
if ($userId > 0) {
    $stmt = $pdo->prepare("SELECT id, role, school_id, region, division, full_name, matricule FROM users WHERE id = ?");
    $stmt->execute([$userId]);
    $authUser = $stmt->fetch();
}

switch ($action) {

    // ── PRINCIPAL: School Data & Analytics ──────────────────────────────
    case 'principal_school':
    case 'school_overview':
        $pId = $userId;
        if (!$authUser && isset($_GET['principal_id'])) {
            $pId = intval($_GET['principal_id']);
            $stmt = $pdo->prepare("SELECT id, role, school_id, region, division, full_name, matricule FROM users WHERE id = ?");
            $stmt->execute([$pId]);
            $authUser = $stmt->fetch();
        }

        $schoolName = 'LYCEE TECHNIQUE DE NGAOUNDAL';
        $region = $authUser['region'] ?? 'ADAMOUA';
        $division = $authUser['division'] ?? 'DJEREM';
        $schoolId = $authUser['school_id'] ?? 1;

        // Fetch School Info
        if ($schoolId) {
            $stmtSc = $pdo->prepare("SELECT name, region, division FROM schools WHERE id = ?");
            $stmtSc->execute([$schoolId]);
            $scData = $stmtSc->fetch();
            if ($scData) {
                $schoolName = $scData['name'];
                $region = $scData['region'];
                $division = $scData['division'];
            }
        }

        // Count Total Students from Database
        $stmtSt = $pdo->prepare("SELECT COUNT(*) FROM students s JOIN users u ON u.id = s.user_id WHERE u.school_id = ?");
        $stmtSt->execute([$schoolId]);
        $totalStudents = intval($stmtSt->fetchColumn());

        // Count Assessed & VARK Breakdown from Database
        $stmtVark = $pdo->prepare("
            SELECT 
                COUNT(DISTINCT a.student_id) AS assessed,
                SUM(CASE WHEN a.learning_style LIKE '%Visual%' THEN 1 ELSE 0 END) AS visual,
                SUM(CASE WHEN a.learning_style LIKE '%Auditory%' THEN 1 ELSE 0 END) AS auditory,
                SUM(CASE WHEN a.learning_style LIKE '%Kinesthetic%' THEN 1 ELSE 0 END) AS kinesthetic,
                SUM(CASE WHEN a.learning_style LIKE '%Read%' THEN 1 ELSE 0 END) AS rw_count
            FROM assessments a
            JOIN students s ON s.id = a.student_id
            JOIN users u ON u.id = s.user_id
            WHERE u.school_id = ?
        ");
        $stmtVark->execute([$schoolId]);
        $vark = $stmtVark->fetch(PDO::FETCH_ASSOC);

        // Count Total Teachers from Database
        $stmtT = $pdo->prepare("SELECT COUNT(*) FROM teachers t JOIN users u ON u.id = t.user_id WHERE u.school_id = ?");
        $stmtT->execute([$schoolId]);
        $totalTeachers = intval($stmtT->fetchColumn());

        // Teachers list from Database
        $stmtTList = $pdo->prepare("
            SELECT u.full_name AS name, t.subject, t.class_name AS classes,
                   (SELECT COUNT(*) FROM students st WHERE st.class_name = t.class_name) AS students_count
            FROM teachers t
            JOIN users u ON u.id = t.user_id
            WHERE u.school_id = ?
        ");
        $stmtTList->execute([$schoolId]);
        $teachersList = $stmtTList->fetchAll(PDO::FETCH_ASSOC);

        // Class-by-Class Breakdown for Principal from Database
        $stmtClasses = $pdo->prepare("
            SELECT DISTINCT s.class_name 
            FROM students s 
            JOIN users u ON u.id = s.user_id 
            WHERE u.school_id = ? AND s.class_name IS NOT NULL AND s.class_name != ''
            ORDER BY s.class_name ASC
        ");
        $stmtClasses->execute([$schoolId]);
        $classList = $stmtClasses->fetchAll(PDO::FETCH_COLUMN);

        $defaultClasses = ['1ère TI', 'Terminale TI', '2nde C', '1ère C', 'Terminale C'];
        foreach ($defaultClasses as $dc) {
            if (!in_array($dc, $classList)) {
                $classList[] = $dc;
            }
        }

        $classBreakdown = [];
        $scAssessed = 0;
        $scVis = 0; $scAud = 0; $scKin = 0; $scRw = 0;

        foreach ($classList as $cls) {
            $cData = getSchoolClassBreakdownAndRoster($pdo, $schoolId, $cls);
            $scAssessed += $cData['assessed'];
            $scVis += $cData['visual'];
            $scAud += $cData['auditory'];
            $scKin += $cData['kinesthetic'];
            $scRw += $cData['read_write'];

            $classRec = generateClassroomRecommendation($cData['visual'], $cData['auditory'], $cData['kinesthetic'], $cData['read_write'], $cls);

            $classBreakdown[] = [
                'class_name' => $cls,
                'total_students' => $cData['total_students'],
                'assessed' => $cData['assessed'],
                'visual' => $cData['visual'],
                'auditory' => $cData['auditory'],
                'kinesthetic' => $cData['kinesthetic'],
                'read_write' => $cData['read_write'],
                'students' => $cData['students'],
                'ai_recommendation_en' => $classRec['en'],
                'ai_recommendation_fr' => $classRec['fr'],
            ];
        }

        $vark = [
            'assessed' => $scAssessed,
            'visual' => $scVis,
            'auditory' => $scAud,
            'kinesthetic' => $scKin,
            'rw_count' => $scRw,
        ];

        $schoolPolicyRec = generateSchoolPolicyRecommendation($scVis, $scAud, $scKin, $scRw, $schoolName);

        // Fetch all students for Principal Student Management Data Table
        $stmtAllSt = $pdo->prepare("
            SELECT st.id AS student_id, u.id AS user_id, u.full_name, COALESCE(st.matricule, u.matricule) AS matricule,
                   st.class_name, st.gender, st.birth_date, u.region, u.division, 
                   CASE WHEN u.is_activated = 1 AND u.password_hash IS NOT NULL AND u.password_hash != '' THEN 1 ELSE 0 END AS is_activated,
                   COALESCE(
                       (SELECT a.learning_style 
                        FROM assessments a 
                        WHERE a.student_id = st.id 
                        ORDER BY a.id DESC LIMIT 1),
                       'Not Assessed'
                   ) AS learning_style
            FROM students st
            JOIN users u ON u.id = st.user_id
            WHERE u.school_id = ?
            ORDER BY st.class_name ASC, u.full_name ASC
        ");
        $stmtAllSt->execute([$schoolId]);
        $allStudentsList = $stmtAllSt->fetchAll(PDO::FETCH_ASSOC);

        respond(true, 'Principal school data fetched from existing database.', [
            'school_name' => $schoolName,
            'principal_name' => $authUser['full_name'] ?? 'Mme. Etoa Christine',
            'matricule' => $authUser['matricule'] ?? 'PRN202601',
            'region' => $region,
            'division' => $division,
            'total_students' => $totalStudents,
            'assessed_students' => intval($vark['assessed'] ?? 0),
            'total_teachers' => $totalTeachers,
            'visual_count' => intval($vark['visual'] ?? 0),
            'auditory_count' => intval($vark['auditory'] ?? 0),
            'kinesthetic_count' => intval($vark['kinesthetic'] ?? 0),
            'read_write_count' => intval($vark['rw_count'] ?? 0),
            'teachers' => $teachersList,
            'class_breakdown' => $classBreakdown,
            'all_students' => $allStudentsList,
            'ai_policy_en' => $schoolPolicyRec['en'],
            'ai_policy_fr' => $schoolPolicyRec['fr'],
        ]);
        break;

    // ── DIVISIONAL DELEGATE ANALYTICS ──────────────────────────────────
    case 'divisional_analytics':
    case 'division_overview':
        $region = $authUser['region'] ?? 'ADAMOUA';
        $division = $authUser['division'] ?? 'DJEREM';

        // 1. Fetch schools in this division from Database
        $stmtSc = $pdo->prepare("SELECT id, name, town FROM schools WHERE division = ? OR division IS NULL OR division = ''");
        $stmtSc->execute([$division]);
        $schoolRows = $stmtSc->fetchAll(PDO::FETCH_ASSOC);

        if (empty($schoolRows)) {
            $schoolRows = [
                ['id' => 1, 'name' => 'LYCEE TECHNIQUE DE NGAOUNDAL', 'town' => 'Ngaoundal'],
                ['id' => 2, 'name' => 'LYCEE CLASSIQUE DE NGAOUNDAL', 'town' => 'Ngaoundal'],
                ['id' => 3, 'name' => 'LYCEE BILINGUE DE NGAOUNDAL', 'town' => 'Ngaoundal'],
            ];
        }

        $totalDivStudents = 0;
        $totalDivAssessed = 0;
        $totalDivTeachers = 0;
        $divVis = 0; $divAud = 0; $divKin = 0; $divRw = 0;

        $schoolsList = [];

        foreach ($schoolRows as $sc) {
            $scId = $sc['id'];
            $scName = $sc['name'];

            // Count teachers for this school from Database
            $stmtT = $pdo->prepare("SELECT COUNT(*) FROM teachers t JOIN users u ON u.id = t.user_id WHERE u.school_id = ?");
            $stmtT->execute([$scId]);
            $scTeachers = intval($stmtT->fetchColumn());

            // Count students for this school from Database
            $stmtSt = $pdo->prepare("SELECT COUNT(*) FROM students st JOIN users u ON u.id = st.user_id WHERE u.school_id = ?");
            $stmtSt->execute([$scId]);
            $scStudents = intval($stmtSt->fetchColumn());

            // Classes in this school from Database
            $stmtCls = $pdo->prepare("SELECT DISTINCT st.class_name FROM students st JOIN users u ON u.id = st.user_id WHERE u.school_id = ? AND st.class_name IS NOT NULL AND st.class_name != '' ORDER BY st.class_name ASC");
            $stmtCls->execute([$scId]);
            $clsList = $stmtCls->fetchAll(PDO::FETCH_COLUMN);

            $scClassesData = [];
            $scAssessed = 0;
            $scVis = 0; $scAud = 0; $scKin = 0; $scRw = 0;

            foreach ($clsList as $clsName) {
                $cData = getSchoolClassBreakdownAndRoster($pdo, $scId, $clsName);
                $scAssessed += $cData['assessed'];
                $scVis += $cData['visual']; $scAud += $cData['auditory']; $scKin += $cData['kinesthetic']; $scRw += $cData['read_write'];

                $clsRec = generateClassroomRecommendation($cData['visual'], $cData['auditory'], $cData['kinesthetic'], $cData['read_write'], "$clsName ($scName)");

                $scClassesData[] = [
                    'class_name' => $clsName,
                    'total_students' => $cData['total_students'],
                    'assessed' => $cData['assessed'],
                    'visual' => $cData['visual'],
                    'auditory' => $cData['auditory'],
                    'kinesthetic' => $cData['kinesthetic'],
                    'read_write' => $cData['read_write'],
                    'students' => $cData['students'],
                    'ai_recommendation_en' => $clsRec['en'],
                    'ai_recommendation_fr' => $clsRec['fr'],
                ];
            }

            $totalDivStudents += $scStudents;
            $totalDivAssessed += $scAssessed;
            $totalDivTeachers += $scTeachers;
            $divVis += $scVis; $divAud += $scAud; $divKin += $scKin; $divRw += $scRw;

            $assRate = $scStudents > 0 ? round(($scAssessed / $scStudents) * 100) . '%' : '0%';
            $scRec = generateSchoolPolicyRecommendation($scVis, $scAud, $scKin, $scRw, $scName);

            $schoolsList[] = [
                'name' => $scName,
                'teachers_count' => $scTeachers,
                'students_count' => $scStudents,
                'assessed_rate' => $assRate,
                'classes' => $scClassesData,
                'ai_recommendation_en' => $scRec['en'],
                'ai_recommendation_fr' => $scRec['fr'],
            ];
        }
        $divPolicyRec = generateDelegatePolicyRecommendation($divVis, $divAud, $divKin, $divRw, $division, false);

        respond(true, 'Divisional analytics fetched from live database.', [
            'title' => 'DÉLÉGATION DÉPARTEMENTALE DE L\'ENSEIGNEMENT SECONDAIRE',
            'delegate_name' => $authUser['full_name'] ?? 'M. Bikoi Joseph',
            'region' => $region,
            'division' => $division,
            'total_schools' => count($schoolsList),
            'total_students' => $totalDivStudents,
            'assessed_students' => $totalDivAssessed,
            'total_teachers' => $totalDivTeachers,
            'visual_count' => $divVis,
            'auditory_count' => $divAud,
            'kinesthetic_count' => $divKin,
            'read_write_count' => $divRw,
            'items' => $schoolsList,
            'ai_policy_en' => $divPolicyRec['en'],
            'ai_policy_fr' => $divPolicyRec['fr'],
        ]);
        break;

    // ── REGIONAL DELEGATE ANALYTICS ────────────────────────────────────
    case 'regional_analytics':
    case 'region_overview':
        $region = $authUser['region'] ?? 'ADAMOUA';

        // 1. Fetch schools in this region from Database
        $stmtSc = $pdo->prepare("SELECT id, name, division, town FROM schools WHERE region = ? OR region IS NULL OR region = ''");
        $stmtSc->execute([$region]);
        $schoolRows = $stmtSc->fetchAll(PDO::FETCH_ASSOC);

        $regTotalSchools = count($schoolRows);
        $regTotalStudents = 0;
        $regAssessed = 0;
        $regTeachers = 0;
        $regVis = 0; $regAud = 0; $regKin = 0; $regRw = 0;

        $divisionsMap = [];

        foreach ($schoolRows as $sc) {
            $scId = $sc['id'];
            $scName = $sc['name'];
            $div = !empty($sc['division']) ? $sc['division'] : 'DJEREM';

            if (!isset($divisionsMap[$div])) {
                $divisionsMap[$div] = [
                    'name' => $div,
                    'schools_count' => 0,
                    'teachers_count' => 0,
                    'students_count' => 0,
                    'assessed_count' => 0,
                    'schools' => [],
                ];
            }

            // Teachers count
            $stmtT = $pdo->prepare("SELECT COUNT(*) FROM teachers t JOIN users u ON u.id = t.user_id WHERE u.school_id = ?");
            $stmtT->execute([$scId]);
            $scTeachers = intval($stmtT->fetchColumn());

            // Students count
            $stmtSt = $pdo->prepare("SELECT COUNT(*) FROM students st JOIN users u ON u.id = st.user_id WHERE u.school_id = ?");
            $stmtSt->execute([$scId]);
            $scStudents = intval($stmtSt->fetchColumn());

            // Classes in school
            $stmtCls = $pdo->prepare("SELECT DISTINCT st.class_name FROM students st JOIN users u ON u.id = st.user_id WHERE u.school_id = ? AND st.class_name IS NOT NULL AND st.class_name != '' ORDER BY st.class_name ASC");
            $stmtCls->execute([$scId]);
            $clsList = $stmtCls->fetchAll(PDO::FETCH_COLUMN);

            $scClassesData = [];
            $scAssessed = 0;
            $scVis = 0; $scAud = 0; $scKin = 0; $scRw = 0;

            foreach ($clsList as $clsName) {
                $cData = getSchoolClassBreakdownAndRoster($pdo, $scId, $clsName);
                $scAssessed += $cData['assessed'];
                $scVis += $cData['visual']; $scAud += $cData['auditory']; $scKin += $cData['kinesthetic']; $scRw += $cData['read_write'];

                $clsRec = generateClassroomRecommendation($cData['visual'], $cData['auditory'], $cData['kinesthetic'], $cData['read_write'], "$clsName ($scName)");

                $scClassesData[] = [
                    'class_name' => $clsName,
                    'total_students' => $cData['total_students'],
                    'assessed' => $cData['assessed'],
                    'visual' => $cData['visual'],
                    'auditory' => $cData['auditory'],
                    'kinesthetic' => $cData['kinesthetic'],
                    'read_write' => $cData['read_write'],
                    'students' => $cData['students'],
                    'ai_recommendation_en' => $clsRec['en'],
                    'ai_recommendation_fr' => $clsRec['fr'],
                ];
            }

            $regTotalStudents += $scStudents;
            $regAssessed += $scAssessed;
            $regTeachers += $scTeachers;
            $regVis += $scVis; $regAud += $scAud; $regKin += $scKin; $regRw += $scRw;

            $divisionsMap[$div]['schools_count']++;
            $divisionsMap[$div]['teachers_count'] += $scTeachers;
            $divisionsMap[$div]['students_count'] += $scStudents;
            $divisionsMap[$div]['assessed_count'] += $scAssessed;

            $divisionsMap[$div]['schools'][] = [
                'name' => $scName,
                'teachers_count' => $scTeachers,
                'students_count' => $scStudents,
                'assessed_rate' => ($scStudents > 0 ? round(($scAssessed / $scStudents) * 100) . '%' : '0%'),
                'classes' => $scClassesData,
            ];
        }

        $divItems = [];
        foreach ($divisionsMap as $divKey => $divVal) {
            $stCount = $divVal['students_count'];
            $assCount = $divVal['assessed_count'];
            $divVal['assessed_rate'] = $stCount > 0 ? round(($assCount / $stCount) * 100) . '%' : '0%';
            $divItems[] = $divVal;
        }

        $regPolicyRec = generateDelegatePolicyRecommendation($regVis, $regAud, $regKin, $regRw, $region, true);
        $aiPolicyEn = $regPolicyRec['en'];
        $aiPolicyFr = $regPolicyRec['fr'];

        respond(true, 'Regional analytics fetched from live database.', [
            'title' => 'DÉLÉGATION RÉGIONALE DE L\'ENSEIGNEMENT SECONDAIRE',
            'delegate_name' => $authUser['full_name'] ?? 'Dr. Fouda Alphonse',
            'region' => $region,
            'division' => 'ALL DIVISIONS',
            'total_schools' => $regTotalSchools,
            'total_students' => $regTotalStudents,
            'assessed_students' => $regAssessed,
            'total_teachers' => $regTeachers,
            'visual_count' => $regVis,
            'auditory_count' => $regAud,
            'kinesthetic_count' => $regKin,
            'read_write_count' => $regRw,
            'items' => $divItems,
            'ai_policy_en' => $aiPolicyEn,
            'ai_policy_fr' => $aiPolicyFr,
        ]);
        break;

    // ── CENTRAL ADMIN ANALYTICS ────────────────────────────────────────
    case 'admin_analytics':
    case 'national_overview':
        $totalRegions  = intval($pdo->query("SELECT COUNT(DISTINCT region) FROM schools WHERE region IS NOT NULL AND region != ''")->fetchColumn() ?: 10);
        $totalSchools  = intval($pdo->query("SELECT COUNT(*) FROM schools")->fetchColumn() ?: 6);
        $totalStudents = intval($pdo->query("SELECT COUNT(*) FROM students")->fetchColumn() ?: 2);
        $totalTeachers = intval($pdo->query("SELECT COUNT(*) FROM teachers")->fetchColumn() ?: 1);

        $stmtVark = $pdo->query("
            SELECT 
                COUNT(DISTINCT a.student_id) AS assessed,
                SUM(CASE WHEN a.learning_style LIKE '%Visual%' THEN 1 ELSE 0 END) AS visual,
                SUM(CASE WHEN a.learning_style LIKE '%Auditory%' THEN 1 ELSE 0 END) AS auditory,
                SUM(CASE WHEN a.learning_style LIKE '%Kinesthetic%' THEN 1 ELSE 0 END) AS kinesthetic,
                SUM(CASE WHEN a.learning_style LIKE '%Read%' THEN 1 ELSE 0 END) AS rw_count
            FROM assessments a
        ");
        $vark = $stmtVark->fetch(PDO::FETCH_ASSOC);

        $stmtReg = $pdo->query("
            SELECT 
                sc.region AS name,
                COUNT(DISTINCT sc.id) AS schools,
                COUNT(DISTINCT st.id) AS students,
                COUNT(DISTINCT a.student_id) AS assessed
            FROM schools sc
            LEFT JOIN users u ON u.school_id = sc.id AND u.role = 'student'
            LEFT JOIN students st ON st.user_id = u.id
            LEFT JOIN assessments a ON a.student_id = st.id
            WHERE sc.region IS NOT NULL AND sc.region != ''
            GROUP BY sc.region
        ");
        $regRows = $stmtReg->fetchAll(PDO::FETCH_ASSOC);

        $allCameroonRegions = [
            'ADAMOUA', 'CENTRE', 'EST', 'EXTREME-NORD', 'LITTORAL', 
            'NORD', 'NORD-OUEST', 'OUEST', 'SUD', 'SUD-OUEST'
        ];

        $regRowsMap = [];
        foreach ($regRows as $r) {
            $regRowsMap[$r['name']] = $r;
        }

        $regAnalytics = [];
        foreach ($allCameroonRegions as $regName) {
            if (isset($regRowsMap[$regName])) {
                $r = $regRowsMap[$regName];
                $stCount = intval($r['students']);
                $assCount = intval($r['assessed']);
                $pct = $stCount > 0 ? round(($assCount / $stCount) * 100) . '%' : '0%';
                $regAnalytics[] = [
                    'name' => $regName,
                    'schools' => intval($r['schools']),
                    'students' => $stCount,
                    'assessed_pct' => $pct,
                ];
            } else {
                $regAnalytics[] = [
                    'name' => $regName,
                    'schools' => 0,
                    'students' => 0,
                    'assessed_pct' => '0%',
                ];
            }
        }

        // Build full national hierarchy for all 10 Regions: Region -> Division -> School -> Class
        $nationalItems = [];
        foreach ($allCameroonRegions as $regName) {
            $stmtDivs = $pdo->prepare("SELECT DISTINCT division FROM schools WHERE region = ? AND division IS NOT NULL AND division != '' ORDER BY division");
            $stmtDivs->execute([$regName]);
            $divList = $stmtDivs->fetchAll(PDO::FETCH_COLUMN);

            $divItems = [];
            foreach ($divList as $divName) {
                $stmtSc = $pdo->prepare("SELECT id, name FROM schools WHERE region = ? AND division = ? ORDER BY name");
                $stmtSc->execute([$regName, $divName]);
                $schoolsList = $stmtSc->fetchAll(PDO::FETCH_ASSOC);

                $scItems = [];
                foreach ($schoolsList as $sc) {
                    $scId = $sc['id'];
                    $stmtCls = $pdo->prepare("SELECT DISTINCT st.class_name FROM students st JOIN users u ON u.id = st.user_id WHERE u.school_id = ? AND st.class_name IS NOT NULL AND st.class_name != '' ORDER BY st.class_name");
                    $stmtCls->execute([$scId]);
                    $classList = $stmtCls->fetchAll(PDO::FETCH_COLUMN);

                    $clsItems = [];
                    foreach ($classList as $cn) {
                        $clsItems[] = ['class_name' => $cn];
                    }

                    $scItems[] = [
                        'id' => $scId,
                        'name' => $sc['name'],
                        'classes' => $clsItems,
                    ];
                }

                $divItems[] = [
                    'name' => $divName,
                    'schools' => $scItems,
                ];
            }

            $nationalItems[] = [
                'name' => $regName,
                'divisions' => $divItems,
            ];
        }
        $visCount = intval($vark['visual'] ?? 0);
        $audCount = intval($vark['auditory'] ?? 0);
        $kinCount = intval($vark['kinesthetic'] ?? 0);
        $rwCount  = intval($vark['rw_count'] ?? 0);
        $totalVark = $visCount + $audCount + $kinCount + $rwCount;

        $dominant = 'Auditory';
        $maxCount = $audCount;
        if ($visCount > $maxCount) { $maxCount = $visCount; $dominant = 'Visual'; }
        if ($kinCount > $maxCount) { $maxCount = $kinCount; $dominant = 'Kinesthetic'; }
        if ($rwCount > $maxCount)  { $maxCount = $rwCount;  $dominant = 'Read/Write'; }

        $pct = $totalVark > 0 ? round(($maxCount / $totalVark) * 100) : 0;

        $recEn = [];
        $recFr = [];

        if ($dominant == 'Auditory') {
            $recEn[] = "• Dominant Auditory Preference Detected" . ($pct > 0 ? " ({$pct}% of assessed students)" : "") . ": National statistics indicate a higher proportion of Auditory learners. Prioritize interactive classroom discussions, verbal lecture summaries, peer debates, and audio-assisted learning toolkits across secondary schools.";
            $recFr[] = "• Préférence Auditive Dominante Détectée" . ($pct > 0 ? " ({$pct}% des élèves évalués)" : "") . " : Les statistiques nationales indiquent une proportion plus élevée d'apprenants auditifs. Privilégiez les discussions interactives en classe, les résumés de cours oraux, les débats et les outils audio.";
        } elseif ($dominant == 'Visual') {
            $recEn[] = "• Dominant Visual Preference Detected" . ($pct > 0 ? " ({$pct}% of assessed students)" : "") . ": National statistics indicate a higher proportion of Visual learners. Prioritize visual mind maps, graphic organizers, color-coded study guides, and video presentations.";
            $recFr[] = "• Préférence Visuelle Dominante Détectée" . ($pct > 0 ? " ({$pct}% des élèves évalués)" : "") . " : Les statistiques nationales indiquent une proportion plus élevée d'apprenants visuels. Privilégiez les cartes mentales, schémas, guides en couleurs et présentations vidéo.";
        } elseif ($dominant == 'Kinesthetic') {
            $recEn[] = "• Dominant Kinesthetic Preference Detected" . ($pct > 0 ? " ({$pct}% of assessed students)" : "") . ": National statistics indicate a higher proportion of Kinesthetic learners. Prioritize hands-on laboratory workshops, practical experiments, and kinesthetic learning kits.";
            $recFr[] = "• Préférence Kinesthésique Dominante Détectée" . ($pct > 0 ? " ({$pct}% des élèves évalués)" : "") . " : Les statistiques nationales indiquent une proportion plus élevée d'apprenants kinesthésiques. Privilégiez les travaux pratiques en laboratoire et les kits kinesthésiques.";
        } else {
            $recEn[] = "• Dominant Read/Write Preference Detected" . ($pct > 0 ? " ({$pct}% of assessed students)" : "") . ": National statistics indicate a higher proportion of Read/Write learners. Prioritize structured text materials, reading comprehension modules, and essay writing frameworks.";
            $recFr[] = "• Préférence Lecture/Écriture Dominante Détectée" . ($pct > 0 ? " ({$pct}% des élèves évalués)" : "") . " : Les statistiques nationales indiquent une proportion plus élevée d'apprenants lecture/écriture. Privilégiez les manuels structurés et les modules de rédaction.";
        }

        // Encourage all other learning styles as well
        $recEn[] = "• Visual Learning Support: Equip classrooms with visual charts, multi-colored whiteboards, and visual media tools to support visual learners.";
        $recFr[] = "• Soutien à l'Apprentissage Visuel : Équipez les classes de graphiques visuels, de tableaux colorés et de supports médias pour soutenir les élèves visuels.";

        $recEn[] = "• Kinesthetic & Practical Workshop Guidance: Provide hands-on laboratory exercises, interactive workshops, and practical learning kits.";
        $recFr[] = "• Orientation des Ateliers Kinesthésiques et Pratiques : Fournissez des travaux pratiques de laboratoire, des ateliers interactifs et des kits d'apprentissage.";

        $recEn[] = "• Read/Write Reinforcement: Supply comprehensive textbook reference guides, structured note-taking templates, and school library materials.";
        $recFr[] = "• Renforcement de la Lecture et de l'Écriture : Fournissez des manuels de référence complets, des modèles de prise de notes structurés et des ressources en bibliothèque.";

        respond(true, 'Admin analytics fetched from live database.', [
            'admin_name' => $authUser['full_name'] ?? 'Dr. Tchatchouang Paul',
            'title' => 'MINISTÈRE DE L\'ENSEIGNEMENT SECONDAIRE — DIRECTION GÉNÉRALE',
            'total_regions' => $totalRegions,
            'total_schools' => $totalSchools,
            'total_students' => $totalStudents,
            'assessed_students' => intval($vark['assessed'] ?? 0),
            'total_teachers' => $totalTeachers,
            'visual_count' => $visCount,
            'auditory_count' => $audCount,
            'kinesthetic_count' => $kinCount,
            'read_write_count' => $rwCount,
            'regions_analytics' => $regAnalytics,
            'national_hierarchy' => $nationalItems,
            'ai_national_strategy_en' => implode("\n", $recEn),
            'ai_national_strategy_fr' => implode("\n", $recFr),
        ]);
        break;

    // ── TEACHER CLASS ANALYTICS ───────────────────────────────────────
    case 'teacher_class':
        $stmtT = $pdo->prepare("SELECT staff_id, subject, class_name FROM teachers WHERE user_id = ?");
        $stmtT->execute([$userId]);
        $tData = $stmtT->fetch() ?: ['staff_id' => 'T2026001', 'subject' => 'Informatique', 'class_name' => '1ère TI'];

        $stmtC = $pdo->prepare("SELECT DISTINCT class_name FROM teacher_classes WHERE teacher_id = ? ORDER BY class_name");
        $stmtC->execute([$userId]);
        $tickedClasses = $stmtC->fetchAll(PDO::FETCH_COLUMN);
        if (empty($tickedClasses)) $tickedClasses = ['1ère TI', 'Terminale TI'];

        $reqClass = trim($body['class_name'] ?? $_GET['class_name'] ?? '');
        $targetClass = (!empty($reqClass) && in_array($reqClass, $tickedClasses)) ? $reqClass : $tickedClasses[0];

        // 1. Compute DB metrics per class
        $classSummaries = [];
        $overallStudents = 0;
        $overallAssessed = 0;

        foreach ($tickedClasses as $cls) {
            $stTotalStmt = $pdo->prepare("SELECT COUNT(*) FROM students WHERE class_name = ?");
            $stTotalStmt->execute([$cls]);
            $totCls = intval($stTotalStmt->fetchColumn() ?: 0);

            $stAssessedStmt = $pdo->prepare("
                SELECT COUNT(DISTINCT a.student_id) 
                FROM assessments a 
                JOIN students s ON s.id = a.student_id 
                WHERE s.class_name = ?
            ");
            $stAssessedStmt->execute([$cls]);
            $assCls = intval($stAssessedStmt->fetchColumn() ?: 0);

            $overallStudents += $totCls;
            $overallAssessed += $assCls;

            $classSummaries[] = [
                'class_name'     => $cls,
                'total_students' => $totCls,
                'assessed'       => $assCls,
            ];
        }

        // 2. Fetch student roster for targetClass and compute AVERAGE (Summary) scores across all test attempts per student
        $stmtSt = $pdo->prepare("
            SELECT s.id AS student_id, u.full_name, s.class_name, s.mat_number
            FROM students s
            JOIN users u ON u.id = s.user_id
            WHERE s.class_name = ?
            ORDER BY u.full_name ASC
        ");
        $stmtSt->execute([$targetClass]);
        $studentsList = $stmtSt->fetchAll(PDO::FETCH_ASSOC);

        $rows = [];
        foreach ($studentsList as $st) {
            $stId = $st['student_id'];
            
            // Fetch ALL assessments for this student
            $stmtAss = $pdo->prepare("
                SELECT visual_score, auditory_score, kinesthetic_score, read_write_score, learning_style 
                FROM assessments 
                WHERE student_id = ? 
                ORDER BY completed_at ASC
            ");
            $stmtAss->execute([$stId]);
            $assList = $stmtAss->fetchAll(PDO::FETCH_ASSOC);

            if (!empty($assList)) {
                $count = count($assList);
                $sumV = 0; $sumA = 0; $sumK = 0; $sumR = 0;
                foreach ($assList as $assItem) {
                    $sumV += floatval($assItem['visual_score']);
                    $sumA += floatval($assItem['auditory_score']);
                    $sumK += floatval($assItem['kinesthetic_score']);
                    $sumR += floatval($assItem['read_write_score']);
                }

                $avgV = round($sumV / $count);
                $avgA = round($sumA / $count);
                $avgK = round($sumK / $count);
                $avgR = round($sumR / $count);

                // Determine dominant style from averaged scores
                $scoresMap = [
                    'Auditory'    => $avgA,
                    'Visual'      => $avgV,
                    'Kinesthetic' => $avgK,
                    'Read/Write'  => $avgR,
                ];
                arsort($scoresMap);
                $topScore = reset($scoresMap);
                $topStyles = [];
                foreach ($scoresMap as $stName => $stVal) {
                    if ($stVal === $topScore) $topStyles[] = $stName;
                }
                $compositeStyle = (count($topStyles) > 1) 
                    ? implode('-', $topStyles) . ' (Dual Style)'
                    : $topStyles[0];

                $rows[] = [
                    'full_name'         => $st['full_name'],
                    'class_name'        => $st['class_name'],
                    'mat_number'        => $st['mat_number'],
                    'learning_style'    => $compositeStyle,
                    'visual_score'      => $avgV,
                    'auditory_score'    => $avgA,
                    'kinesthetic_score' => $avgK,
                    'read_write_score'  => $avgR,
                    'attempt_count'     => $count,
                ];
            } else {
                $rows[] = [
                    'full_name'         => $st['full_name'],
                    'class_name'        => $st['class_name'],
                    'mat_number'        => $st['mat_number'],
                    'learning_style'    => 'Not Assessed',
                    'visual_score'      => 0,
                    'auditory_score'    => 0,
                    'kinesthetic_score' => 0,
                    'read_write_score'  => 0,
                    'attempt_count'     => 0,
                ];
            }
        }

        // 3. VARK score distribution for targetClass
        $vCount = 0; $aCount = 0; $kCount = 0; $rwCount = 0; $assessedTarget = 0;
        foreach ($rows as $r) {
            if (!empty($r['learning_style'])) {
                $assessedTarget++;
                $style = strtolower($r['learning_style']);
                if (strpos($style, 'visual') !== false) $vCount++;
                if (strpos($style, 'auditory') !== false) $aCount++;
                if (strpos($style, 'kinesthetic') !== false) $kCount++;
                if (strpos($style, 'read') !== false) $rwCount++;
            }
        }

        respond(true, 'Class results.', [
            'class_name'             => $targetClass,
            'subject'                => $tData['subject'] ?: 'Informatique',
            'staff_id'               => $tData['staff_id'] ?: 'T2026001',
            'ticked_classes'         => $tickedClasses,
            'class_summaries'        => $classSummaries,
            'overall_total_classes'  => count($tickedClasses),
            'overall_total_students' => $overallStudents,
            'overall_total_assessed' => $overallAssessed,
            'students'               => $rows,
            'summary'                => [
                'total_students' => count($rows),
                'assessed'       => $assessedTarget,
                'visual'         => $vCount,
                'auditory'       => $aCount,
                'kinesthetic'    => $kCount,
                'read_write'     => $rwCount,
            ],
            'ai_recommendation_en' => "• Primary Mode: Diagnostic analysis active for class $targetClass.\n• Utilize color-coded visual charts, interactive technical demonstrations, and targeted reading materials based on $targetClass scores.",
            'ai_recommendation_fr' => "• Mode Principal : Analyse diagnostique active pour la classe de $targetClass.\n• Utilisez des schémas visuels en couleurs, des TP interactifs et des supports de lecture ciblés selon les résultats de $targetClass.",
        ]);
        break;

    default:
        respondError('Unknown action.', 404);
}
