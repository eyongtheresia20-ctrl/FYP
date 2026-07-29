<?php
// ============================================================
//  MINESEC LST — Setup Teacher Account & Schema
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- SETTING UP TEACHER ACCOUNT & SCHEMA ---\n";

    // 1. Ensure class_name column exists in teachers table
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS class_name VARCHAR(100) NULL AFTER subject;");

    // 2. Ensure school exists
    $stmt = $pdo->prepare("SELECT id FROM schools WHERE code = 'LT_NGAOUNDAL'");
    $stmt->execute();
    $schoolId = $stmt->fetchColumn();
    if (!$schoolId) {
        $pdo->prepare("INSERT INTO schools (code, name, region, division, town)
            VALUES ('LT_NGAOUNDAL', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal')")->execute();
        $schoolId = $pdo->lastInsertId();
    }

    $passHash = hash('sha256', 'password123');
    $pinHash  = hash('sha256', '1234');

    // 3. Create or Update Teacher User (Staff ID: T2026001)
    $stmt = $pdo->prepare("SELECT id FROM users WHERE email = 'nguene.j@minesec.cm'");
    $stmt->execute();
    $userId = $stmt->fetchColumn();

    if (!$userId) {
        $pdo->prepare("
            INSERT INTO users (full_name, email, password_hash, security_code, role, school_id, region, division, is_activated, is_active)
            VALUES ('M. Nguene Jacques', 'nguene.j@minesec.cm', ?, ?, 'teacher', ?, 'ADAMOUA', 'DJEREM', 1, 1)
        ")->execute([$passHash, $pinHash, $schoolId]);
        $userId = $pdo->lastInsertId();
    } else {
        $pdo->prepare("
            UPDATE users SET password_hash = ?, security_code = ?, is_activated = 1, school_id = ?, region = 'ADAMOUA', division = 'DJEREM'
            WHERE id = ?
        ")->execute([$passHash, $pinHash, $schoolId, $userId]);
    }

    // 4. Create or Update Teachers row
    $stmt = $pdo->prepare("SELECT id FROM teachers WHERE user_id = ?");
    $stmt->execute([$userId]);
    $teacherId = $stmt->fetchColumn();

    if (!$teacherId) {
        $pdo->prepare("
            INSERT INTO teachers (user_id, staff_id, subject, class_name, qualification)
            VALUES (?, 'T2026001', 'Informatique', '1ère TI', 'PLEG Informatique')
        ")->execute([$userId]);
    } else {
        $pdo->prepare("
            UPDATE teachers SET staff_id = 'T2026001', subject = 'Informatique', class_name = '1ère TI'
            WHERE user_id = ?
        ")->execute([$userId]);
    }

    echo "Teacher account setup successfully!\n";
    echo "Matricule: T2026001 | Password: password123 | PIN: 1234 | Class: 1ère TI | Subject: Informatique\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
