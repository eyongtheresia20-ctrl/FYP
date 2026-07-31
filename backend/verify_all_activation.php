<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();

echo "=== USERS TABLE STATUS ===\n";
$users = $pdo->query("SELECT id, full_name, role, is_activated, password_hash, security_code FROM users")->fetchAll();
foreach ($users as $u) {
    $hasPass = !empty($u['password_hash']) ? 'YES' : 'NULL';
    $hasSec  = !empty($u['security_code']) ? 'YES' : 'NULL';
    echo "ID: {$u['id']} | Name: {$u['full_name']} | Role: {$u['role']} | Activated: {$u['is_activated']} | PassHash: $hasPass | SecCode: $hasSec\n";
}

echo "\n=== TEACHERS TABLE STATUS ===\n";
$teachers = $pdo->query("SELECT user_id, full_name, matricule, password_hash, security_code FROM teachers")->fetchAll();
foreach ($teachers as $t) {
    $hasPass = !empty($t['password_hash']) ? 'YES' : 'NULL';
    $hasSec  = !empty($t['security_code']) ? 'YES' : 'NULL';
    echo "Matricule: {$t['matricule']} | Name: {$t['full_name']} | PassHash: $hasPass | SecCode: $hasSec\n";
}

echo "\n=== STUDENTS TABLE STATUS ===\n";
$students = $pdo->query("SELECT user_id, full_name, mat_number, password_hash, security_code FROM students")->fetchAll();
foreach ($students as $s) {
    $hasPass = !empty($s['password_hash']) ? 'YES' : 'NULL';
    $hasSec  = !empty($s['security_code']) ? 'YES' : 'NULL';
    echo "Matricule: {$s['mat_number']} | Name: {$s['full_name']} | PassHash: $hasPass | SecCode: $hasSec\n";
}
