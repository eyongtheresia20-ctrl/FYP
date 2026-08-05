<?php
require_once __DIR__ . '/../backend/config/database.php';
$pdo = getDB();

echo "=== ASSESSMENTS ===\n";
$stmt = $pdo->query("
    SELECT a.*, u.full_name, u.email 
    FROM assessments a 
    JOIN students s ON s.id = a.student_id 
    JOIN users u ON u.id = s.user_id
    ORDER BY a.id DESC
");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "\n=== RESULTS ===\n";
$stmt2 = $pdo->query("
    SELECT r.*, u.full_name 
    FROM results r 
    JOIN students s ON s.id = r.student_id 
    JOIN users u ON u.id = s.user_id
    ORDER BY r.id DESC
");
print_r($stmt2->fetchAll(PDO::FETCH_ASSOC));
