<?php
header('Content-Type: application/json');
require_once __DIR__ . '/config/database.php';

try {
    $db = getDB();

    // Ensure matricule column exists
    try {
        $db->exec("ALTER TABLE users ADD COLUMN matricule VARCHAR(100) DEFAULT NULL");
    } catch (Exception $e) {}

    // 1. Principal: Mme. Etoa Christine (P2026001)
    $db->exec("UPDATE users SET password_hash = '', security_code = '', is_activated = 0, matricule = 'P2026001' WHERE id = 11 OR role = 'principal'");

    // 2. Divisional Delegate: M. Bikoi Joseph (DD2026001)
    $db->exec("UPDATE users SET password_hash = '', security_code = '', is_activated = 0, matricule = 'DD2026001' WHERE id = 12 OR role = 'divisional_delegate'");

    // 3. Regional Delegate: Dr. Fouda Alphonse (RD2026001)
    $db->exec("UPDATE users SET password_hash = '', security_code = '', is_activated = 0, matricule = 'RD2026001' WHERE id = 13 OR role = 'regional_delegate'");

    // 4. MINESEC Admin: MINESEC Inspector General (ADMIN2026)
    $db->exec("UPDATE users SET password_hash = '', security_code = '', is_activated = 0, matricule = 'ADMIN2026' WHERE id = 14 OR role = 'admin'");

    echo json_encode([
        'success' => true,
        'message' => 'Accounts reset to unactivated state for first-time activation flow testing.',
        'unactivated_matricules' => [
            'principal' => 'P2026001',
            'divisional_delegate' => 'DD2026001',
            'regional_delegate' => 'RD2026001',
            'admin' => 'ADMIN2026'
        ]
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
