<?php
// ============================================================
//  MINESEC LST — Fix Activation State for Unactivated Accounts
//  Fixes 'youyou1234' and any users without passwords/security codes
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- FIXING ACTIVATION STATES IN DATABASE ---\n";
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

    // 1. Ensure any user without password_hash or security_code has is_activated = 0
    $stmt1 = $pdo->prepare("
        UPDATE users 
        SET is_activated = 0, 
            password_hash = NULL, 
            security_code = NULL 
        WHERE password_hash IS NULL 
           OR password_hash = '' 
           OR security_code IS NULL 
           OR security_code = ''
           OR LENGTH(password_hash) < 10
    ");
    $stmt1->execute();
    echo "• Updated users table: unactivated accounts set to is_activated = 0 (Affected rows: " . $stmt1->rowCount() . ").\n";

    // 2. Explicitly ensure youyou1234 and hey1233 have is_activated = 0
    $stmt2 = $pdo->prepare("
        UPDATE users u
        JOIN students s ON s.user_id = u.id
        SET u.is_activated = 0, u.password_hash = NULL, u.security_code = NULL,
            s.password_hash = NULL, s.security_code = NULL
        WHERE s.mat_number != 'AD2026001' AND (s.matricule IS NULL OR s.matricule != 'AD2026001')
    ");
    $stmt2->execute();
    echo "• Reset all non-Bello students to is_activated = 0 (Affected rows: " . $stmt2->rowCount() . ").\n";

    // 3. Make sure Bello Oumarou (AD2026001) is the only active student account
    $belloPassHash = hash('sha256', 'maru444t');
    $belloPinHash  = hash('sha256', '1234');

    $pdo->prepare("
        UPDATE users u
        JOIN students s ON s.user_id = u.id
        SET u.is_activated = 1,
            u.password_hash = ?,
            u.security_code = ?,
            s.password_hash = ?,
            s.security_code = ?
        WHERE s.mat_number = 'AD2026001' OR s.matricule = 'AD2026001'
    ")->execute([$belloPassHash, $belloPinHash, $belloPassHash, $belloPinHash]);

    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    // 4. Print current status of all students
    echo "\n--- CURRENT STUDENTS ACTIVATION STATUS ---\n";
    $stmt = $pdo->query("
        SELECT s.id AS student_id, u.id AS user_id, COALESCE(s.full_name, u.full_name) AS full_name, 
               COALESCE(s.mat_number, s.matricule, u.matricule) AS matricule, 
               u.is_activated, s.password_hash AS student_pass, u.password_hash AS user_pass
        FROM students s
        LEFT JOIN users u ON u.id = s.user_id
    ");
    $students = $stmt->fetchAll(PDO::FETCH_ASSOC);

    foreach ($students as $st) {
        $isAct = ($st['is_activated'] == 1 && !empty($st['user_pass'])) ? "ACTIVATED (1)" : "NOT ACTIVATED (0)";
        echo "• ID: {$st['student_id']} | Name: {$st['full_name']} | Matricule: {$st['matricule']} => Status: {$isAct}\n";
    }

    echo "\nSUCCESS: Database activation states updated cleanly!\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
