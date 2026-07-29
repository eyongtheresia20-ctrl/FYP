<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDB();
    $pdo->exec("ALTER TABLE users ADD COLUMN IF NOT EXISTS activated_at TIMESTAMP NULL AFTER is_activated;");
    echo "SUCCESS: Added activated_at column to users table!\n";
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
