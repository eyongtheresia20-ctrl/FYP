<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();

echo "--- Questionnaires ---\n";
$q = $pdo->query("SELECT * FROM questionnaires")->fetchAll();
print_r($q);

echo "--- Assessments FK Constraints ---\n";
$fk = $pdo->query("
    SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
    FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = 'school_bd' AND TABLE_NAME = 'assessments' AND REFERENCED_TABLE_NAME IS NOT NULL
")->fetchAll();
print_r($fk);
