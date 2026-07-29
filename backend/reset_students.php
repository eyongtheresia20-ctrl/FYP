<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDB();
    echo "--- RESETTING & INSERTING FRESH STUDENTS ---\n";

    // 1. Ensure schema is correct
    $pdo->exec("ALTER TABLE users MODIFY COLUMN email VARCHAR(200) NULL;");
    $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL AFTER password_hash;");
    $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS activated_at TIMESTAMP NULL AFTER is_activated;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");

    // 2. Delete ALL existing students cleanly
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");
    $pdo->exec("TRUNCATE TABLE students;");
    $pdo->exec("DELETE FROM users WHERE role = 'student';");
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    // 3. Ensure school exists
    $stmt = $pdo->prepare("SELECT id FROM schools WHERE code = 'LT_NGAOUNDAL'");
    $stmt->execute();
    $schoolId = $stmt->fetchColumn();
    if (!$schoolId) {
        $pdo->prepare("INSERT INTO schools (code, name, region, division, town)
            VALUES ('LT_NGAOUNDAL', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal')")->execute();
        $schoolId = $pdo->lastInsertId();
    }

    // 4. STUDENT 1 — Unactivated (for Activate Account test)
    $pdo->prepare("
        INSERT INTO users (full_name, email, password_hash, security_code, role, school_id, region, division, is_activated, is_active, created_at)
        VALUES ('Bello Oumarou', NULL, '', NULL, 'student', ?, 'ADAMOUA', 'DJEREM', 0, 1, NOW())
    ")->execute([$schoolId]);
    $s1UserId = $pdo->lastInsertId();

    $pdo->prepare("
        INSERT INTO students (user_id, full_name, class_name, mat_number, birth_date, gender)
        VALUES (?, 'Bello Oumarou', '1ère TI', 'AD2026001', '2007-03-12', 'Male')
    ")->execute([$s1UserId]);

    // 5. STUDENT 2 — Activated (for Sign In test)
    $passHash = hash('sha256', 'password123');
    $pinHash  = hash('sha256', '1234');

    $pdo->prepare("
        INSERT INTO users (full_name, email, password_hash, security_code, role, school_id, region, division, is_activated, activated_at, is_active, created_at)
        VALUES ('Amina Mohamadou', NULL, ?, ?, 'student', ?, 'ADAMOUA', 'DJEREM', 1, NOW(), 1, NOW())
    ")->execute([$passHash, $pinHash, $schoolId]);
    $s2UserId = $pdo->lastInsertId();

    $pdo->prepare("
        INSERT INTO students (user_id, full_name, class_name, mat_number, birth_date, gender)
        VALUES (?, 'Amina Mohamadou', 'Terminale TI', 'AD2026002', '2006-08-25', 'Female')
    ")->execute([$s2UserId]);

    echo "SUCCESS! Students inserted.\n";
    echo "Student 1 user_id: $s1UserId\n";
    echo "Student 2 user_id: $s2UserId\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
