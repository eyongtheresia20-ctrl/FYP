<?php
require_once 'c:/Users/COUNTESS/Desktop/FYP/backend/config/database.php';
$pdo = getDB();

try {
    $pdo->exec("ALTER TABLE schools ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER town");
    echo "SUCCESS: Added is_active column to schools table\n";
} catch (Exception $e) {
    echo "NOTE: Column might already exist: " . $e->getMessage() . "\n";
}
