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
require_once __DIR__ . '/../services/vark_academic_engine.php';

$action = $_GET['action'] ?? '';
$body   = getBody();
$pdo    = getDB();

switch ($action) {

    // ── 1. GET ALL USERS IN SYSTEM (Or filtered by school_id) ────
    case 'get_all_users':
        $schoolIdParam = intval($_GET['school_id'] ?? 0);
        $whereClause = "";
        $params = [];

        if ($schoolIdParam > 0) {
            $whereClause = "WHERE u.school_id = ?";
            $params = [$schoolIdParam];
        }

        $stmt = $pdo->prepare("
            SELECT 
                u.id,
                u.full_name,
                COALESCE(NULLIF(u.matricule, ''), st.matricule, st.mat_number, t.matricule, t.staff_id, pr.matricule, pr.staff_id, 'N/A') AS matricule,
                u.email,
                u.role,
                COALESCE(u.is_activated, 1) AS is_activated,
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
                st.gender AS student_gender,
                st.birth_date AS student_birth_date,
                t.class_name AS teacher_class,
                t.subject AS teacher_subject
            FROM users u
            LEFT JOIN schools sc ON sc.id = u.school_id
            LEFT JOIN students st ON st.user_id = u.id
            LEFT JOIN teachers t ON t.user_id = u.id
            LEFT JOIN principals pr ON pr.user_id = u.id
            $whereClause
            ORDER BY u.role, u.full_name
        ");
        $stmt->execute($params);
        $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

        respond(true, 'Users fetched successfully.', $users);
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

        if (empty($fullName) || empty($role)) {
            respondError('Full Name and Role are required.');
        }

        // Auto-generate matricule if empty
        if (empty($matricule)) {
            $matricule = 'STU' . date('Y') . sprintf('%04d', rand(1000, 9999));
        }

        // Check if matricule already exists
        $stmtChk = $pdo->prepare("SELECT id FROM users WHERE matricule = ?");
        $stmtChk->execute([$matricule]);
        if ($stmtChk->fetch()) {
            // Append random suffix if exists
            $matricule .= rand(10, 99);
        }

        $passHash = hash('sha256', $password);
        if (empty($email)) {
            $email = strtolower(str_replace(' ', '.', $fullName)) . '@minesec.cm';
        }

        // Insert into users table (UNACTIVATED by default, no pre-set password or security code)
        $stmtIns = $pdo->prepare("
            INSERT INTO users (full_name, matricule, email, phone, password_hash, security_code, role, is_activated, region, division, school_id)
            VALUES (?, ?, ?, NULL, NULL, NULL, ?, 0, ?, ?, ?)
        ");
        $stmtIns->execute([$fullName, $matricule, $email, $role, $region, $division, $schoolId]);
        $newUserId = $pdo->lastInsertId();

        // Fetch school name for school-level roles based on schoolId
        $stmtSchool = $pdo->prepare("SELECT name, region, division FROM schools WHERE id = ?");
        $stmtSchool->execute([$schoolId]);
        $schoolRow = $stmtSchool->fetch(PDO::FETCH_ASSOC);
        if ($schoolRow) {
            $schoolName = $schoolRow['name'];
            if (empty($region)) $region = $schoolRow['region'];
            if (empty($division)) $division = $schoolRow['division'];
        } else {
            $schoolName = trim($body['school_name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL');
        }

        // Insert role-specific details
        if ($role === 'student') {
            $stmtSt = $pdo->prepare("INSERT INTO students (user_id, full_name, mat_number, matricule, class_name, gender, birth_date, region, division, school_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmtSt->execute([$newUserId, $fullName, $matricule, $matricule, $className, $gender, $birthDate, $region, $division, $schoolName]);
        } else if ($role === 'teacher') {
            $stmtT = $pdo->prepare("INSERT INTO teachers (user_id, full_name, staff_id, matricule, subject, class_name, region, division, school_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
            $stmtT->execute([$newUserId, $fullName, $matricule, $matricule, $subject, $className, $region, $division, $schoolName]);
            
            $stmtTc = $pdo->prepare("INSERT IGNORE INTO teacher_classes (teacher_id, class_name) VALUES (?, ?)");
            $stmtTc->execute([$newUserId, $className]);
        } else if ($role === 'dean_of_studies' || $role === 'dean') {
            try {
                $stmtDean = $pdo->prepare("INSERT INTO dean_of_studies (user_id, full_name, staff_id, matricule, school_id, region, division, school_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                $stmtDean->execute([$newUserId, $fullName, $matricule, $matricule, $schoolId, $region, $division, $schoolName]);
            } catch (Exception $e) {}
            // Dean of Studies can also be a class teacher
            if (!empty($className)) {
                try {
                    $stmtT = $pdo->prepare("INSERT INTO teachers (user_id, full_name, staff_id, matricule, subject, class_name, region, division, school_name) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
                    $stmtT->execute([$newUserId, $fullName, $matricule, $matricule, $subject, $className, $region, $division, $schoolName]);
                    $stmtTc = $pdo->prepare("INSERT IGNORE INTO teacher_classes (teacher_id, class_name) VALUES (?, ?)");
                    $stmtTc->execute([$newUserId, $className]);
                } catch (Exception $e) {}
            }
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
        $stmt = $pdo->query("SELECT id, name, region, division, town, COALESCE(is_active, 1) AS is_active FROM schools ORDER BY region, division, name");
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

        // Fetch students in this class (LATEST attempt per unique student)
        $stmtSt = $pdo->prepare("
            SELECT st.id AS student_id, st.mat_number, u.full_name, st.class_name,
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
        if ($totalVarkClass > 0) {
            $dominant = 'Auditory';
            $maxVal = $audCount;
            if ($visCount > $maxVal) { $maxVal = $visCount; $dominant = 'Visual'; }
            if ($kinCount > $maxVal) { $maxVal = $kinCount; $dominant = 'Kinesthetic'; }
            if ($rwCount > $maxVal)  { $maxVal = $rwCount;  $dominant = 'Read/Write'; }

            $pct = round(($maxVal / $totalVarkClass) * 100);

            $recsEn = [];
            $recsFr = [];

            if ($dominant == 'Auditory') {
                $recsEn[] = "• Auditory Learners (Majority — {$pct}%): Prioritize interactive classroom discussions, verbal lecture summaries, peer debates, and audio-assisted learning toolkits across the class.";
                $recsFr[] = "• Apprenants Auditifs (Majorité — {$pct}%) : Privilégiez les discussions interactives en classe, les résumés de cours oraux, les débats et les outils audio.";
                $recsEn[] = "• Visual Learners Support: Include color-coded board diagrams, visual mind maps, and key summary slides so visual students can follow along effectively.";
                $recsFr[] = "• Soutien aux Apprenants Visuels : Intégrez des schémas visuels en couleurs au tableau, des cartes mentales et des diaporamas résumés.";
                $recsEn[] = "• Kinesthetic Learners Support: Incorporate hands-on problem-solving exercises, lab demonstrations, and interactive group activities for practical learners.";
                $recsFr[] = "• Soutien aux Apprenants Kinesthésiques : Proposez des exercices pratiques de résolution de problèmes et démonstrations en groupe.";
                $recsEn[] = "• Read/Write Learners Support: Provide structured written handouts, key term glossaries, and bulleted note-taking frameworks for text-focused students.";
                $recsFr[] = "• Soutien aux Apprenants Lecture/Écriture : Fournissez des fiches de cours imprimées structurées, des glossaires et guides de prise de notes.";
            } elseif ($dominant == 'Visual') {
                $recsEn[] = "• Visual Learners (Majority — {$pct}%): Utilize color-coded visual charts, mind maps, graphic organizers, and video demonstrations to boost comprehension.";
                $recsFr[] = "• Apprenants Visuels (Majorité — {$pct}%) : Utilisez des schémas visuels en couleurs, des cartes mentales, des organisateurs graphiques et démonstrations vidéo.";
                $recsEn[] = "• Auditory Learners Support: Facilitate verbal lecture summaries, class Q&A sessions, and interactive group discussions for auditory students.";
                $recsFr[] = "• Soutien aux Apprenants Auditifs : Facilitez les synthèses de cours orales, les séances de Q/R et les discussions de groupe.";
                $recsEn[] = "• Kinesthetic Learners Support: Incorporate hands-on practical exercises, lab demonstrations, and active learning tasks for practical learners.";
                $recsFr[] = "• Soutien aux Apprenants Kinesthésiques : Intégrez des exercices pratiques interactifs et des travaux de groupe.";
                $recsEn[] = "• Read/Write Learners Support: Provide structured reading materials, written glossaries, and bulleted note-taking frameworks for text-focused students.";
                $recsFr[] = "• Soutien aux Apprenants Lecture/Écriture : Fournissez des manuels structurés, des glossaires et des fiches de synthèse.";
            } elseif ($dominant == 'Kinesthetic') {
                $recsEn[] = "• Kinesthetic Learners (Majority — {$pct}%): Structure lessons around hands-on laboratory experiments, interactive coding, and practical exercises.";
                $recsFr[] = "• Apprenants Kinesthésiques (Majorité — {$pct}%) : Structurez les cours autour de travaux pratiques en laboratoire, du codage et d'exercices pratiques.";
                $recsEn[] = "• Auditory Learners Support: Provide clear verbal explanations, oral instructions, and interactive class Q&A for auditory students.";
                $recsFr[] = "• Soutien aux Apprenants Auditifs : Proposez des explications orales claires, des instructions verbales et des échanges oraux.";
                $recsEn[] = "• Visual Learners Support: Supply visual step-by-step procedure diagrams and flowcharts for visual students.";
                $recsFr[] = "• Soutien aux Apprenants Visuels : Fournissez des schémas de procédure étape par étape et des organigrammes.";
                $recsEn[] = "• Read/Write Learners Support: Provide written lab manuals and practical exercise worksheets for text-focused students.";
                $recsFr[] = "• Soutien aux Apprenants Lecture/Écriture : Mettez à disposition des manuels de travaux pratiques et des fiches d'exercices.";
            } else {
                $recsEn[] = "• Read/Write Learners (Majority — {$pct}%): Provide structured printed handouts, comprehensive reading glossaries, and detailed note-taking frameworks.";
                $recsFr[] = "• Apprenants Lecture/Écriture (Majorité — {$pct}%) : Fournissez des fiches de cours imprimées, des glossaires détaillés et des guides de prise de notes.";
                $recsEn[] = "• Auditory Learners Support: Conduct verbal class discussions and oral summaries of key concepts for auditory students.";
                $recsFr[] = "• Soutien aux Apprenants Auditifs : Animez des discussions de classe orales et des synthèses verbale des notions clés.";
                $recsEn[] = "• Visual Learners Support: Use visual summary charts and key diagrammatic models for visual students.";
                $recsFr[] = "• Soutien aux Apprenants Visuels : Utilisez des schémas de synthèse visuels et des modèles schématiques.";
                $recsEn[] = "• Kinesthetic Learners Support: Assign interactive practice exercises and written problem sets for practical learners.";
                $recsFr[] = "• Soutien aux Apprenants Kinesthésiques : Proposez des exercices pratiques interactifs et des séries de problèmes.";
            }

            $aiRecEn = implode("\n", $recsEn);
            $aiRecFr = implode("\n", $recsFr);
        } else {
            $aiRecEn = "• Multimodal Teaching Strategy (Diagnostic Phase): Diagnostic VARK assessments are in progress. Encourage all learning styles equally through multimodal instruction.\n" .
                       "• Auditory Recommendation: Integrate interactive class discussions, verbal lecture summaries, audio recordings, and peer Q&A sessions.\n" .
                       "• Visual Recommendation: Utilize color-coded visual board diagrams, mind maps, graphic organizers, and video demonstrations.\n" .
                       "• Kinesthetic Recommendation: Incorporate hands-on problem-solving exercises, practical lab demonstrations, and interactive group activities.\n" .
                       "• Read/Write Recommendation: Supply structured printed handouts, comprehensive reading glossaries, and bulleted note-taking frameworks.";

            $aiRecFr = "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Les évaluations VARK sont en cours. Encouragez équitablement tous les styles d'apprentissage.\n" .
                       "• Recommandation Auditive : Intégrez des discussions interactives en classe, des synthèses orales de cours et des enregistrements audio.\n" .
                       "• Recommandation Visuelle : Utilisez des schémas visuels en couleurs, des cartes mentales et des diaporamas résumés.\n" .
                       "• Recommandation Kinesthésique : Proposez des exercices pratiques de résolution de problèmes et des travaux en groupe.\n" .
                       "• Recommandation Lecture/Écriture : Fournissez des fiches de cours imprimées structurées et des glossaires détaillés.";
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

    // ── 5B. GET DETAILED SCHOOL DATA & RECOMMENDATIONS FOR SELECTED SCHOOL ──
    case 'get_school_details':
        $schoolName = trim($_GET['school_name'] ?? $body['school_name'] ?? '');

        if (empty($schoolName)) {
            $stmtFirst = $pdo->query("SELECT name FROM schools ORDER BY id ASC LIMIT 1");
            $firstRow = $stmtFirst->fetch(PDO::FETCH_ASSOC);
            $schoolName = $firstRow['name'] ?? 'LYCEE TECHNIQUE DE NGAOUNDAL';
        }

        // Find school ID
        $stmtSc = $pdo->prepare("SELECT id, name, region, division, town FROM schools WHERE name = ?");
        $stmtSc->execute([$schoolName]);
        $school = $stmtSc->fetch(PDO::FETCH_ASSOC);
        $schoolId = $school['id'] ?? 1;

        // Fetch total classes in this school
        $stmtCls = $pdo->prepare("SELECT DISTINCT class_name FROM students WHERE user_id IN (SELECT id FROM users WHERE school_id = ?)");
        $stmtCls->execute([$schoolId]);
        $classesList = $stmtCls->fetchAll(PDO::FETCH_COLUMN);
        $classesCount = count($classesList);
        if ($classesCount == 0) $classesCount = 2;

        // Fetch teachers count
        $stmtT = $pdo->prepare("SELECT COUNT(*) FROM teachers t JOIN users u ON u.id = t.user_id WHERE u.school_id = ?");
        $stmtT->execute([$schoolId]);
        $teachersCount = (int)$stmtT->fetchColumn();

        // Fetch students in this school
        $stmtSt = $pdo->prepare("
            SELECT st.id AS student_id,
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
        ");
        $stmtSt->execute([$schoolId]);
        $students = $stmtSt->fetchAll(PDO::FETCH_ASSOC);

        $totalSt  = count($students);
        $assessed = 0;
        $visCount = 0;
        $audCount = 0;
        $kinCount = 0;
        $rwCount  = 0;

        foreach ($students as $s) {
            $style = $s['learning_style'] ?? null;
            if ($style && $style !== 'Not Assessed') {
                $assessed++;
                if (stripos($style, 'Visual') !== false) $visCount++;
                if (stripos($style, 'Auditory') !== false) $audCount++;
                if (stripos($style, 'Kinesthetic') !== false) $kinCount++;
                if (stripos($style, 'Read') !== false) $rwCount++;
            }
        }

        $assessedRate = $totalSt > 0 ? round(($assessed / $totalSt) * 100) . '%' : '0%';

        if ($assessed > 0) {
            $eval = VarkAcademicEngine::evaluate($audCount, $visCount, $kinCount, $rwCount);
            $aiRecEn = "• Institutional Academic Diagnosis ({$schoolName}): Dominant profile is {$eval['learning_style']} ({$eval['primary_category_name_en']}).\n" .
                       "• Academic Prospects: {$eval['prospects_summary_en']}\n\n" .
                       $eval['learning_strategy_en'];

            $aiRecFr = "• Diagnostic Pédagogique Institutionnel ({$schoolName}) : Profil dominant {$eval['learning_style']} ({$eval['primary_category_name_fr']}).\n" .
                       "• Perspectives Académiques : {$eval['prospects_summary_fr']}\n\n" .
                       $eval['learning_strategy_fr'];
        } else {
            $aiRecEn = "• Multimodal Diagnostic Phase: Diagnostic VARK assessments are in progress for {$schoolName}. Encourage all learning styles equally through multimodal instruction.\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.";
            $aiRecFr = "• Phase Diagnostique Multimodale : Les évaluations diagnostiques VARK sont en cours pour {$schoolName}. Encouragez équitablement tous les styles d'apprentissage.\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.";
        }

        respond(true, 'School details fetched successfully.', [
            'school_name' => $schoolName,
            'region' => $school['region'] ?? 'ADAMOUA',
            'division' => $school['division'] ?? 'DJEREM',
            'total_students' => $totalSt,
            'total_classes' => $classesCount,
            'total_teachers' => $teachersCount,
            'assessed_students' => $assessed,
            'assessed_rate' => $assessedRate,
            'visual_count' => $visCount,
            'auditory_count' => $audCount,
            'kinesthetic_count' => $kinCount,
            'read_write_count' => $rwCount,
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

        // Delete safely from sub tables
        $subTables = ['students', 'teachers', 'principals', 'dean_of_studies', 'regional_delegates', 'admins'];
        foreach ($subTables as $tbl) {
            try {
                $pdo->prepare("DELETE FROM $tbl WHERE user_id = ?")->execute([$userId]);
            } catch (Exception $ex) {
                // Ignore missing subtable or foreign constraint warnings
            }
        }

        // Delete from main users table
        $stmt = $pdo->prepare("DELETE FROM users WHERE id = ?");
        $stmt->execute([$userId]);

        respond(true, "User account deleted successfully.", ['deleted_user_id' => $userId]);
        break;

    // ── 8. UPDATE STUDENT DETAILS ───────────────────────────────
    case 'update_student':
        $userId    = intval($body['user_id'] ?? $_GET['user_id'] ?? 0);
        $fullName  = trim($body['full_name'] ?? '');
        $matricule = trim($body['matricule'] ?? '');
        $className = trim($body['class_name'] ?? '');
        $gender    = trim($body['gender'] ?? 'M');
        $birthDate = trim($body['birth_date'] ?? '2008-01-01');

        if ($userId <= 0 || empty($fullName)) respondError('User ID and Full Name are required.');

        // Update users table
        $stmtU = $pdo->prepare("UPDATE users SET full_name = ?, matricule = ? WHERE id = ?");
        $stmtU->execute([$fullName, $matricule, $userId]);

        // Update students table
        $stmtS = $pdo->prepare("UPDATE students SET full_name = ?, matricule = ?, mat_number = ?, class_name = ?, gender = ?, birth_date = ? WHERE user_id = ?");
        $stmtS->execute([$fullName, $matricule, $matricule, $className, $gender, $birthDate, $userId]);

        respond(true, "Student '$fullName' updated successfully.", ['user_id' => $userId]);
        break;

    // ── 9. ADD SCHOOL ──────────────────────────────────────────
    case 'add_school':
        $schoolName = trim($body['name'] ?? $body['school_name'] ?? '');
        $region     = trim($body['region'] ?? 'ADAMOUA');
        $division   = trim($body['division'] ?? 'DJEREM');
        $town       = trim($body['town'] ?? '');
        $code       = trim($body['code'] ?? 'SCH' . str_pad(rand(10, 999), 3, '0', STR_PAD_LEFT));

        if (empty($schoolName)) respondError('School name is required.');

        // Check duplicate
        $stmtCheck = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
        $stmtCheck->execute([$schoolName]);
        if ($stmtCheck->fetch()) {
            respondError("A school with the name '$schoolName' already exists.");
        }

        $stmt = $pdo->prepare("INSERT INTO schools (code, name, region, division, town, is_active, created_at) VALUES (?, ?, ?, ?, ?, 1, NOW())");
        $stmt->execute([$code, $schoolName, $region, $division, $town]);
        $newId = $pdo->lastInsertId();

        respond(true, "School '$schoolName' registered successfully.", [
            'id' => $newId,
            'name' => $schoolName,
            'region' => $region,
            'division' => $division,
            'town' => $town,
            'is_active' => 1
        ]);
        break;

    // ── 10. UPDATE / MODIFY SCHOOL ──────────────────────────────
    case 'update_school':
    case 'edit_school':
        $schoolId   = intval($body['id'] ?? $body['school_id'] ?? 0);
        $schoolName = trim($body['name'] ?? $body['school_name'] ?? '');
        $region     = trim($body['region'] ?? 'ADAMOUA');
        $division   = trim($body['division'] ?? 'DJEREM');
        $town       = trim($body['town'] ?? '');

        if ($schoolId <= 0 && !empty($schoolName)) {
            // Find by name if id not sent
            $stmtFind = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
            $stmtFind->execute([$schoolName]);
            $schoolId = intval($stmtFind->fetchColumn());
        }

        if ($schoolId <= 0 || empty($schoolName)) {
            respondError('Valid School ID and School Name are required.');
        }

        // Get old name for cascading user/student/teacher records
        $stmtOld = $pdo->prepare("SELECT name FROM schools WHERE id = ?");
        $stmtOld->execute([$schoolId]);
        $oldSchoolName = $stmtOld->fetchColumn();

        $stmt = $pdo->prepare("UPDATE schools SET name = ?, region = ?, division = ?, town = ? WHERE id = ?");
        $stmt->execute([$schoolName, $region, $division, $town, $schoolId]);

        // Cascade school name update to users and sub-tables
        if ($oldSchoolName && $oldSchoolName !== $schoolName) {
            $pdo->prepare("UPDATE users SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE students SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE teachers SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE principals SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
            $pdo->prepare("UPDATE dean_of_studies SET school_name = ? WHERE school_name = ?")->execute([$schoolName, $oldSchoolName]);
        }

        respond(true, "School '$schoolName' updated successfully.", [
            'id' => $schoolId,
            'name' => $schoolName,
            'region' => $region,
            'division' => $division,
            'town' => $town
        ]);
        break;

    // ── 11. DELETE SCHOOL ───────────────────────────────────────
    case 'delete_school':
        $schoolId   = intval($body['id'] ?? $body['school_id'] ?? $_GET['id'] ?? 0);
        $schoolName = trim($body['name'] ?? $body['school_name'] ?? $_GET['school_name'] ?? '');

        if ($schoolId <= 0 && !empty($schoolName)) {
            $stmtFind = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
            $stmtFind->execute([$schoolName]);
            $schoolId = intval($stmtFind->fetchColumn());
        }

        if ($schoolId <= 0) {
            respondError('School ID or School Name is required.');
        }

        $stmt = $pdo->prepare("DELETE FROM schools WHERE id = ?");
        $stmt->execute([$schoolId]);

        respond(true, "School deleted successfully from directory.", ['deleted_id' => $schoolId]);
        break;

    // ── 12. TOGGLE SCHOOL STATUS (BLOCK / UNBLOCK) ──────────────
    case 'toggle_school_status':
        $schoolId  = intval($body['id'] ?? $body['school_id'] ?? $_GET['id'] ?? 0);
        $statusVal = intval($body['is_active'] ?? $_GET['is_active'] ?? 1);
        $schoolName= trim($body['name'] ?? $body['school_name'] ?? '');

        if ($schoolId <= 0 && !empty($schoolName)) {
            $stmtFind = $pdo->prepare("SELECT id FROM schools WHERE LOWER(name) = LOWER(?)");
            $stmtFind->execute([$schoolName]);
            $schoolId = intval($stmtFind->fetchColumn());
        }

        if ($schoolId <= 0) respondError('School ID is required.');

        $stmt = $pdo->prepare("UPDATE schools SET is_active = ? WHERE id = ?");
        $stmt->execute([$statusVal, $schoolId]);

        $statusMsg = $statusVal === 1 ? 'activated/unblocked' : 'blocked/suspended';
        respond(true, "School status updated to $statusMsg.", ['id' => $schoolId, 'is_active' => $statusVal]);
        break;

    default:
        respondError("Unknown action '$action'.");
}
