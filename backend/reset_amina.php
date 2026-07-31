<?php
// ============================================================
// Reset Amina Mohamadou (AD2026002) to Unactivated State
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- RESETTING AMINA MOHAMADOU (AD2026002) TO UNACTIVATED ---\n";

    // 1. Reset users table for user_id = 7
    $pdo->exec("
        UPDATE users
        SET is_activated = 0,
            password_hash = NULL,
            security_code = NULL
        WHERE id = 7 OR full_name LIKE '%Amina%'
    ");

    // 2. Reset students table for user_id = 7
    $pdo->exec("
        UPDATE students
        SET password_hash = NULL,
            security_code = NULL
        WHERE user_id = 7 OR mat_number = 'AD2026002'
    ");

    echo "Amina Mohamadou (AD2026002) has been reset to UNACTIVATED state (is_activated = 0, password_hash = NULL, security_code = NULL).\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
