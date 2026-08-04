<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
require_once __DIR__ . '/config/database.php';

try {
    $db = getDB();

    // Add matricule column if missing
    try {
        $db->exec("ALTER TABLE users ADD COLUMN matricule VARCHAR(100) DEFAULT NULL");
    } catch (Exception $e) {}

    // 1. Setup Principal: Mme. Etoa Christine (P2026001)
    $passHash = hash('sha256', 'principal1');
    $secCode  = '1234@';
    $db->exec("UPDATE users SET password_hash = '$passHash', security_code = '$secCode', is_activated = 1, matricule = 'P2026001' WHERE id = 11 OR role = 'principal'");

    // 2. Setup Divisional Delegate: M. Bikoi Joseph (DEL202601)
    $passHashDiv = hash('sha256', 'divisional123');
    $secCodeDiv  = '12345@';
    $db->exec("UPDATE users SET password_hash = '$passHashDiv', security_code = '$secCodeDiv', is_activated = 1, matricule = 'DEL202601' WHERE id = 12 OR role = 'divisional_delegate'");

    // 3. Setup Regional Delegate: Dr. Fouda Alphonse (REG202601)
    $passHashReg = hash('sha256', 'regional123');
    $secCodeReg  = '123456';
    $db->exec("UPDATE users SET password_hash = '$passHashReg', security_code = '$secCodeReg', is_activated = 1, matricule = 'REG202601' WHERE id = 13 OR role = 'regional_delegate'");

    // 4. Setup MINESEC Admin: MINESEC Inspector General (ADM202601)
    $passHashAdmin = hash('sha256', 'admin1');
    $secCodeAdmin  = '1234567';
    $db->exec("UPDATE users SET password_hash = '$passHashAdmin', security_code = '$secCodeAdmin', is_activated = 1, matricule = 'ADM202601' WHERE id = 14 OR role = 'admin'");

    echo json_encode([
        'success' => true,
        'message' => 'All actor credentials updated successfully in database.',
        'credentials' => [
            'principal' => ['matricule' => 'PRN202601', 'password' => 'principal1', 'security_code' => '12345'],
            'divisional_delegate' => ['matricule' => 'DEL202601', 'password' => 'divisional123', 'security_code' => '12345@'],
            'regional_delegate' => ['matricule' => 'REG202601', 'password' => 'regional123', 'security_code' => '123456'],
            'admin' => ['matricule' => 'ADM202601', 'password' => 'admin1', 'security_code' => '1234567'],
        ]
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
