<?php
// ============================================================
//  MINESEC LST — Pre-register Unactivated Teacher Account
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- PRE-REGISTERING TEACHER (UNACTIVATED) ---\n";

    // 1. Ensure columns exist
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS class_name VARCHAR(100) NULL AFTER subject;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NULL;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS division VARCHAR(100) NULL;");

    // 2. Ensure school exists
    $stmt = $pdo->prepare("SELECT id FROM schools WHERE code = 'LT_NGAOUNDAL'");
    $stmt->execute();
    $schoolId = $stmt->fetchColumn();
    if (!$schoolId) {
        $pdo->prepare("INSERT INTO schools (code, name, region, division, town)
            VALUES ('LT_NGAOUNDAL', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal')")->execute();
        $schoolId = $pdo->lastInsertId();
    }

    // 3. Create or Update Unactivated Teacher User (Staff ID: T2026001)
    // Password and security code are NULL initially until the teacher activates
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = 'nguene.j@minesec.cm'");
    $stmt->execute();
    $userId = $stmt->fetchColumn();

    if (!$userId) {
        $pdo->prepare("
            INSERT INTO users (full_name, email, password_hash, security_code, role, school_id, region, division, is_activated, is_active)
            VALUES ('M. Nguene Jacques', 'nguene.j@minesec.cm', NULL, NULL, 'teacher', ?, 'ADAMOUA', 'DJEREM', 0, 1)
        ")->execute([$schoolId]);
        $userId = $pdo->lastInsertId();
    } else {
        $pdo->prepare("
            UPDATE users SET password_hash = NULL, security_code = NULL, is_activated = 0, school_id = ?, region = 'ADAMOUA', division = 'DJEREM'
            WHERE id = ?
        ")->execute([$schoolId, $userId]);
    }

    // 4. Create or Update Teachers row
    $stmt = $pdo->prepare("SELECT id FROM teachers WHERE user_id = ?");
    $stmt->execute([$userId]);
    $teacherId = $stmt->fetchColumn();

    if (!$teacherId) {
        $pdo->prepare("
            INSERT INTO teachers (user_id, staff_id, subject, class_name, qualification, division, password_hash, security_code)
            VALUES (?, 'T2026001', 'Informatique', '1ère TI', 'PLEG Informatique', 'DJEREM', NULL, NULL)
        ")->execute([$userId]);
    } else {
        $pdo->prepare("
            UPDATE teachers SET staff_id = 'T2026001', subject = 'Informatique', class_name = '1ère TI', division = 'DJEREM', password_hash = NULL, security_code = NULL
            WHERE user_id = ?
        ")->execute([$userId]);
    }

    echo "Teacher account pre-registered successfully (Unactivated)!\n";
    echo "Matricule: T2026001 | Status: UNACTIVATED (is_activated = 0)\n";
    echo "The teacher can now activate their account using Matricule 'T2026001' and create their password and security code!\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
