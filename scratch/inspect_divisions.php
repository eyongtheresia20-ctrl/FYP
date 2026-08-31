<?php
require_once 'backend/config/database.php';
$pdo = getDB();

echo "=== REGIONS TABLE ===\n";
$regions = $pdo->query("SELECT * FROM regions")->fetchAll(PDO::FETCH_ASSOC);
print_r($regions);

echo "\n=== DIVISIONS TABLE ===\n";
$divisions = $pdo->query("SELECT * FROM divisions")->fetchAll(PDO::FETCH_ASSOC);
print_r($divisions);

echo "\n=== SCHOOLS TABLE ===\n";
$schools = $pdo->query("SELECT * FROM schools")->fetchAll(PDO::FETCH_ASSOC);
print_r($schools);
