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

    // 2. Setup Divisional Delegate: M. Bikoi Joseph (DD2026001)
    $passHashDel = hash('sha256', 'delegate1');
    $db->exec("UPDATE users SET password_hash = '$passHashDel', security_code = '$secCode', is_activated = 1, matricule = 'DD2026001' WHERE id = 12 OR role = 'divisional_delegate'");

    // 3. Setup Regional Delegate: Dr. Fouda Alphonse (RD2026001)
    $db->exec("UPDATE users SET password_hash = '$passHashDel', security_code = '$secCode', is_activated = 1, matricule = 'RD2026001' WHERE id = 13 OR role = 'regional_delegate'");

    // 4. Setup MINESEC Admin: MINESEC Inspector General (ADMIN2026)
    $passHashAdmin = hash('sha256', 'admin1');
    $db->exec("UPDATE users SET password_hash = '$passHashAdmin', security_code = '$secCode', is_activated = 1, matricule = 'ADMIN2026' WHERE id = 14 OR role = 'admin'");

    echo json_encode([
        'success' => true,
        'message' => 'All actor credentials updated successfully in database.',
        'credentials' => [
            'principal' => ['matricule' => 'P2026001', 'password' => 'principal1', 'security_code' => '1234@'],
            'divisional_delegate' => ['matricule' => 'DD2026001', 'password' => 'delegate1', 'security_code' => '1234@'],
            'regional_delegate' => ['matricule' => 'RD2026001', 'password' => 'delegate1', 'security_code' => '1234@'],
            'admin' => ['matricule' => 'ADMIN2026', 'password' => 'admin1', 'security_code' => '1234@'],
        ]
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
