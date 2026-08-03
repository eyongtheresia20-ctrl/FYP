<?php
header('Content-Type: application/json');
require_once __DIR__ . '/config/database.php';

try {
    $db = getDB();

    $db->exec("SET FOREIGN_KEY_CHECKS = 0;");

    // Add missing columns safely
    $cols = [
        "ALTER TABLE users ADD COLUMN matricule VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE schools ADD COLUMN code VARCHAR(50) DEFAULT NULL",
        "ALTER TABLE students ADD COLUMN matricule VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE teachers ADD COLUMN matricule VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE teachers ADD COLUMN staff_id VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE delegates ADD COLUMN matricule VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE delegates ADD COLUMN staff_id VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE delegates ADD COLUMN region VARCHAR(100) DEFAULT NULL",
        "ALTER TABLE delegates ADD COLUMN division VARCHAR(100) DEFAULT NULL",
    ];

    foreach ($cols as $cSql) {
        try {
            $db->exec($cSql);
        } catch (Exception $e) {
        }
    }

    // 2. Seed Schools across Regions and Divisions
    $db->exec("TRUNCATE TABLE schools");
    $db->exec("
        INSERT INTO schools (id, code, name, region, division, town) VALUES
        (1, 'SCH001', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal'),
        (2, 'SCH002', 'LYCEE CLASSIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal'),
        (3, 'SCH003', 'LYCEE BILINGUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal'),
        (4, 'SCH004', 'LYCEE TECHNIQUE DE NGAOUNDERE', 'ADAMOUA', 'VINA', 'Ngaoundéré'),
        (5, 'SCH005', 'LYCEE BILINGUE DE YAOUNDE', 'CENTRE', 'MFOUNDI', 'Yaoundé'),
        (6, 'SCH006', 'LYCEE JOSSE DE DOUALA', 'LITTORAL', 'WOURI', 'Douala')
    ");

    // Ensure User School Associations
    $db->exec("UPDATE users SET school_id = 1, region = 'ADAMOUA', division = 'DJEREM' WHERE id IN (8, 9, 10, 11)");
    $db->exec("UPDATE users SET region = 'ADAMOUA', division = 'DJEREM' WHERE id = 12");
    $db->exec("UPDATE users SET region = 'ADAMOUA', division = 'DJEREM' WHERE id = 13");
    $db->exec("UPDATE users SET region = 'NATIONAL', division = 'CENTRAL' WHERE id = 14");

    // 3. Seed Delegates & Principals tables
    $db->exec("DELETE FROM principals WHERE user_id = 11");
    $db->exec("INSERT INTO principals (user_id, matricule, staff_id, school_name, region, division) VALUES (11, 'P2026001', 'P2026001', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM')");

    $db->exec("DELETE FROM delegates WHERE user_id IN (12, 13)");
    $db->exec("INSERT INTO delegates (user_id, matricule, staff_id, delegate_type, region, division) VALUES (12, 'DD2026001', 'DD2026001', 'divisional', 'ADAMOUA', 'DJEREM')");
    $db->exec("INSERT INTO delegates (user_id, matricule, staff_id, delegate_type, region, division) VALUES (13, 'RD2026001', 'RD2026001', 'regional', 'ADAMOUA', 'DJEREM')");

    // 4. Seed Additional Students and Assessments for Real Metrics
    $chkSt = $db->query("SELECT COUNT(*) FROM students")->fetchColumn();
    if ($chkSt < 8) {
        $sampleStudents = [
            ['name' => 'Kouam Armel', 'mat' => 'AD2026003', 'class' => '1ère TI', 'style' => 'Visual', 'v' => 9, 'a' => 4, 'k' => 2, 'rw' => 1],
            ['name' => 'Mbida Joseph', 'mat' => 'AD2026004', 'class' => '1ère TI', 'style' => 'Visual', 'v' => 10, 'a' => 3, 'k' => 2, 'rw' => 1],
            ['name' => 'Tchinda Grace', 'mat' => 'AD2026005', 'class' => '1ère TI', 'style' => 'Auditory', 'v' => 3, 'a' => 9, 'k' => 3, 'rw' => 1],
            ['name' => 'Nfor Kevin', 'mat' => 'AD2026006', 'class' => '1ère TI', 'style' => 'Kinesthetic', 'v' => 2, 'a' => 3, 'k' => 10, 'rw' => 1],
            ['name' => 'Fokam Eric', 'mat' => 'AD2026007', 'class' => 'Terminale TI', 'style' => 'Visual', 'v' => 8, 'a' => 4, 'k' => 2, 'rw' => 2],
            ['name' => 'Ewondo Marie', 'mat' => 'AD2026008', 'class' => 'Terminale TI', 'style' => 'Read/Write', 'v' => 2, 'a' => 2, 'k' => 1, 'rw' => 11],
        ];

        foreach ($sampleStudents as $s) {
            $db->exec("INSERT INTO users (full_name, role, school_id, region, division, is_activated, matricule) VALUES ('{$s['name']}', 'student', 1, 'ADAMOUA', 'DJEREM', 1, '{$s['mat']}')");
            $uId = $db->lastInsertId();
            $db->exec("INSERT INTO students (user_id, mat_number, matricule, class_name) VALUES ($uId, '{$s['mat']}', '{$s['mat']}', '{$s['class']}')");
            $sId = $db->lastInsertId();
            $db->exec("INSERT INTO assessments (student_id, visual_score, auditory_score, kinesthetic_score, read_write_score, learning_style, completed_at) VALUES ($sId, {$s['v']}, {$s['a']}, {$s['k']}, {$s['rw']}, '{$s['style']}', NOW())");
        }
    }

    $db->exec("SET FOREIGN_KEY_CHECKS = 1;");

    echo json_encode([
        'success' => true,
        'message' => 'Full database seeded successfully with real existing institutions, users, and VARK diagnostic metrics.'
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
