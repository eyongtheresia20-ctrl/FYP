<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDB();
    echo "--- UPDATING SCHEMA ---\n";
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS division VARCHAR(100) NULL;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255) NULL;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS security_code VARCHAR(255) NULL;");

    // Copy existing division, password_hash, security_code from users to students for all existing students
    $pdo->exec("
        UPDATE students s
        JOIN users u ON u.id = s.user_id
        SET s.division = u.division,
            s.password_hash = u.password_hash,
            s.security_code = u.security_code
    ");

    echo "Schema updated successfully! Columns added to students table.\n";
} catch (Exception $e) {
    echo "Error updating schema: " . $e->getMessage() . "\n";
}
