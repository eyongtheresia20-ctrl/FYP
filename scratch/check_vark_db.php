<?php
require_once 'c:/Users/COUNTESS/Desktop/FYP/backend/config/database.php';
$pdo = getDB();

echo "=== ASSESSMENTS TABLE ===\n";
$stmt = $pdo->query("SELECT a.id, a.student_id, u.full_name, a.visual_score, a.auditory_score, a.kinesthetic_score, a.read_write_score, a.learning_style 
                     FROM assessments a 
                     LEFT JOIN students s ON s.id = a.student_id 
                     LEFT JOIN users u ON u.id = s.user_id");
$assessments = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($assessments);

echo "=== ALL STUDENTS IN DB ===\n";
$stmt = $pdo->query("SELECT s.id as student_id, u.full_name, s.matricule, sch.name as school_name 
                     FROM students s 
                     JOIN users u ON u.id = s.user_id 
                     LEFT JOIN schools sch ON sch.id = s.school_id");
$students = $stmt->fetchAll(PDO::FETCH_ASSOC);
print_r($students);

echo "=== HOW ADMIN.PHP CALCULATES VARK ===\n";
$stmt = $pdo->query("SELECT learning_style, COUNT(*) as count FROM assessments GROUP BY learning_style");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
