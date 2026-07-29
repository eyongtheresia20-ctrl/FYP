<?php
// ============================================================
//  MINESEC LST — Database Seeder Script
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();

    echo "--- SEEDING MINESEC LST DATABASE ---\n";

    // 1. Ensure security_code column exists
    $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL AFTER password_hash;");

    // 2. Insert School if not exists
    $stmt = $pdo->prepare("SELECT id FROM schools WHERE code = ?");
    $stmt->execute(['GHS_YAOUNDE']);
    $school = $stmt->fetch();

    if (!$school) {
        $pdo->prepare("
            INSERT INTO schools (code, name, region, division, town)
            VALUES ('GHS_YAOUNDE', 'Lycée Général de Yaoundé', 'Centre', 'Mfoundi', 'Yaoundé')
        ")->execute();
        $schoolId = $pdo->lastInsertId();
    } else {
        $schoolId = $school['id'];
    }

    $passHash = hash('sha256', 'password123');
    $pinHash  = hash('sha256', '1234');

    // Helper to insert or get user
    $createUser = function($name, $email, $role, $phone, $isActivated) use ($pdo, $schoolId, $passHash, $pinHash) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $u = $stmt->fetch();
        if ($u) return $u['id'];

        $pdo->prepare("
            INSERT INTO users (full_name, email, password_hash, security_code, role, phone, school_id, region, division, is_activated, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, 'Centre', 'Mfoundi', ?, 1)
        ")->execute([$name, $email, $passHash, $pinHash, $role, $phone, $schoolId, $isActivated ? 1 : 0]);

        return $pdo->lastInsertId();
    };

    // --- A. STUDENT 1 (Unactivated — for testing Activate Account) ---
    $s1_userId = $createUser('Kamga Paul', 'paul.kamga@student.cm', 'student', '671111111', false);
    $pdo->prepare("DELETE FROM students WHERE user_id = ?")->execute([$s1_userId]);
    $pdo->prepare("INSERT INTO students (user_id, class_name, mat_number, gender) VALUES (?, 'Form 5 A', 'CM2026001', 'Male')")->execute([$s1_userId]);

    // --- B. STUDENT 2 (Activated — for testing Sign In) ---
    $s2_userId = $createUser('Ngo Mbock Marie', 'marie.ngo@student.cm', 'student', '672222222', true);
    $pdo->prepare("DELETE FROM students WHERE user_id = ?")->execute([$s2_userId]);
    $pdo->prepare("INSERT INTO students (user_id, class_name, mat_number, gender) VALUES (?, 'Form 5 B', 'CM2026002', 'Female')")->execute([$s2_userId]);

    // --- C. TEACHER (Activated) ---
    $t_userId = $createUser('Dr. Abena François', 'abena.f@teacher.cm', 'teacher', '673333333', true);
    $pdo->prepare("DELETE FROM teachers WHERE user_id = ?")->execute([$t_userId]);
    $pdo->prepare("INSERT INTO teachers (user_id, staff_id, subject) VALUES (?, 'TCH202601', 'Computer Science')")->execute([$t_userId]);

    // --- D. PRINCIPAL (Activated) ---
    $createUser('Mme. Etoa Christine', 'etoa.c@principal.cm', 'principal', 'PRN202601', true);

    // --- E. DIVISIONAL DELEGATE (Activated) ---
    $createUser('M. Bikoi Joseph', 'bikoi.j@delegate.cm', 'divisional_delegate', 'DEL202601', true);

    // --- F. REGIONAL DELEGATE (Activated) ---
    $createUser('Dr. Fouda Alphonse', 'fouda.a@delegate.cm', 'regional_delegate', 'REG202601', true);

    // --- G. ADMIN (Activated) ---
    $createUser('MINESEC Inspector General', 'admin@minesec.cm', 'admin', 'ADM202601', true);

    echo "SUCCESS: Database seeded successfully!\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
