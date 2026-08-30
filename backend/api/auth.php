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

        // 1. Direct search in users table
        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                   u.matricule, sc.name AS school_name
            FROM users u
            LEFT JOIN schools sc ON sc.id = u.school_id
            WHERE u.matricule = ?
        ");
        $stmt->execute([$matricule]);
        $user = $stmt->fetch();

        // 2. Fallback search in students table
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                       s.class_name, s.matricule, sc.name AS school_name
                FROM students s
                JOIN users u ON u.id = s.user_id
                LEFT JOIN schools sc ON sc.id = u.school_id
                WHERE s.matricule = ? OR s.mat_number = ?
            ");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 3. Fallback search in teachers table
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                       t.subject, t.matricule, sc.name AS school_name
                FROM teachers t
                JOIN users u ON u.id = t.user_id
                LEFT JOIN schools sc ON sc.id = u.school_id
                WHERE t.matricule = ? OR t.staff_id = ?
            ");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 4. Fallback search in principals table
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                       p.matricule, sc.name AS school_name
                FROM principals p
                JOIN users u ON u.id = p.user_id
                LEFT JOIN schools sc ON sc.id = u.school_id
                WHERE p.matricule = ? OR p.staff_id = ?
            ");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 5. Fallback search in dean_of_studies table
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                       d.staff_id AS matricule, d.office_title
                FROM dean_of_studies d
                JOIN users u ON u.id = d.user_id
                WHERE d.staff_id = ?
            ");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        // 6. Fallback search in regional_delegates table
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                       r.matricule, r.delegation_name
                FROM regional_delegates r
                JOIN users u ON u.id = r.user_id
                WHERE r.matricule = ? OR r.staff_id = ?
            ");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 7. Fallback search in admins table
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                       a.matricule
                FROM admins a
                JOIN users u ON u.id = a.user_id
                WHERE a.matricule = ? OR a.staff_id = ?
            ");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 8. Search by phone for delegates / admins / users
        if (!$user) {
            $stmt = $pdo->prepare("
                SELECT u.id, u.full_name, u.role, u.is_activated, u.password_hash, u.school_id, u.region, u.division,
                       sc.name AS school_name
                FROM users u
                LEFT JOIN schools sc ON sc.id = u.school_id
                WHERE u.phone = ?
            ");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        if (!$user) respondError('Matricule not found. Contact your administrator.', 404);

        respond(true, 'Matricule found.', [
            'already_activated' => ((int)($user['is_activated'] ?? 0) === 1),
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

        // Resolve user_id from matricule / staff_id directly from users or sub-tables
        $userId = null;
        $row    = null;

        // 1. Check users table directly
        $stmt = $pdo->prepare("SELECT id, is_activated FROM users WHERE matricule = ?");
        $stmt->execute([$matricule]);
        $row = $stmt->fetch();
        if ($row) $userId = $row['id'];

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM students s JOIN users u ON u.id = s.user_id WHERE s.matricule = ? OR s.mat_number = ?");
            $stmt->execute([$matricule, $matricule]);
            $row = $stmt->fetch();
            if ($row) $userId = $row['id'];
        }

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM teachers t JOIN users u ON u.id = t.user_id WHERE t.matricule = ? OR t.staff_id = ?");
            $stmt->execute([$matricule, $matricule]);
            $row = $stmt->fetch();
            if ($row) $userId = $row['id'];
        }

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM principals p JOIN users u ON u.id = p.user_id WHERE p.matricule = ? OR p.staff_id = ?");
            $stmt->execute([$matricule, $matricule]);
            $row = $stmt->fetch();
            if ($row) $userId = $row['id'];
        }

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM dean_of_studies d JOIN users u ON u.id = d.user_id WHERE d.staff_id = ?");
            $stmt->execute([$matricule]);
            $row = $stmt->fetch();
            if ($row) $userId = $row['id'];
        }

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM regional_delegates r JOIN users u ON u.id = r.user_id WHERE r.matricule = ? OR r.staff_id = ?");
            $stmt->execute([$matricule, $matricule]);
            $row = $stmt->fetch();
            if ($row) $userId = $row['id'];
        }

        if (!$userId) {
            $stmt = $pdo->prepare("SELECT u.id, u.is_activated FROM admins a JOIN users u ON u.id = a.user_id WHERE a.matricule = ? OR a.staff_id = ?");
            $stmt->execute([$matricule, $matricule]);
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
        if (strlen($body['password']) < 6) respondError('Password must be at least 6 characters.');
        if (strlen($body['security_code']) < 4) respondError('Security code must be at least 4 characters.');

        $passwordRaw  = trim($body['password']);
        $securityCode = trim($body['security_code']);
        $passwordHash = hash('sha256', $passwordRaw);
        $securityHash = hash('sha256', $securityCode);

        try {
            $pdo->prepare("UPDATE users SET password_hash = ?, security_code = ?, is_activated = 1 WHERE id = ?")->execute([$passwordHash, $securityCode, $userId]);
        } catch (Exception $e) {
            try { $pdo->prepare("UPDATE users SET password_hash = ?, is_activated = 1 WHERE id = ?")->execute([$passwordHash, $userId]); } catch (Exception $e2) {}
        }
        try { $pdo->prepare("UPDATE students SET password_hash = ?, security_code = ? WHERE user_id = ?")->execute([$passwordHash, $securityCode, $userId]); } catch (Exception $e) {}
        try { $pdo->prepare("UPDATE teachers SET password_hash = ?, security_code = ? WHERE user_id = ?")->execute([$passwordHash, $securityCode, $userId]); } catch (Exception $e) {}
        try { $pdo->prepare("UPDATE principals SET password_hash = ?, security_code = ? WHERE user_id = ?")->execute([$passwordHash, $securityCode, $userId]); } catch (Exception $e) {}
        try { $pdo->prepare("UPDATE dean_of_studies SET password_hash = ?, security_code = ? WHERE user_id = ?")->execute([$passwordHash, $securityCode, $userId]); } catch (Exception $e) {}
        try { $pdo->prepare("UPDATE regional_delegates SET password_hash = ?, security_code = ? WHERE user_id = ?")->execute([$passwordHash, $securityCode, $userId]); } catch (Exception $e) {}
        try { $pdo->prepare("UPDATE admins SET password_hash = ?, security_code = ? WHERE user_id = ?")->execute([$passwordHash, $securityCode, $userId]); } catch (Exception $e) {}

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

        // 1. Direct search in users table by matricule
        $stmt = $pdo->prepare("SELECT * FROM users WHERE matricule = ?");
        $stmt->execute([$matricule]);
        $user = $stmt->fetch();

        // 2. Search in students table
        if (!$user) {
            $stmt = $pdo->prepare("SELECT u.* FROM students s JOIN users u ON u.id = s.user_id WHERE s.mat_number = ? OR s.matricule = ?");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 3. Search in teachers table
        if (!$user) {
            $stmt = $pdo->prepare("SELECT u.* FROM teachers t JOIN users u ON u.id = t.user_id WHERE t.staff_id = ? OR t.matricule = ?");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 4. Search in principals table
        if (!$user) {
            $stmt = $pdo->prepare("SELECT u.* FROM principals p JOIN users u ON u.id = p.user_id WHERE p.staff_id = ? OR p.matricule = ?");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 5. Search in dean of studies table
        if (!$user) {
            $stmt = $pdo->prepare("SELECT u.* FROM dean_of_studies d JOIN users u ON u.id = d.user_id WHERE d.staff_id = ?");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        // 6. Search in regional delegates table
        if (!$user) {
            $stmt = $pdo->prepare("SELECT u.* FROM regional_delegates r JOIN users u ON u.id = r.user_id WHERE r.staff_id = ? OR r.matricule = ?");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 7. Search in admins table
        if (!$user) {
            $stmt = $pdo->prepare("SELECT u.* FROM admins a JOIN users u ON u.id = a.user_id WHERE a.staff_id = ? OR a.matricule = ?");
            $stmt->execute([$matricule, $matricule]);
            $user = $stmt->fetch();
        }

        // 8. Search by phone number
        if (!$user) {
            $stmt = $pdo->prepare("SELECT * FROM users WHERE phone = ?");
            $stmt->execute([$matricule]);
            $user = $stmt->fetch();
        }

        if (!$user) respondError('Matricule not found.', 404);

        $inputPass     = trim($body['password']);
        $inputSec      = trim($body['security_code']);
        $passwordHash  = hash('sha256', $inputPass);
        $securityHash  = hash('sha256', $inputSec);

        $dbPassHash    = $user['password_hash'] ?? '';
        $dbPassRaw     = $user['password_raw'] ?? '';
        $dbSecCode     = $user['security_code'] ?? '';

        $passMatches = ($dbPassHash === $passwordHash) || ($dbPassRaw === $inputPass) || ($dbPassHash === $inputPass);
        $secMatches  = ($dbSecCode === $securityHash) || ($dbSecCode === $inputSec) || ($dbSecCode === $body['security_code']);

        if (!$passMatches) respondError('Incorrect password.', 401);
        if (!$secMatches)  respondError('Incorrect security code.', 401);

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
            $pRaw  = trim($body['password']);
            $pHash = hash('sha256', $pRaw);
            $updates[]    = "password_hash = ?";
            $params[]     = $pHash;
            $updates[]    = "password_raw = ?";
            $params[]     = $pRaw;
            $stuUpdates[] = "password_hash = ?";
            $stuParams[]  = $pHash;
        }
        if (!empty($body['security_code'])) {
            if (strlen($body['security_code']) < 4) respondError('Security code must be at least 4 characters.');
            $sCode = trim($body['security_code']);
            $sHash = hash('sha256', $sCode);
            $updates[]    = "security_code = ?";
            $params[]     = $sCode;
            $stuUpdates[] = "security_code = ?";
            $stuParams[]  = $sCode;
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

        // Sync password and security code across all role sub-tables
        if (!empty($body['password']) || !empty($body['security_code'])) {
            $syncUpdates = [];
            $syncParams  = [];
            if (!empty($body['password'])) {
                $syncUpdates[] = "password_hash = ?";
                $syncParams[]  = hash('sha256', trim($body['password']));
            }
            if (!empty($body['security_code'])) {
                $syncUpdates[] = "security_code = ?";
                $syncParams[]  = trim($body['security_code']);
            }
            if (!empty($syncUpdates)) {
                $syncSql = implode(', ', $syncUpdates);
                $pdo->prepare("UPDATE teachers SET $syncSql WHERE user_id = ?")->execute(array_merge($syncParams, [$userId]));
                $pdo->prepare("UPDATE principals SET $syncSql WHERE user_id = ?")->execute(array_merge($syncParams, [$userId]));
                $pdo->prepare("UPDATE divisional_delegates SET $syncSql WHERE user_id = ?")->execute(array_merge($syncParams, [$userId]));
                $pdo->prepare("UPDATE regional_delegates SET $syncSql WHERE user_id = ?")->execute(array_merge($syncParams, [$userId]));
                $pdo->prepare("UPDATE admins SET $syncSql WHERE user_id = ?")->execute(array_merge($syncParams, [$userId]));
            }
        }

        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role, u.school_id, u.region, u.division, u.password_raw as password, u.security_code,
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

        $pdo  = getDB();
        $stmt = $pdo->prepare("
            SELECT u.id, u.full_name, u.role, u.school_id, u.region, u.division, u.password_raw as password, u.security_code,
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

        if (empty($profile['password'])) $profile['password'] = '';
        if (empty($profile['security_code'])) $profile['security_code'] = '';

        respond(true, 'Profile fetched successfully.', $profile);
        break;

    default:
        respondError('Unknown action.', 404);
}
