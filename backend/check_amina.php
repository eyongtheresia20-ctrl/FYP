<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();
$u = $pdo->query("SELECT id, full_name, email, is_activated, password_hash, security_code FROM users WHERE id = 7")->fetch();
$s = $pdo->query("SELECT * FROM students WHERE user_id = 7")->fetch();
echo "--- USER ROW (ID 7) ---\n";
print_r($u);
echo "\n--- STUDENT ROW (USER ID 7) ---\n";
print_r($s);
