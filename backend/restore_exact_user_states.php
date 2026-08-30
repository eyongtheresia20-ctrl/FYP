<?php
// ============================================================
//  MINESEC LST — Restore Exact Active Accounts & Unactivated Accounts
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- RESTORING EXACT USER ACTIVATION STATES & CREDENTIALS ---\n";
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

    // 1. TEACHER: M. Nguene Jacques
    $passTeacher = hash('sha256', 'teacher1');
    $secTeacher  = '1234@';
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 1, password_hash = ?, security_code = ?
        WHERE full_name LIKE '%Nguene%' OR role = 'teacher'
    ")->execute([$passTeacher, $secTeacher]);
    try { $pdo->prepare("UPDATE teachers SET password_hash = ?, security_code = ?")->execute([$passTeacher, $secTeacher]); } catch (Exception $e) {}
    echo "• Teacher (M. Nguene Jacques): ACTIVATED (Password: teacher1 | Security Code: 1234@)\n";

    // 2. STUDENT 1: Bello Oumarou
    $passBello = hash('sha256', 'maru444t');
    $secBello  = '1234';
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 1, password_hash = ?, security_code = ?
        WHERE full_name LIKE '%Bello%' OR matricule = 'AD2026001'
    ")->execute([$passBello, $secBello]);
    try { $pdo->prepare("UPDATE students SET password_hash = ?, security_code = ? WHERE mat_number = 'AD2026001' OR matricule = 'AD2026001'")->execute([$passBello, $secBello]); } catch (Exception $e) {}
    echo "• Student (Bello Oumarou): ACTIVATED (Password: maru444t | Security Code: 1234)\n";

    // 3. STUDENT 2: Amina Mohamadou
    $passAmina = hash('sha256', 'amina123');
    $secAmina  = '1234';
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 1, password_hash = ?, security_code = ?
        WHERE full_name LIKE '%Amina%' OR matricule = 'AD2026002'
    ")->execute([$passAmina, $secAmina]);
    try { $pdo->prepare("UPDATE students SET password_hash = ?, security_code = ? WHERE mat_number = 'AD2026002' OR full_name LIKE '%Amina%'")->execute([$passAmina, $secAmina]); } catch (Exception $e) {}
    echo "• Student (Amina Mohamadou): ACTIVATED (Password: amina123 | Security Code: 1234)\n";

    // 4. PRINCIPAL: Mme. Etoa Christine
    $passPrn = hash('sha256', 'principal1');
    $secPrn  = 'P1234';
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 1, password_hash = ?, security_code = ?
        WHERE full_name LIKE '%Etoa%' OR role = 'principal'
    ")->execute([$passPrn, $secPrn]);
    try { $pdo->prepare("UPDATE principals SET password_hash = ?, security_code = ?")->execute([$passPrn, $secPrn]); } catch (Exception $e) {}
    echo "• Principal (Mme. Etoa Christine): ACTIVATED (Password: principal1 | Security Code: P1234)\n";

    // 5. DEAN OF STUDIES: M. Bikoi Joseph
    $passDean = hash('sha256', 'dean1');
    $secDean  = 'D1234';
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 1, password_hash = ?, security_code = ?
        WHERE full_name LIKE '%Bikoi%' OR role = 'dean_of_studies'
    ")->execute([$passDean, $secDean]);
    try { $pdo->prepare("UPDATE dean_of_studies SET password_hash = ?, security_code = ?")->execute([$passDean, $secDean]); } catch (Exception $e) {}
    echo "• Dean of Studies (M. Bikoi Joseph): ACTIVATED (Password: dean1 | Security Code: D1234)\n";

    // 6. REGIONAL DELEGATE: Dr. Fouda Alphonse
    $passReg = hash('sha256', 'regional1');
    $secReg  = '123456@';
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 1, password_hash = ?, security_code = ?
        WHERE full_name LIKE '%Fouda%' OR role = 'regional_delegate'
    ")->execute([$passReg, $secReg]);
    try { $pdo->prepare("UPDATE regional_delegates SET password_hash = ?, security_code = ?")->execute([$passReg, $secReg]); } catch (Exception $e) {}
    echo "• Regional Delegate (Dr. Fouda Alphonse): ACTIVATED (Password: regional1 | Security Code: 123456@)\n";

    // 7. MINESEC ADMIN: Inspector General
    $passAdmin = hash('sha256', 'admin1');
    $secAdmin  = '1234#';
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 1, password_hash = ?, security_code = ?
        WHERE full_name LIKE '%Inspector%' OR role = 'admin'
    ")->execute([$passAdmin, $secAdmin]);
    try { $pdo->prepare("UPDATE admins SET password_hash = ?, security_code = ?")->execute([$passAdmin, $secAdmin]); } catch (Exception $e) {}
    echo "• MINESEC Admin (Inspector General): ACTIVATED (Password: admin1 | Security Code: 1234#)\n";

    // 8. UNACTIVATED TEST ACCOUNTS: cheryle yakwa, youyou cake, hey you
    $pdo->prepare("
        UPDATE users 
        SET is_activated = 0, password_hash = NULL, security_code = NULL
        WHERE full_name LIKE '%cheryle%' OR full_name LIKE '%youyou%' OR full_name LIKE '%hey%'
    ")->execute();
    echo "• Unactivated Test Accounts (cheryle yakwa, youyou cake, hey you): UNACTIVATED (is_activated = 0, NULL Pass, NULL Code)\n";

    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    // Print summary table
    echo "\n--- VERIFICATION OF DATABASE USERS TABLE ---\n";
    $stmt = $pdo->query("SELECT id, full_name, role, is_activated, password_hash, security_code FROM users ORDER BY id");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    foreach ($users as $u) {
        $st = $u['is_activated'] == 1 ? "ACTIVATED (1)" : "UNACTIVATED (0)";
        $p  = $u['password_hash'] ? "SET" : "NULL";
        $c  = $u['security_code'] ? $u['security_code'] : "NULL";
        echo "• ID: {$u['id']} | Name: " . str_pad($u['full_name'], 25) . " | Role: " . str_pad($u['role'], 18) . " | Status: {$st} | SecCode: {$c}\n";
    }

    echo "\nSUCCESS: Database successfully restored to exact working state!\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
