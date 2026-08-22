<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../backend/config/helpers.php';
require_once __DIR__ . '/../backend/config/database.php';

$pdo = getDB();

try {
    // 1. Fetch principal user
    $stmtP = $pdo->query("SELECT * FROM users WHERE role = 'principal' OR full_name LIKE '%Etoa%' LIMIT 5");
    $principals = $stmtP->fetchAll(PDO::FETCH_ASSOC);

    // 2. Fetch all schools
    $stmtS = $pdo->query("SELECT * FROM schools");
    $schools = $stmtS->fetchAll(PDO::FETCH_ASSOC);

    // 3. Fetch all students with their user school_id
    $stmtSt = $pdo->query("
        SELECT s.id AS student_tbl_id, s.user_id, s.full_name, s.class_name, s.school_name AS student_school_name, u.school_id AS user_school_id, u.matricule
        FROM students s
        LEFT JOIN users u ON u.id = s.user_id
    ");
    $students = $stmtSt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'principals' => $principals,
        'schools' => $schools,
        'students' => $students
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
