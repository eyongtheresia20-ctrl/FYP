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

        $stmt = $pdo->prepare("
            SELECT u.full_name, s.class_name, s.mat_number,
                   a.visual_score, a.auditory_score, a.kinesthetic_score,
                   a.learning_style, r.summary_en, r.summary_fr
            FROM teachers t
            JOIN users tu ON tu.id = t.user_id
            JOIN schools sc ON sc.id = tu.school_id
            JOIN students s ON s.user_id IN (
                SELECT u2.id FROM users u2 WHERE u2.school_id = tu.school_id
            )
            JOIN users u ON u.id = s.user_id
            LEFT JOIN assessments a ON a.student_id = s.id
            LEFT JOIN results r ON r.student_id = s.id
            WHERE t.user_id = ?
            ORDER BY s.class_name, u.full_name
        ");
        $stmt->execute([$userId]);
        $rows = $stmt->fetchAll();

        respond(true, 'Class results.', ['students' => $rows]);
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
