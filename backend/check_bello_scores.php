<?php
require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "=== BELLO OUMAROU (AD2026001) DATABASE RECORDS ===\n";

    // 1. Check student record
    $stmtSt = $pdo->prepare("SELECT s.id AS student_id, u.id AS user_id, s.full_name, s.mat_number, s.class_name FROM students s JOIN users u ON u.id = s.user_id WHERE s.mat_number = 'AD2026001' OR s.matricule = 'AD2026001'");
    $stmtSt->execute();
    $bello = $stmtSt->fetch(PDO::FETCH_ASSOC);
    print_r($bello);

    if ($bello) {
        $stId = $bello['student_id'];
        
        // 2. Check assessments records
        $stmtAss = $pdo->prepare("SELECT * FROM assessments WHERE student_id = ? ORDER BY id DESC");
        $stmtAss->execute([$stId]);
        $assessments = $stmtAss->fetchAll(PDO::FETCH_ASSOC);
        echo "\n--- ASSESSMENTS TABLE FOR BELLO ---\n";
        print_r($assessments);

        // 3. Check results table
        $stmtRes = $pdo->prepare("SELECT * FROM results WHERE student_id = ?");
        $stmtRes->execute([$stId]);
        $results = $stmtRes->fetchAll(PDO::FETCH_ASSOC);
        echo "\n--- RESULTS TABLE FOR BELLO ---\n";
        print_r($results);
    }
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
