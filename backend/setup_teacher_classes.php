<?php
// ============================================================
//  MINESEC LST — Setup Teacher Ticked Classes System
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- CREATING TEACHER CLASSES TABLE (CLASS TICKING SYSTEM) ---\n";

    // 1. CREATE TEACHER_CLASSES TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS teacher_classes (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            teacher_id    INT UNSIGNED NOT NULL,
            school_id     INT UNSIGNED NOT NULL,
            class_name    VARCHAR(100) NOT NULL,
            academic_year VARCHAR(20)  NOT NULL DEFAULT '2025-2026',
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (teacher_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (school_id)  REFERENCES schools(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    echo "teacher_classes table created successfully.\n";

    // 2. Resolve Teacher ID (M. Nguene Jacques - Staff ID: T2026001)
    $stmt = $pdo->prepare("SELECT id, school_id FROM users WHERE email = 'nguene.j@minesec.cm'");
    $stmt->execute();
    $teacherUser = $stmt->fetch();

    if (!$teacherUser) {
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

    // 3. Clear and seed ticked classes for teacher T2026001 (e.g. 1ère TI and Terminale TI)
    $pdo->prepare("DELETE FROM teacher_classes WHERE teacher_id = ?")->execute([$teacherUserId]);

    $tickedClasses = ['1ère TI', 'Terminale TI'];
    $stmtIns = $pdo->prepare("
        INSERT INTO teacher_classes (teacher_id, school_id, class_name, academic_year)
        VALUES (?, ?, ?, '2025-2026')
    ");

    foreach ($tickedClasses as $cls) {
        $stmtIns->execute([$teacherUserId, $schoolId, $cls]);
    }

    echo "Ticked classes seeded for teacher M. Nguene Jacques:\n";
    echo "• [✓] 1ère TI\n";
    echo "• [✓] Terminale TI\n";

    echo "--- SETUP COMPLETE ---\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
