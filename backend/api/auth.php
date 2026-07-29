<?php
// ============================================================
//  MINESEC LST — Auth API
//  POST /api/auth.php?action=check_matricule
//  POST /api/auth.php?action=activate
//  POST /api/auth.php?action=matricule_login
//  POST /api/auth.php?action=register
//  POST /api/auth.php?action=login
//  POST /api/auth.php?action=validate_code
// ============================================================

require_once __DIR__ . '/../config/helpers.php';
require_once __DIR__ . '/../config/database.php';

$action = $_GET['action'] ?? '';
$body   = getBody();

switch ($action) {

    // ── CHECK MATRICULE (Step 1 of Activation) ─────────────────
    case 'check_matricule':
        if (empty($body['matricule'])) respondError('Matricule is required.');

        $pdo       = getDB();
        $matricule = trim($body['matricule']);

        // Search in students table
        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role, u.is_activated, u.school_id, u.region, u.division,
                   s.class_name, s.mat_number, sc.name AS school_name
            FROM students s
            JOIN users u ON u.id = s.user_id
            LEFT JOIN schools sc ON sc.id = u.school_id
            WHERE s.mat_number = ?
        ");
        $stmt->execute([$matricule]);
        $user = $stmt->fetch();

        // Search in teachers table
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.school_id, u.region, u.division,
                       t.subject, t.staff_id, sc.name AS school_name
                FROM teachers t
                JOIN users u ON u.id = t.user_id
                LEFT JOIN schools sc ON sc.id = u.school_id
                WHERE t.staff_id = ?
            ");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        // Search by phone for delegates / admins
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.school_id, u.region, u.division,
                       sc.name AS school_name
                FROM users u
                LEFT JOIN schools sc ON sc.id = u.school_id
                WHERE u.phone = ?
            ");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        if (!$user) respondError('Matricule not found. Contact your administrator.', 404);

        if ($user['is_activated']) {
            respond(true, 'Account already activated. Please sign in.', [
                'already_activated' => true,
                'full_name' => $user['full_name'],
                'role'      => $user['role'],
            ]);
        }

        respond(true, 'Matricule found.', [
            'already_activated' => false,
            'user_id'     => $user['id'],
            'full_name'   => $user['full_name'],
            'role'        => $user['role'],
            'school_name' => $user['school_name'] ?? null,
            'region'      => $user['region'] ?? null,
            'division'    => $user['division'] ?? null,
            'class_name'  => $user['class_name'] ?? null,
            'subject'     => $user['subject'] ?? null,
        ]);
        break;

    // ── ACTIVATE ACCOUNT (Set password + security code) ────────
    case 'activate':
        $required = ['matricule', 'password', 'security_code'];
        foreach ($required as $f) {
            if (empty($body[$f])) respondError("Field '$f' is required.");
        }

        $pdo       = getDB();
        $matricule = trim($body['matricule']);

        // Resolve user_id from matricule
        $userId = null;
        $row    = null;

        $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM students s JOIN users u ON u.id = s.user_id WHERE s.mat_number = ?");
        $stmt->execute([$matricule]);
        $row = $stmt->fetch();
        if ($row) $userId = $row['id'];

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM teachers t JOIN users u ON u.id = t.user_id WHERE t.staff_id = ?");
            $stmt->execute([$matricule]);
            $row = $stmt->fetch();
            if ($row) $userId = $row['id'];
        }

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT id, is_activated FROM users WHERE phone = ?");
            $stmt->execute([$matricule]);
            $row = $stmt->fetch();
            if ($row) $userId = $row['id'];
        }

        if (!$userId) respondError('Matricule not found.', 404);
        if ($row['is_activated']) respondError('Account already activated. Please sign in.', 409);
        if (strlen($body['password']) < 6) respondError('Password must be at least 6 characters.');
        if (strlen($body['security_code']) < 4) respondError('Security code must be at least 4 characters.');

        $passwordHash = hash('sha256', $body['password']);
        $securityHash = hash('sha256', $body['security_code']);

        $pdo->prepare("UPDATE users SET password_hash = ?, security_code = ?, is_activated = 1, activated_at = NOW() WHERE id = ?")
            ->execute([$passwordHash, $securityHash, $userId]);
        $pdo->prepare("UPDATE students SET password_hash = ?, security_code = ? WHERE user_id = ?")
            ->execute([$passwordHash, $securityHash, $userId]);

        $stmt = $pdo->prepare("SELECT id, full_name, role, school_id, region, division FROM users WHERE id = ?");
        $stmt->execute([$userId]);
        $user = $stmt->fetch();

        $token = hash('sha256', $userId . time() . 'MINESEC_SECRET_2025');

        respond(true, 'Account activated successfully.', [
            'token'     => $token,
            'user_id'   => $user['id'],
            'full_name' => $user['full_name'],
            'role'      => $user['role'],
            'school_id' => $user['school_id'],
            'region'    => $user['region'],
            'division'  => $user['division'],
        ], 201);
        break;

    // ── MATRICULE LOGIN ─────────────────────────────────────────
    case 'matricule_login':
        $required = ['matricule', 'password', 'security_code'];
        foreach ($required as $f) {
            if (empty($body[$f])) respondError("Field '$f' is required.");
        }

        $pdo          = getDB();
        $matricule    = trim($body['matricule']);
        $passwordHash = hash('sha256', $body['password']);
        $securityHash = hash('sha256', $body['security_code']);

        $user = null;

        $stmt = $pdo->prepare("SELECT u.* FROM students s JOIN users u ON u.id = s.user_id WHERE s.mat_number = ?");
        $stmt->execute([$matricule]);
        $user = $stmt->fetch();

        if (!$user) {
            $stmt = $pdo->prepare("SELECT u.* FROM teachers t JOIN users u ON u.id = t.user_id WHERE t.staff_id = ?");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        if (!$user) {
            $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ?");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        if (!$user)                                    respondError('Matricule not found.', 404);
        if (!$user['is_active'])                       respondError('Account is disabled. Contact administrator.', 403);
        if (!$user['is_activated'])                    respondError('Account not activated. Please activate first.', 403);
        if ($user['password_hash'] !== $passwordHash)  respondError('Incorrect password.', 401);
        if ($user['security_code']  !== $securityHash) respondError('Incorrect security code.', 401);

        $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = ?")->execute([$user['id']]);

        $token = hash('sha256', $user['id'] . time() . 'MINESEC_SECRET_2025');

        respond(true, 'Login successful.', [
            'token'     => $token,
            'user_id'   => $user['id'],
            'full_name' => $user['full_name'],
            'role'      => $user['role'],
            'school_id' => $user['school_id'],
            'region'    => $user['region'],
            'division'  => $user['division'],
        ]);
        break;

    // ── REGISTER ──────────────────────────────────────────────
    case 'register':
        $required = ['full_name', 'email', 'password', 'role', 'activation_code'];
        foreach ($required as $field) {
            if (empty($body[$field])) respondError("Field '$field' is required.");
        }

        $pdo  = getDB();
        $code = trim($body['activation_code']);

        $stmt = $pdo->prepare("SELECT * FROM activation_codes WHERE code = ? AND used_by IS NULL");
        $stmt->execute([$code]);
        $codeRow = $stmt->fetch();

        if (!$codeRow) respondError('Invalid or already used activation code.', 403);
        if ($codeRow['role'] !== $body['role']) respondError('Activation code does not match selected role.', 403);
        if ($codeRow['expires_at'] && strtotime($codeRow['expires_at']) < time()) respondError('Activation code has expired.', 403);

        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$body['email']]);
        if ($stmt->fetch()) respondError('Email already registered.', 409);

        $hash = hash('sha256', $body['password']);
        $stmt = $pdo->prepare("
            INSERT INTO users (full_name, email, password_hash, role, phone, school_id, activation_code, is_activated)
            VALUES (?, ?, ?, ?, ?, ?, ?, 1)
        ");
        $stmt->execute([
            $body['full_name'], $body['email'], $hash, $body['role'],
            $body['phone'] ?? null, $codeRow['school_id'] ?? null, $code,
        ]);
        $userId = $pdo->lastInsertId();

        $pdo->prepare("UPDATE activation_codes SET used_by = ?, used_at = NOW() WHERE code = ?")
            ->execute([$userId, $code]);

        if ($body['role'] === 'student') {
            $pdo->prepare("INSERT INTO students (user_id, class_name, mat_number, gender) VALUES (?, ?, ?, ?)")
                ->execute([$userId, $body['class_name'] ?? 'Unknown', $body['mat_number'] ?? null, $body['gender'] ?? null]);
        } elseif ($body['role'] === 'teacher') {
            $pdo->prepare("INSERT INTO teachers (user_id, staff_id, subject) VALUES (?, ?, ?)")
                ->execute([$userId, $body['staff_id'] ?? null, $body['subject'] ?? null]);
        }

        respond(true, 'Account created successfully.', ['user_id' => $userId], 201);
        break;

    // ── LOGIN (email + password — legacy) ─────────────────────
    case 'login':
        if (empty($body['email']) || empty($body['password'])) respondError('Email and password are required.');

        $pdo  = getDB();
        $hash = hash('sha256', $body['password']);

        $stmt = $pdo->prepare("SELECT id, full_name, email, role, is_activated, is_active, school_id, region, division FROM users WHERE email = ? AND password_hash = ?");
        $stmt->execute([$body['email'], $hash]);
        $user = $stmt->fetch();

        if (!$user)              respondError('Invalid email or password.', 401);
        if (!$user['is_active']) respondError('Account is disabled.', 403);
        if (!$user['is_activated']) respondError('Account not yet activated.', 403);

        $pdo->prepare("UPDATE users SET last_login = NOW() WHERE id = ?")->execute([$user['id']]);
        $token = hash('sha256', $user['id'] . time() . 'MINESEC_SECRET_2025');

        respond(true, 'Login successful.', [
            'token'     => $token,
            'user_id'   => $user['id'],
            'full_name' => $user['full_name'],
            'role'      => $user['role'],
            'school_id' => $user['school_id'],
        ]);
        break;

    // ── VALIDATE ACTIVATION CODE ──────────────────────────────
    case 'validate_code':
        if (empty($body['code'])) respondError('Activation code is required.');

        $pdo  = getDB();
        $stmt = $pdo->prepare("SELECT role, school_id, expires_at, used_by FROM activation_codes WHERE code = ?");
        $stmt->execute([trim($body['code'])]);
        $row = $stmt->fetch();

        if (!$row)          respondError('Invalid activation code.', 404);
        if ($row['used_by']) respondError('Activation code already used.', 409);
        if ($row['expires_at'] && strtotime($row['expires_at']) < time()) respondError('Activation code has expired.', 410);

        respond(true, 'Code is valid.', ['role' => $row['role'], 'school_id' => $row['school_id']]);
        break;

    // ── UPDATE PROFILE ──────────────────────────────────────────
    case 'update_profile':
        $userId = intval($body['user_id'] ?? 0);
        if ($userId <= 0) respondError('user_id is required.');

        $pdo = getDB();

        $updates    = [];
        $params     = [];
        $stuUpdates = [];
        $stuParams  = [];

        if (!empty($body['full_name'])) {
            $nameVal = trim($body['full_name']);
            $updates[]    = "full_name = ?";
            $params[]     = $nameVal;
            $stuUpdates[] = "full_name = ?";
            $stuParams[]  = $nameVal;
        }
        if (!empty($body['division'])) {
            $divVal = trim($body['division']);
            $updates[]    = "division = ?";
            $params[]     = $divVal;
            $stuUpdates[] = "division = ?";
            $stuParams[]  = $divVal;
        }
        if (!empty($body['region'])) {
            $regVal = trim($body['region']);
            $updates[]    = "region = ?";
            $params[]     = $regVal;
        }
        if (!empty($body['password'])) {
            if (strlen($body['password']) < 6) respondError('Password must be at least 6 characters.');
            $pHash = hash('sha256', $body['password']);
            $updates[]    = "password_hash = ?";
            $params[]     = $pHash;
            $stuUpdates[] = "password_hash = ?";
            $stuParams[]  = $pHash;
        }
        if (!empty($body['security_code'])) {
            if (strlen($body['security_code']) < 4) respondError('Security code must be at least 4 characters.');
            $sHash = hash('sha256', $body['security_code']);
            $updates[]    = "security_code = ?";
            $params[]     = $sHash;
            $stuUpdates[] = "security_code = ?";
            $stuParams[]  = $sHash;
        }

        if (!empty($updates)) {
            $params[] = $userId;
            $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?";
            $pdo->prepare($sql)->execute($params);
        }

        if (isset($body['class_name'])) {
            $stuUpdates[] = "class_name = ?";
            $stuParams[]  = trim($body['class_name']);
        }
        if (isset($body['birth_date'])) {
            $stuUpdates[] = "birth_date = ?";
            $stuParams[]  = trim($body['birth_date']);
        }

        if (!empty($stuUpdates)) {
            $stuParams[] = $userId;
            $sqlStu = "UPDATE students SET " . implode(', ', $stuUpdates) . " WHERE user_id = ?";
            $pdo->prepare($sqlStu)->execute($stuParams);
        }

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role, u.school_id, u.region, u.division,
                   s.name as school_name, st.class_name, st.mat_number, st.birth_date, st.gender
            FROM users u
            LEFT JOIN schools s ON s.id = u.school_id
            LEFT JOIN students st ON st.user_id = u.id
            WHERE u.id = ?
        ");
        $stmt->execute([$userId]);
        $profile = $stmt->fetch();

        respond(true, 'Profile updated successfully.', $profile);
        break;

    // ── GET PROFILE ─────────────────────────────────────────────
    case 'get_profile':
        $userId = intval($_GET['user_id'] ?? 0);
        if ($userId <= 0) respondError('user_id is required.');

        $pdo = getDB();
        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role, u.school_id, u.region, u.division,
                   s.name as school_name, st.class_name, st.mat_number, st.birth_date, st.gender,
                   t.staff_id, t.subject, t.class_name as teacher_class
            FROM users u
            LEFT JOIN schools s ON s.id = u.school_id
            LEFT JOIN students st ON st.user_id = u.id
            LEFT JOIN teachers t ON t.user_id = u.id
            WHERE u.id = ?
        ");
        $stmt->execute([$userId]);
        $profile = $stmt->fetch();

        if (!$profile) respondError('Profile not found.', 404);
        respond(true, 'Profile fetched successfully.', $profile);
        break;

    default:
        respondError('Unknown action.', 404);
}
