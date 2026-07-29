<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDB();
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");
    echo "SUCCESS: Added full_name column directly to students table!\n";
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
