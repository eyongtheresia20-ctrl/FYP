<?php
require_once 'backend/config/database.php';
$db = getDB();

echo "=== USERS (BELLO) ===\n";
$stmt = $db->query("SELECT id, matricule, full_name, role, learning_style, primary_learning_style, vark_scores FROM users WHERE full_name LIKE '%Bello%' OR matricule LIKE '%Bello%'");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "\n=== STUDENTS TABLE (BELLO) ===\n";
$stmt = $db->query("SELECT * FROM students WHERE name LIKE '%Bello%' OR matricule LIKE '%Bello%'");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "\n=== STUDENT_ASSESSMENTS / ASSESSMENT_RESULTS (BELLO) ===\n";
$tables = ['student_assessments', 'assessment_results', 'assessments', 'vark_results'];
foreach ($tables as $t) {
    try {
        $stmt = $db->query("SELECT * FROM $t WHERE student_id IN (SELECT id FROM users WHERE full_name LIKE '%Bello%') OR student_matricule LIKE '%Bello%' OR user_id IN (SELECT id FROM users WHERE full_name LIKE '%Bello%')");
        echo "Table: $t\n";
        print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
    } catch (Exception $e) {
        // table might not exist
    }
}
