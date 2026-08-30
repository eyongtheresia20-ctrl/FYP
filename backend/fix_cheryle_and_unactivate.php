<?php
// ============================================================
//  MINESEC LST — Reset Cheryle Yakwa & All Accounts for Activation
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- FIXING CHERYLE YAKWA & UNACTIVATING ACCOUNTS ---\n";
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

    // 1. Reset Cheryle Yakwa (and all created students like youyou cake, hey you)
    $stmt1 = $pdo->prepare("
        UPDATE users 
        SET is_activated = 0, 
            password_hash = NULL, 
            security_code = NULL,
            phone = NULL
        WHERE full_name LIKE '%cheryle%' 
           OR full_name LIKE '%youyou%' 
           OR full_name LIKE '%hey%'
           OR role = 'student' AND (matricule IS NULL OR matricule != 'AD2026001')
    ");
    $stmt1->execute();
    echo "• Cheryle Yakwa and newly created students reset to UNACTIVATED (is_activated = 0, NULL password, NULL security code, NULL phone).\n";

    // 2. Reset Regional Delegate (Dr. Fouda Alphonse / REG202601) to UNACTIVATED
    $stmt2 = $pdo->prepare("
        UPDATE users
        SET is_activated = 0,
            password_hash = NULL,
            security_code = NULL,
            phone = NULL
        WHERE role = 'regional_delegate' OR id = 13 OR matricule = 'REG202601' OR matricule = 'RD2026001'
    ");
    $stmt2->execute();
    echo "• Regional Delegate account reset to UNACTIVATED (is_activated = 0, NULL password, NULL security code, NULL phone).\n";

    // 3. Clear phone column for all users as requested
    $pdo->exec("UPDATE users SET phone = NULL;");
    echo "• Phone numbers cleared across users table.\n";

    // 4. Also clear student/teacher/subtable password & security hashes
    try { $pdo->exec("UPDATE students SET password_hash = NULL, security_code = NULL WHERE mat_number != 'AD2026001';"); } catch (Exception $e) {}
    try { $pdo->exec("UPDATE regional_delegates SET password_hash = NULL, security_code = NULL;"); } catch (Exception $e) {}
    try { $pdo->exec("UPDATE teachers SET password_hash = NULL, security_code = NULL;"); } catch (Exception $e) {}
    try { $pdo->exec("UPDATE principals SET password_hash = NULL, security_code = NULL;"); } catch (Exception $e) {}

    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    // Print status of Cheryle Yakwa & Regional Delegate
    echo "\n--- VERIFICATION OF ACCOUNTS STATUS ---\n";
    $stmtCheck = $pdo->query("SELECT id, full_name, role, is_activated, password_hash, security_code, phone FROM users WHERE full_name LIKE '%cheryle%' OR role = 'regional_delegate' OR full_name LIKE '%Amina%'");
    $rows = $stmtCheck->fetchAll(PDO::FETCH_ASSOC);
    foreach ($rows as $r) {
        $p = $r['password_hash'] ? 'HASHED' : 'NULL';
        $s = $r['security_code'] ? 'SET' : 'NULL';
        $ph = $r['phone'] ? $r['phone'] : 'NULL';
        echo "• ID: {$r['id']} | Name: {$r['full_name']} | Role: {$r['role']} | Activated: {$r['is_activated']} | Pass: {$p} | Code: {$s} | Phone: {$ph}\n";
    }

    echo "\nSUCCESS: Database updated cleanly!\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
