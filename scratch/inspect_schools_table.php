<?php
require_once 'c:/Users/COUNTESS/Desktop/FYP/backend/config/database.php';
$pdo = getDB();

$stmt = $pdo->query("SHOW COLUMNS FROM schools");
$cols = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo "=== SCHOOLS TABLE COLUMNS ===\n";
foreach ($cols as $c) {
    echo "{$c['Field']} - {$c['Type']} - {$c['Null']} - Default: {$c['Default']}\n";
}

$stmt2 = $pdo->query("SELECT * FROM schools LIMIT 10");
$rows = $stmt2->fetchAll(PDO::FETCH_ASSOC);
echo "\n=== SCHOOLS ROWS ===\n";
print_r($rows);
