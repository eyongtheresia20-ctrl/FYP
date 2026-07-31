<?php
// ============================================================
//  MINESEC LST — Fix Exact Activation States
//  • Bello Oumarou (AD2026001): ACTIVATED (is_activated = 1)
//  • ALL OTHER USERS: UNACTIVATED (is_activated = 0, NULL hashes)
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- FIXING ACTIVATION STATES ---\n";
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

    $belloPassHash = hash('sha256', 'maru444t');
    $belloPinHash  = hash('sha256', '1234');

    // 1. ACTIVATE BELLO OUMAROU (AD2026001)
    $pdo->prepare("
        UPDATE users u
        JOIN students s ON s.user_id = u.id
        SET u.is_activated = 1,
            u.password_hash = ?,
            u.security_code = ?,
            s.password_hash = ?,
            s.security_code = ?
        WHERE s.mat_number = 'AD2026001' OR s.matricule = 'AD2026001'
    ")->execute([$belloPassHash, $belloPinHash, $belloPassHash, $belloPinHash]);

    echo "• Bello Oumarou (AD2026001) set to ACTIVATED (password: maru444t, PIN: 1234).\n";

    // 2. UNACTIVATE ALL OTHER USERS IN users TABLE
    $pdo->prepare("
        UPDATE users u
        LEFT JOIN students s ON s.user_id = u.id AND (s.mat_number = 'AD2026001' OR s.matricule = 'AD2026001')
        SET u.is_activated = 0,
            u.password_hash = NULL,
            u.security_code = NULL
        WHERE s.id IS NULL
    ")->execute();

    // 3. CLEAR HASHES IN TEACHERS TABLE
    $pdo->exec("UPDATE teachers SET password_hash = NULL, security_code = NULL;");

    // 4. CLEAR HASHES IN AMINA'S STUDENT ROW
    $pdo->prepare("
        UPDATE students
        SET password_hash = NULL, security_code = NULL
        WHERE mat_number != 'AD2026001' AND (matricule IS NULL OR matricule != 'AD2026001')
    ")->execute();

    // 5. CLEAR HASHES IN PRINCIPALS TABLE
    $pdo->exec("UPDATE principals SET password_hash = NULL, security_code = NULL;");

    // 6. CLEAR HASHES IN DIVISIONAL DELEGATES TABLE
    $pdo->exec("UPDATE divisional_delegates SET password_hash = NULL, security_code = NULL;");

    // 7. CLEAR HASHES IN REGIONAL DELEGATES TABLE
    $pdo->exec("UPDATE regional_delegates SET password_hash = NULL, security_code = NULL;");

    // 8. CLEAR HASHES IN ADMINS TABLE
    $pdo->exec("UPDATE admins SET password_hash = NULL, security_code = NULL;");

    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    echo "\nSUCCESS: Activation states fixed!\n";
    echo "• Bello Oumarou (AD2026001): ACTIVATED (1)\n";
    echo "• Teacher (T2026001): UNACTIVATED (0)\n";
    echo "• Amina Mohamadou (AD2026002): UNACTIVATED (0)\n";
    echo "• Principal (PRN202601): UNACTIVATED (0)\n";
    echo "• Divisional Delegate (DEL202601): UNACTIVATED (0)\n";
    echo "• Regional Delegate (REG202601): UNACTIVATED (0)\n";
    echo "• Admin (ADM202601): UNACTIVATED (0)\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
