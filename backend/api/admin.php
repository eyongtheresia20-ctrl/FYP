<?php
// ============================================================
//  MINESEC LST — Central Admin & System Governance API
//  GET /api/admin.php?action=get_all_users
//  POST /api/admin.php?action=create_user
//  GET /api/admin.php?action=get_all_schools
//  POST /api/admin.php?action=create_school
//  GET /api/admin.php?action=get_class_details
// ============================================================

require_once __DIR__ . '/../config/helpers.php';
require_once __DIR__ . '/../config/database.php';

$action = $_GET['action'] ?? '';
$body   = getBody();
$pdo    = getDB();

switch ($action) {

    // ── 1. GET ALL USERS IN SYSTEM ──────────────────────────────
    case 'get_all_users':
        $stmt = $pdo->query("
            SELECT 
                u.id,
                u.full_name,
                COALESCE(NULLIF(u.matricule, ''), st.matricule, st.mat_number, t.matricule, t.staff_id, pr.matricule, pr.staff_id, 'N/A') AS matricule,
                u.email,
                u.role,
                u.is_activated,
                u.region,
                u.division,
                u.security_code,
                u.school_id,
                CASE 
                    WHEN u.role = 'admin' THEN 'Administration Centrale MINESEC'
                    WHEN u.role = 'regional_delegate' THEN CONCAT('Délégation Régionale (', u.region, ')')
                    WHEN u.role = 'divisional_delegate' THEN CONCAT('Délégation Départementale (', u.division, ')')
                    ELSE COALESCE(sc.name, st.school_name, t.school_name, pr.school_name, 'N/A')
                END AS school_name,
                st.class_name AS student_class,
                t.class_name AS teacher_class,
                t.subject AS teacher_subject
            FROM users u
            LEFT JOIN schools sc ON sc.id = u.school_id
            LEFT JOIN students st ON st.user_id = u.id
            LEFT JOIN teachers t ON t.user_id = u.id
            LEFT JOIN principals pr ON pr.user_id = u.id
            ORDER BY u.role, u.full_name
        ");
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        respond(true, 'All users fetched successfully.', $users);
        break;

    // ── 2. CREATE NEW USER (REGIONAL DELEGATE, DIVISIONAL DELEGATE, PRINCIPAL, TEACHER, STUDENT) ──
    case 'create_user':
        $fullName  = trim($body['full_name'] ?? '');
        $role      = trim($body['role'] ?? '');
        $matricule = trim($body['matricule'] ?? '');
        $gender    = trim($body['gender'] ?? 'M');
        $birthDate = trim($body['birth_date'] ?? '2008-01-01');
        $email     = trim($body['email'] ?? '');
        $phone     = trim($body['phone'] ?? '');
        $password  = '123456';
        $secCode   = '123456';
        $region    = trim($body['region'] ?? 'ADAMOUA');
        $division  = trim($body['division'] ?? 'DJEREM');
        $schoolId  = intval($body['school_id'] ?? 1);
        $className = trim($body['class_name'] ?? '1ère TI');
        $subject   = trim($body['subject'] ?? 'Informatique');

        if (empty($fullName) || empty($role) || empty($matricule)) {
            respondError('Full Name, Role, and Matricule are required.');
        }

        // Check if matricule already exists
        $stmtChk = $pdo->prepare("SELECT id FROM users WHERE matricule = ?");
        $stmtChk->execute([$matricule]);
        if ($stmtChk->fetch()) {
            respondError("Matricule '$matricule' already exists in system.");
        }

        $passHash = hash('sha256', $password);
        if (empty($email)) {
            $email = strtolower(str_replace(' ', '.', $fullName)) . '@minesec.cm';
        }

        // Insert into users table
        $stmtIns = $pdo->prepare("
            INSERT INTO users (full_name, matricule, email, phone, password_hash, security_code, role, is_activated, region, division, school_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?)
        ");
        $stmtIns->execute([$fullName, $matricule, $email, $phone, $passHash, $secCode, $role, $region, $division, $schoolId]);
        $newUserId = $pdo->lastInsertId();

        // Fetch school name for school-level roles
        $stmtSchool = $pdo->prepare("SELECT name FROM schools WHERE id = ?");
        $stmtSchool->execute([$schoolId]);
        $schoolRow = $stmtSchool->fetch(PDO::FETCH_ASSOC);
        $schoolName = $schoolRow['name'] ?? 'LYCEE BILINGUE DE NGAOUNDAL';

        // Insert role-specific details
        if ($role === 'student') {
            $stmtSt = $pdo->prepare("INSERT INTO students (user_id, full_name, mat_number, matricule, class_name, gender, birth_date, region, division, school_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmtSt->execute([$newUserId, $fullName, $matricule, $matricule, $className, $gender, $birthDate, $region, $division, $schoolName]);
        } else if ($role === 'teacher') {
            $stmtT = $pdo->prepare("INSERT INTO teachers (user_id, full_name, staff_id, matricule, subject, class_name, region, division, school_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmtT->execute([$newUserId, $fullName, $matricule, $matricule, $subject, $className, $region, $division, $schoolName]);
            
            $stmtTc = $pdo->prepare("INSERT IGNORE INTO teacher_classes (teacher_id, class_name) VALUES (?, ?)");
            $stmtTc->execute([$newUserId, $className]);
        } else if ($role === 'principal') {
            $stmtP = $pdo->prepare("INSERT INTO principals (user_id, full_name, staff_id, matricule, school_id, region, division, school_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
            $stmtP->execute([$newUserId, $fullName, $matricule, $matricule, $schoolId, $region, $division, $schoolName]);
        } else if ($role === 'divisional_delegate') {
            $stmtD = $pdo->prepare("INSERT INTO divisional_delegates (user_id, full_name, staff_id, matricule, delegation_name, region, division) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $stmtD->execute([$newUserId, $fullName, $matricule, $matricule, "DÉLÉGATION DÉPARTEMENTALE DU $division", $region, $division]);
        } else if ($role === 'regional_delegate') {
            $stmtR = $pdo->prepare("INSERT INTO regional_delegates (user_id, full_name, staff_id, matricule, delegation_name, region) VALUES (?, ?, ?, ?, ?, ?)");
            $stmtR->execute([$newUserId, $fullName, $matricule, $matricule, "DÉLÉGATION RÉGIONALE DE L'$region", $region]);
        }

        respond(true, "User '$fullName' created successfully as $role.", ['user_id' => $newUserId]);
        break;

    // ── 3. GET ALL SCHOOLS IN SYSTEM ─────────────────────────────
    case 'get_all_schools':
        $stmt = $pdo->query("SELECT id, name, region, division, town FROM schools ORDER BY region, division, name");
        $schools = $stmt->fetchAll(PDO::FETCH_ASSOC);
        respond(true, 'Schools fetched successfully.', $schools);
        break;

    // ── 4. CREATE NEW SCHOOL ─────────────────────────────────────
    case 'create_school':
        $name     = trim($body['name'] ?? '');
        $region   = trim($body['region'] ?? '');
        $division = trim($body['division'] ?? '');
        $town     = trim($body['town'] ?? '');

        if (empty($name) || empty($region) || empty($division)) {
            respondError('School Name, Region, and Division are required.');
        }

        $stmt = $pdo->prepare("INSERT INTO schools (name, region, division, town) VALUES (?, ?, ?, ?)");
        $stmt->execute([$name, $region, $division, $town]);
        $newSchoolId = $pdo->lastInsertId();

        respond(true, "School '$name' created successfully.", ['school_id' => $newSchoolId]);
        break;

    // ── 5. GET DETAILED CLASS DATA & RECOMMENDATIONS FOR SELECTED CLASS ──
    case 'get_class_details':
        $schoolName = trim($_GET['school_name'] ?? $body['school_name'] ?? '');
        $className  = trim($_GET['class_name'] ?? $body['class_name'] ?? '');

        if (empty($schoolName) || empty($className)) {
            respondError('School name and Class name are required.');
        }

        // Find school ID
        $stmtSc = $pdo->prepare("SELECT id, name, region, division FROM schools WHERE name = ?");
        $stmtSc->execute([$schoolName]);
        $school = $stmtSc->fetch(PDO::FETCH_ASSOC);

        $schoolId = $school['id'] ?? 1;

        // Fetch students in this class
        $stmtSt = $pdo->prepare("
            SELECT st.id AS student_id, st.mat_number, u.full_name, st.class_name, a.learning_style
            FROM students st
            JOIN users u ON u.id = st.user_id
            LEFT JOIN assessments a ON a.student_id = st.id
            WHERE u.school_id = ? AND st.class_name = ?
            ORDER BY u.full_name
        ");
        $stmtSt->execute([$schoolId, $className]);
        $students = $stmtSt->fetchAll(PDO::FETCH_ASSOC);

        $totalSt  = count($students);
        $assessed = 0;
        $visCount = 0;
        $audCount = 0;
        $kinCount = 0;
        $rwCount  = 0;

        foreach ($students as &$s) {
            $style = $s['learning_style'] ?? null;
            if ($style && $style !== 'Not Assessed') {
                $assessed++;
                if (stripos($style, 'Visual') !== false) $visCount++;
                if (stripos($style, 'Auditory') !== false) $audCount++;
                if (stripos($style, 'Kinesthetic') !== false) $kinCount++;
                if (stripos($style, 'Read') !== false) $rwCount++;
            } else {
                $s['learning_style'] = 'Not Assessed';
            }
        }

        $assessedRate = $totalSt > 0 ? round(($assessed / $totalSt) * 100) . '%' : '0%';

        // Generate VARK AI Policy Directives for Class
        $totalVarkClass = $visCount + $audCount + $kinCount + $rwCount;
        if ($totalVarkClass > 0) {
            $cStyles = [
                'Visual' => $visCount,
                'Auditory' => $audCount,
                'Kinesthetic' => $kinCount,
                'Read/Write' => $rwCount
            ];
            arsort($cStyles);
            $topStyle = key($cStyles);
            $topPct = round(($cStyles[$topStyle] / $totalVarkClass) * 100);

            $aiRecEn = "• Dominant VARK Profile for $className at $schoolName: $topStyle ($topPct% of diagnosed students).\n" .
                       "• Class Tactical Strategy: Integrate high-impact $topStyle learning aids, structured visual flowcharts, and interactive problem-solving exercises.\n" .
                       "• Teacher Action Plan: Differentiate homework assignments to support multimodal learners and provide regular progress monitoring.";

            $aiRecFr = "• Profil VARK Dominant pour la $className à $schoolName : $topStyle ($topPct% des élèves diagnostiqués).\n" .
                       "• Stratégie Tactique de Classe : Intégrez des supports pédagogiques $topStyle à fort impact, des schémas visuels structurés et des exercices interactifs.\n" .
                       "• Plan d'Action Enseignant : Différenciez les devoirs pour accompagner les apprenants multimodaux et assurez un suivi régulier.";
        } else {
            $aiRecEn = "• Class VARK Assessment for $className at $schoolName: Diagnostic evaluations pending. Administer the 16-item VARK questionnaire to generate AI pedagogical directives.";
            $aiRecFr = "• Évaluation VARK pour la $className à $schoolName : Évaluations diagnostiques en attente. Administrez le questionnaire VARK pour générer les directives pédagogiques IA.";
        }

        respond(true, 'Class details fetched successfully.', [
            'school_name' => $schoolName,
            'class_name' => $className,
            'region' => $school['region'] ?? 'ADAMOUA',
            'division' => $school['division'] ?? 'DJEREM',
            'total_students' => $totalSt,
            'assessed_students' => $assessed,
            'assessed_rate' => $assessedRate,
            'visual_count' => $visCount,
            'auditory_count' => $audCount,
            'kinesthetic_count' => $kinCount,
            'read_write_count' => $rwCount,
            'students' => $students,
            'ai_recommendation_en' => $aiRecEn,
            'ai_recommendation_fr' => $aiRecFr,
        ]);
        break;

    // ── 6. TOGGLE USER ACTIVATED/BLOCKED STATUS ──────────────────
    case 'toggle_user_status':
        $userId    = intval($body['user_id'] ?? $_GET['user_id'] ?? 0);
        $statusVal = intval($body['is_activated'] ?? $_GET['is_activated'] ?? 0);

        if ($userId <= 0) respondError('User ID is required.');

        $stmt = $pdo->prepare("UPDATE users SET is_activated = ? WHERE id = ?");
        $stmt->execute([$statusVal, $userId]);

        $statusMsg = $statusVal === 1 ? 'activated' : 'blocked';
        respond(true, "User status updated to $statusMsg.", ['user_id' => $userId, 'is_activated' => $statusVal]);
        break;

    // ── 7. DELETE USER ACCOUNT PERMANENTLY ───────────────────────
    case 'delete_user':
        $userId = intval($body['user_id'] ?? $_GET['user_id'] ?? 0);

        if ($userId <= 0) respondError('User ID is required.');

        // Delete from sub tables
        $pdo->prepare("DELETE FROM students WHERE user_id = ?")->execute([$userId]);
        $pdo->prepare("DELETE FROM teachers WHERE user_id = ?")->execute([$userId]);
        $pdo->prepare("DELETE FROM principals WHERE user_id = ?")->execute([$userId]);
        $pdo->prepare("DELETE FROM divisional_delegates WHERE user_id = ?")->execute([$userId]);
        $pdo->prepare("DELETE FROM regional_delegates WHERE user_id = ?")->execute([$userId]);

        // Delete from users table
        $stmt = $pdo->prepare("DELETE FROM users WHERE id = ?");
        $stmt->execute([$userId]);

        respond(true, "User account deleted successfully.", ['deleted_user_id' => $userId]);
        break;

    default:
        respondError("Unknown action '$action'.");
}
