<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../backend/config/helpers.php';
require_once __DIR__ . '/../backend/config/database.php';

$pdo = getDB();

try {
    $stmt1 = $pdo->query("DESCRIBE students");
    $cols1 = $stmt1->fetchAll(PDO::FETCH_ASSOC);

    $stmt2 = $pdo->query("DESCRIBE users");
    $cols2 = $stmt2->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        'students_columns' => $cols1,
        'users_columns' => $cols2
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
