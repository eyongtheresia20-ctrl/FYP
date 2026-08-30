<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();

// Sync sub-table passwords with users table for activated users
$pdo->exec("UPDATE dean_of_studies d JOIN users u ON u.id = d.user_id SET d.password_hash = u.password_hash, d.security_code = u.security_code WHERE u.is_activated = 1");
$pdo->exec("UPDATE principals p JOIN users u ON u.id = p.user_id SET p.password_hash = u.password_hash, p.security_code = u.security_code WHERE u.is_activated = 1");

echo "=== SCHOOLS TABLE ===\n";
$schools = $pdo->query("SELECT id, code, name FROM schools")->fetchAll(PDO::FETCH_ASSOC);
foreach ($schools as $sc) {
    echo "ID: {$sc['id']} | Code: {$sc['code']} | Name: {$sc['name']}\n";
}

echo "\n=== USERS TABLE STATUS ===\n";
$users = $pdo->query("SELECT id, full_name, role, is_activated, matricule, password_hash, security_code FROM users")->fetchAll(PDO::FETCH_ASSOC);
foreach ($users as $u) {
    $hasPass = !empty($u['password_hash']) ? 'YES' : 'NULL';
    $hasSec  = !empty($u['security_code']) ? 'YES' : 'NULL';
    echo "ID: {$u['id']} | Name: {$u['full_name']} | Role: {$u['role']} | Mat: {$u['matricule']} | Activated: {$u['is_activated']} | PassHash: $hasPass | SecCode: $hasSec\n";
}

echo "\n=== DEAN OF STUDIES TABLE STATUS ===\n";
$deans = $pdo->query("SELECT user_id, full_name, matricule, staff_id, password_hash, security_code FROM dean_of_studies")->fetchAll(PDO::FETCH_ASSOC);
foreach ($deans as $d) {
    $hasPass = !empty($d['password_hash']) ? 'YES' : 'NULL';
    $hasSec  = !empty($d['security_code']) ? 'YES' : 'NULL';
    echo "Matricule: {$d['matricule']} | StaffID: {$d['staff_id']} | Name: {$d['full_name']} | PassHash: $hasPass | SecCode: $hasSec\n";
}
