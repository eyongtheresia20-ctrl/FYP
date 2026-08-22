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

            $recEn = "• Integrate visual mind maps, flowchart diagrams, and auditory lectures tailored for $cls.\n• Encourage interactive peer discussions and practical lab sessions.";
            $recFr = "• Intégrez des cartes mentales visuelles, des schémas et des cours auditifs adaptés pour la classe de $cls.\n• Encouragez les discussions interactives entre pairs et les séances de travaux pratiques.";

            $classBreakdown[] = [
                'class_name' => $cls,
                'total_students' => $cData['total_students'],
                'assessed' => $cData['assessed'],
                'visual' => $cData['visual'],
                'auditory' => $cData['auditory'],
                'kinesthetic' => $cData['kinesthetic'],
                'read_write' => $cData['read_write'],
                'students' => $cData['students'],
                'ai_recommendation_en' => $recEn,
                'ai_recommendation_fr' => $recFr,
            ];
        }

        $vark = [
            'assessed' => $scAssessed,
            'visual' => $scVis,
            'auditory' => $scAud,
            'kinesthetic' => $scKin,
            'rw_count' => $scRw,
        ];

        // Fetch all students for Principal Student Management Data Table
        $stmtAllSt = $pdo->prepare("
            SELECT st.id AS student_id, u.id AS user_id, u.full_name, COALESCE(st.matricule, u.matricule) AS matricule,
                   st.class_name, st.gender, st.birth_date, u.region, u.division, COALESCE(u.is_activated, 1) AS is_activated,
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
            'ai_policy_en' => "• Prioritize practical ICT laboratory resources to accommodate visual and kinesthetic learners.\n• Organize inter-class workshops and auditory seminars for language and humanities subjects.\n• Request MINESEC pedagogical support for updated digital learning aids.",
            'ai_policy_fr' => "• Priorisez les équipements de laboratoires informatiques pratiques pour répondre aux besoins des apprenants visuels et kinesthésiques.\n• Organisez des ateliers inter-classes et séminaires auditifs pour les matières littéraires.\n• Sollicitez le soutien pédagogique du MINESEC pour le matériel d'apprentissage numérique.",
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

                $scClassesData[] = [
                    'class_name' => $clsName,
                    'total_students' => $cData['total_students'],
                    'assessed' => $cData['assessed'],
                    'visual' => $cData['visual'],
                    'auditory' => $cData['auditory'],
                    'kinesthetic' => $cData['kinesthetic'],
                    'read_write' => $cData['read_write'],
                    'students' => $cData['students'],
                    'ai_recommendation_en' => "• Prioritize interactive VARK workshops and visual flowcharts for $clsName at $scName.",
                    'ai_recommendation_fr' => "• Priorisez les ateliers VARK interactifs et les organigrammes visuels pour la classe de $clsName à $scName.",
                ];
            }

            $totalDivStudents += $scStudents;
            $totalDivAssessed += $scAssessed;
            $totalDivTeachers += $scTeachers;
            $divVis += $scVis; $divAud += $scAud; $divKin += $scKin; $divRw += $scRw;

            $assRate = $scStudents > 0 ? round(($scAssessed / $scStudents) * 100) . '%' : '0%';

            $schoolsList[] = [
                'name' => $scName,
                'teachers_count' => $scTeachers,
                'students_count' => $scStudents,
                'assessed_rate' => $assRate,
                'classes' => $scClassesData,
                'ai_recommendation_en' => "• School Policy Recommendation for $scName: Allocate digital learning aids and conduct teacher VARK seminars.",
                'ai_recommendation_fr' => "• Recommandation Pédagogique pour $scName : Allouez du matériel numérique et organisez des séminaires d'apprentissage VARK.",
            ];
        }

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
            'ai_policy_en' => "• Divisional Policy Directive for $division: Coordinate inspection visits and prioritize digital infrastructure across technical and general secondary lycées.",
            'ai_policy_fr' => "• Directive Départementale pour le $division : Coordonnez les inspections pédagogiques et priorisez l'infrastructure numérique dans les lycées.",
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

                $scClassesData[] = [
                    'class_name' => $clsName,
                    'total_students' => $cData['total_students'],
                    'assessed' => $cData['assessed'],
                    'visual' => $cData['visual'],
                    'auditory' => $cData['auditory'],
                    'kinesthetic' => $cData['kinesthetic'],
                    'read_write' => $cData['read_write'],
                    'students' => $cData['students'],
                    'ai_recommendation_en' => "• VARK Analysis for $clsName at $scName: " . ($cData['assessed'] > 0 ? "Visual: {$cData['visual']}, Auditory: {$cData['auditory']}, Kinesthetic: {$cData['kinesthetic']}, Read/Write: {$cData['read_write']}." : "Assessments pending."),
                    'ai_recommendation_fr' => "• Analyse VARK pour la classe $clsName à $scName : " . ($cData['assessed'] > 0 ? "Visuel: {$cData['visual']}, Auditif: {$cData['auditory']}, Kinesthésique: {$cData['kinesthetic']}, Lecture/Écriture: {$cData['read_write']}." : "Évaluations en attente."),
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

        $totalVarkReg = $regVis + $regAud + $regKin + $regRw;
        if ($totalVarkReg > 0) {
            $regStyles = [
                'Visual' => $regVis,
                'Auditory' => $regAud,
                'Kinesthetic' => $regKin,
                'Read/Write' => $regRw
            ];
            arsort($regStyles);
            $domStyle = key($regStyles);
            $domCount = current($regStyles);
            $domPct = round(($domCount / $totalVarkReg) * 100);

            $aiPolicyEn = "• Dominant Regional VARK Learning Profile for $region Region: $domStyle ($domPct% of assessed students across all regional lycées).\n" .
                          "• Regional Equipment Directive: Allocate digital projectors, interactive smartboards, and visual simulation software to technical and general secondary schools across all divisions in $region.\n" .
                          "• Pedagogical Training Strategy: Establish regional teacher seminars focused on VARK-adaptive lesson planning and visual diagrammatic instruction.";

            $aiPolicyFr = "• Profil Pédagogique VARK Dominant pour la Région de l'$region : $domStyle ($domPct% des élèves évalués dans tous les lycées régionaux).\n" .
                          "• Directive Régionale d'Équipement : Allouez des projecteurs numériques, des tableaux interactifs et des logiciels de simulation visuelle dans tous les départements de l'$region.\n" .
                          "• Stratégie de Formation Pédagogique : Organisez des séminaires régionaux de formation des enseignants à la pédagogie différenciée VARK et aux supports visuels d'enseignement.";
        } else {
            $aiPolicyEn = "• Regional Policy Directive for $region: Assessment coverage in progress. Coordinate with divisional delegates to accelerate student VARK diagnostic completion.";
            $aiPolicyFr = "• Directive Régionale pour l'$region : Couverture des évaluations en cours. Coordonnez avec les délégués départementaux pour accélérer le diagnostic VARK des élèves.";
        }

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

        respond(true, 'Admin analytics fetched from live database.', [
            'admin_name' => $authUser['full_name'] ?? 'Dr. Tchatchouang Paul',
            'title' => 'MINISTÈRE DE L\'ENSEIGNEMENT SECONDAIRE — DIRECTION GÉNÉRALE',
            'total_regions' => $totalRegions,
            'total_schools' => $totalSchools,
            'total_students' => $totalStudents,
            'assessed_students' => intval($vark['assessed'] ?? 0),
            'total_teachers' => $totalTeachers,
            'visual_count' => intval($vark['visual'] ?? 0),
            'auditory_count' => intval($vark['auditory'] ?? 0),
            'kinesthetic_count' => intval($vark['kinesthetic'] ?? 0),
            'read_write_count' => intval($vark['rw_count'] ?? 0),
            'regions_analytics' => $regAnalytics,
            'national_hierarchy' => $nationalItems,
            'ai_national_strategy_en' => "• National Pedagogical Strategy: Live diagnostic tracking active. Total assessed: " . intval($vark['assessed'] ?? 0) . " out of $totalStudents students.",
            'ai_national_strategy_fr' => "• Stratégie Pédagogique Nationale : Suivi diagnostique en direct. Total évalué : " . intval($vark['assessed'] ?? 0) . " sur $totalStudents élèves.",
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
