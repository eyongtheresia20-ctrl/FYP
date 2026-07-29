<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();
$users = $pdo->query("SELECT id, full_name, role, password_hash, security_code, is_activated FROM users")->fetchAll();
print_r($users);
