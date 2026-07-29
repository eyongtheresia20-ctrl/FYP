<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();
$passHash = hash('sha256', 'maru444t');
$pinHash  = hash('sha256', '1234');

$pdo->prepare("UPDATE users u JOIN students s ON s.user_id = u.id SET u.password_hash = ?, u.security_code = ?, u.is_activated = 1 WHERE s.mat_number = 'AD2026001'")
    ->execute([$passHash, $pinHash]);

echo "Updated Bello Oumarou (AD2026001) password to 'maru444t' and security code to '1234'.\n";
