<?php
require_once 'backend/config/database.php';
$db = getDB();

echo "=== ASSESSMENTS FOR STUDENT_ID = 9 ===\n";
$stmt = $db->query("SELECT * FROM assessments WHERE student_id = 9 ORDER BY completed_at ASC");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));

echo "=== RESULTS FOR STUDENT_ID = 9 ===\n";
$stmt = $db->query("SELECT * FROM results WHERE student_id = 9");
print_r($stmt->fetchAll(PDO::FETCH_ASSOC));
