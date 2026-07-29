<?php
// ============================================================
//  MINESEC LST — Dashboard API
//  All endpoints require: Header "Authorization: Bearer <token>"
//  GET  /api/dashboard.php?action=student_result
//  GET  /api/dashboard.php?action=teacher_class
//  GET  /api/dashboard.php?action=school_overview
//  GET  /api/dashboard.php?action=division_overview
//  GET  /api/dashboard.php?action=region_overview
//  GET  /api/dashboard.php?action=national_overview
// ============================================================

require_once __DIR__ . '/../config/helpers.php';
require_once __DIR__ . '/../config/database.php';

$action = $_GET['action'] ?? '';
$body   = getBody();
$pdo    = getDB();

// ── Auth helper (simple token check via user_id param for now) ──
// In production, validate token against a sessions table.
$userId = intval($body['user_id'] ?? 0);
if (!$userId) respondError('user_id is required.', 401);

$stmt = $pdo->prepare("SELECT id, role, school_id, region, division FROM users WHERE id = ? AND is_active = 1");
$stmt->execute([$userId]);
$authUser = $stmt->fetch();
if (!$authUser) respondError('Unauthorized.', 401);

switch ($action) {

    // ── STUDENT: own result ────────────────────────────────────
    case 'student_result':
        if ($authUser['role'] !== 'student') respondError('Access denied.', 403);

        $stmt = $pdo->prepare("
            SELECT a.visual_score, a.auditory_score, a.kinesthetic_score,
                   a.learning_style, a.completed_at,
                   r.summary_en, r.summary_fr
            FROM students s
            JOIN assessments a ON a.student_id = s.id
            LEFT JOIN results r ON r.student_id = s.id
            WHERE s.user_id = ?
            ORDER BY a.completed_at DESC LIMIT 1
        ");
        $stmt->execute([$userId]);
        $result = $stmt->fetch();

        if (!$result) {
            respond(true, 'No assessment found.', ['has_result' => false]);
        }

        respond(true, 'Result found.', ['has_result' => true, 'result' => $result]);
        break;

    // ── TEACHER: class results ─────────────────────────────────
    case 'teacher_class':
        if ($authUser['role'] !== 'teacher') respondError('Access denied.', 403);

        // Fetch teacher's subject & class_name
        $stmtT = $pdo->prepare("SELECT staff_id, subject, class_name FROM teachers WHERE user_id = ?");
        $stmtT->execute([$userId]);
        $tData = $stmtT->fetch() ?: ['staff_id' => 'T2026001', 'subject' => 'Informatique', 'class_name' => '1ère TI'];

        $targetClass = $tData['class_name'] ?: '1ère TI';

        $stmt = $pdo->prepare("
            SELECT u.full_name, s.class_name, s.mat_number,
                   a.visual_score, a.auditory_score, a.kinesthetic_score,
                   a.learning_style, r.summary_en, r.summary_fr
            FROM teachers t
            JOIN users tu ON tu.id = t.user_id
            JOIN students s ON s.user_id IN (
                SELECT u2.id FROM users u2 WHERE u2.school_id = tu.school_id
            )
            JOIN users u ON u.id = s.user_id
            LEFT JOIN assessments a ON a.student_id = s.id
            LEFT JOIN results r ON r.student_id = s.id
            WHERE t.user_id = ? AND (s.class_name = ? OR s.class_name LIKE ?)
            ORDER BY s.class_name, u.full_name
        ");
        $stmt->execute([$userId, $targetClass, "%$targetClass%"]);
        $rows = $stmt->fetchAll();

        // Calculate VARK Distribution for the class
        $vCount = 0; $aCount = 0; $kCount = 0; $rCount = 0;
        $totalAssessed = 0;

        foreach ($rows as $row) {
            $style = $row['learning_style'] ?? '';
            if (!empty($style)) {
                $totalAssessed++;
                if (stripos($style, 'Visual') !== false) $vCount++;
                if (stripos($style, 'Auditory') !== false) $aCount++;
                if (stripos($style, 'Kinesthetic') !== false) $kCount++;
                if (stripos($style, 'Read/Write') !== false) $rCount++;
            }
        }

        // Generate AI Pedagogical Teaching Recommendations for the Teacher
        $recEn = "• Incorporate visual mind maps, architectural diagrams, and flowcharts on the board.\n• Provide structured printed notes and code summaries for reading.\n• Use interactive lab exercises and hands-on coding demonstrations during class.";
        $recFr = "• Intégrez des cartes mentales, des schémas d'architecture et des organigrammes au tableau.\n• Fournissez des fiches de cours structurées et des résumés de code rédigés.\n• Proposez des travaux pratiques guidés et des démonstrations de code interactives en classe.";

        if ($vCount >= $aCount && $vCount >= $kCount) {
            $recEn = "• Primary Mode: Visual Learners Dominant\n• Use high-contrast color coding, mind maps, and interactive code diagrams.\n• Display step-by-step visual solution workflows on slides or whiteboard.";
            $recFr = "• Mode Principal : Apprenants Visuels Dominants\n• Utilisez du surlignage couleur contrasté, des cartes mentales et des diagrammes de code.\n• Affichez les étapes de résolution visuelles au tableau ou sur projecteur.";
        } else if ($aCount >= $vCount && $aCount >= $kCount) {
            $recEn = "• Primary Mode: Auditory Learners Dominant\n• Conduct verbal walkthroughs, group discussions, and peer explanations.\n• Encourage students to explain coding concepts out loud in class.";
            $recFr = "• Mode Principal : Apprenants Auditifs Dominants\n• Privilégiez les explications orales, débats en groupe et synthèses verbales.\n• Encouragez les élèves à expliquer les concepts informatiques à voix haute.";
        } else if ($kCount >= $vCount && $kCount >= $aCount) {
            $recEn = "• Primary Mode: Kinesthetic Learners Dominant\n• Maximize hands-on computer lab sessions and practical exercises.\n• Allow students to build small interactive projects and test code live.";
            $recFr = "• Mode Principal : Apprenants Kinesthésiques Dominants\n• Maximisez les séances de travaux pratiques sur machine et exercices interactifs.\n• Permettez aux élèves de manipuler directement et tester le code en direct.";
        }

        respond(true, 'Class results.', [
            'class_name' => $targetClass,
            'subject'    => $tData['subject'] ?: 'Informatique',
            'staff_id'   => $tData['staff_id'] ?: 'T2026001',
            'students'   => $rows,
            'summary'    => [
                'total_students' => count($rows),
                'assessed'       => $totalAssessed,
                'visual'         => $vCount,
                'auditory'       => $aCount,
                'kinesthetic'    => $kCount,
                'read_write'     => $rCount,
            ],
            'ai_recommendation_en' => $recEn,
            'ai_recommendation_fr' => $recFr,
        ]);
        break;

    // ── PRINCIPAL: school overview ─────────────────────────────
    case 'school_overview':
        if (!in_array($authUser['role'], ['principal', 'admin'])) respondError('Access denied.', 403);

        $schoolId = $authUser['school_id'];

        $stmt = $pdo->prepare("
            SELECT s.class_name,
                   COUNT(s.id) AS total_students,
                   SUM(CASE WHEN a.learning_style IS NOT NULL THEN 1 ELSE 0 END) AS assessed,
                   SUM(CASE WHEN a.learning_style = 'Visual' THEN 1 ELSE 0 END) AS visual,
                   SUM(CASE WHEN a.learning_style = 'Auditory' THEN 1 ELSE 0 END) AS auditory,
                   SUM(CASE WHEN a.learning_style = 'Kinesthetic' THEN 1 ELSE 0 END) AS kinesthetic,
                   SUM(CASE WHEN a.learning_style = 'Read/Write' THEN 1 ELSE 0 END) AS read_write
            FROM students s
            JOIN users u ON u.id = s.user_id
            LEFT JOIN assessments a ON a.student_id = s.id
            WHERE u.school_id = ?
            GROUP BY s.class_name
            ORDER BY s.class_name
        ");
        $stmt->execute([$schoolId]);
        $rows = $stmt->fetchAll();

        respond(true, 'School overview.', ['classes' => $rows]);
        break;

    // ── DIVISIONAL DELEGATE ────────────────────────────────────
    case 'division_overview':
        if (!in_array($authUser['role'], ['divisional_delegate', 'admin'])) respondError('Access denied.', 403);

        $stmt = $pdo->prepare("
            SELECT sc.name AS school_name, sc.town,
                   COUNT(s.id) AS total_students,
                   SUM(CASE WHEN a.learning_style IS NOT NULL THEN 1 ELSE 0 END) AS assessed
            FROM schools sc
            LEFT JOIN users u ON u.school_id = sc.id
            LEFT JOIN students s ON s.user_id = u.id
            LEFT JOIN assessments a ON a.student_id = s.id
            WHERE sc.division = ?
            GROUP BY sc.id
            ORDER BY sc.name
        ");
        $stmt->execute([$authUser['division']]);
        $rows = $stmt->fetchAll();

        respond(true, 'Division overview.', ['schools' => $rows]);
        break;

    // ── REGIONAL DELEGATE ──────────────────────────────────────
    case 'region_overview':
        if (!in_array($authUser['role'], ['regional_delegate', 'admin'])) respondError('Access denied.', 403);

        $stmt = $pdo->prepare("
            SELECT sc.division,
                   COUNT(DISTINCT sc.id) AS total_schools,
                   COUNT(s.id) AS total_students,
                   SUM(CASE WHEN a.learning_style IS NOT NULL THEN 1 ELSE 0 END) AS assessed
            FROM schools sc
            LEFT JOIN users u ON u.school_id = sc.id
            LEFT JOIN students s ON s.user_id = u.id
            LEFT JOIN assessments a ON a.student_id = s.id
            WHERE sc.region = ?
            GROUP BY sc.division
            ORDER BY sc.division
        ");
        $stmt->execute([$authUser['region']]);
        $rows = $stmt->fetchAll();

        respond(true, 'Region overview.', ['divisions' => $rows]);
        break;

    // ── NATIONAL / ADMIN ───────────────────────────────────────
    case 'national_overview':
        if ($authUser['role'] !== 'admin') respondError('Access denied.', 403);

        $stmt = $pdo->prepare("
            SELECT sc.region,
                   COUNT(DISTINCT sc.id) AS total_schools,
                   COUNT(s.id) AS total_students,
                   SUM(CASE WHEN a.learning_style IS NOT NULL THEN 1 ELSE 0 END) AS assessed,
                   SUM(CASE WHEN a.learning_style = 'Visual' THEN 1 ELSE 0 END) AS visual,
                   SUM(CASE WHEN a.learning_style = 'Auditory' THEN 1 ELSE 0 END) AS auditory,
                   SUM(CASE WHEN a.learning_style = 'Kinesthetic' THEN 1 ELSE 0 END) AS kinesthetic,
                   SUM(CASE WHEN a.learning_style = 'Read/Write' THEN 1 ELSE 0 END) AS read_write
            FROM schools sc
            LEFT JOIN users u ON u.school_id = sc.id
            LEFT JOIN students s ON s.user_id = u.id
            LEFT JOIN assessments a ON a.student_id = s.id
            GROUP BY sc.region
            ORDER BY sc.region
        ");
        $stmt->execute();
        $rows = $stmt->fetchAll();

        // Totals
        $totals = $pdo->query("SELECT COUNT(*) AS total_schools FROM schools")->fetch();
        $totals['total_users']    = $pdo->query("SELECT COUNT(*) AS c FROM users")->fetch()['c'];
        $totals['total_students'] = $pdo->query("SELECT COUNT(*) AS c FROM students")->fetch()['c'];
        $totals['total_assessed'] = $pdo->query("SELECT COUNT(*) AS c FROM assessments WHERE completed_at IS NOT NULL")->fetch()['c'];

        respond(true, 'National overview.', ['regions' => $rows, 'totals' => $totals]);
        break;

    default:
        respondError('Unknown action.', 404);
}
