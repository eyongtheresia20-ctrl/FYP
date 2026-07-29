<?php
// ============================================================
//  MINESEC LST — Setup Multi-Class & Multi-Subject Assignments Table
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- CREATING TEACHER ASSIGNMENTS TABLE (MULTI-CLASS & MULTI-SUBJECT PER ACADEMIC YEAR) ---\n";

    // 1. CREATE TEACHER_ASSIGNMENTS TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS teacher_assignments (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            teacher_id    INT UNSIGNED NOT NULL,
            school_id     INT UNSIGNED NOT NULL,
            class_name    VARCHAR(100) NOT NULL,
            subject_name  VARCHAR(100) NOT NULL,
            academic_year VARCHAR(20)  NOT NULL DEFAULT '2025-2026',
            is_current    TINYINT(1)   DEFAULT 1,
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (school_id)  REFERENCES schools(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    echo "teacher_assignments table created successfully.\n";

    // 2. Resolve Teacher ID (M. Nguene Jacques - Staff ID: T2026001)
    $stmt = $pdo->prepare("SELECT id, school_id FROM users WHERE email = 'nguene.j@minesec.cm'");
    $stmt->execute();
    $teacherUser = $stmt->fetch();

    if (!$teacherUser) {
        // Fallback create user if missing
        $pdo->prepare("
            INSERT INTO users (full_name, email, role, school_id, region, division, is_activated, is_active)
            VALUES ('M. Nguene Jacques', 'nguene.j@minesec.cm', 'teacher', 1, 'ADAMOUA', 'DJEREM', 0, 1)
        ")->execute();
        $teacherUserId = $pdo->lastInsertId();
        $schoolId = 1;
    } else {
        $teacherUserId = $teacherUser['id'];
        $schoolId = $teacherUser['school_id'] ?: 1;
    }

    // 3. Clear existing sample assignments for this teacher for testing
    $pdo->prepare("DELETE FROM teacher_assignments WHERE teacher_id = ?")->execute([$teacherUserId]);

    // 4. Seed Multi-Class & Multi-Subject Assignments for Academic Year 2025-2026
    $assignments = [
        ['1ère TI',       'Informatique',   '2025-2026'],
        ['1ère TI',       'Algorithmique',  '2025-2026'],
        ['Terminale TI',  'Informatique',   '2025-2026'],
    ];

    $stmtIns = $pdo->prepare("
        INSERT INTO teacher_assignments (teacher_id, school_id, class_name, subject_name, academic_year, is_current)
        VALUES (?, ?, ?, ?, ?, 1)
    ");

    foreach ($assignments as $a) {
        $stmtIns->execute([$teacherUserId, $schoolId, $a[0], $a[1], $a[2]]);
    }

    echo "Sample assignments seeded for M. Nguene Jacques:\n";
    echo "1) Class: 1ère TI       | Subject: Informatique  | Academic Year: 2025-2026\n";
    echo "2) Class: 1ère TI       | Subject: Algorithmique | Academic Year: 2025-2026\n";
    echo "3) Class: Terminale TI  | Subject: Informatique  | Academic Year: 2025-2026\n";

    echo "--- SETUP COMPLETE ---\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
