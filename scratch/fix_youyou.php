<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../backend/config/helpers.php';
require_once __DIR__ . '/../backend/config/database.php';

$pdo = getDB();

try {
    // Fix youyou cake (user 52) to school_id = 1 and school_name = 'LYCEE TECHNIQUE DE NGAOUNDAL'
    $stmt1 = $pdo->prepare("UPDATE users SET school_id = 1 WHERE full_name LIKE '%youyou%' OR id = 52");
    $stmt1->execute();

    $stmt2 = $pdo->prepare("UPDATE students SET school_name = 'LYCEE TECHNIQUE DE NGAOUNDAL' WHERE full_name LIKE '%youyou%' OR user_id = 52");
    $stmt2->execute();

    // Verify all students in school 1
    $stmtSt = $pdo->query("
        SELECT s.id, s.user_id, s.full_name, s.class_name, s.school_name, u.school_id, u.matricule
        FROM students s
        JOIN users u ON u.id = s.user_id
        WHERE u.school_id = 1
    ");
    $students = $stmtSt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'message' => 'Updated youyou cake to school 1',
        'students_in_school_1' => $students
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
