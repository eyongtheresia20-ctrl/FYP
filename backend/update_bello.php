<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();
$passHash = hash('sha256', 'password123');

$pdo->prepare("UPDATE users u JOIN students s ON s.user_id = u.id SET u.password_hash = ?, u.password_raw = 'password123', u.security_code = '1234', u.is_activated = 1 WHERE s.mat_number = 'AD2026001' OR s.matricule = 'AD2026001'")
    ->execute([$passHash]);

echo "Updated Bello Oumarou (AD2026001) password to 'password123' and security code to '1234'.\n";
