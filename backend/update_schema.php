<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDB();
    $passHash = hash('sha256', 'teacher1');
    $pdo->exec("UPDATE users SET password_hash = '$passHash', password_raw = 'teacher1', security_code = '1234@' WHERE id = 8");
    $pdo->exec("UPDATE users SET password_hash = '$passHash', password_raw = 'teacher1', security_code = '1234@' WHERE role = 'teacher'");
    echo "Updated teacher credentials to password: teacher1 and security code: 1234@\n";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
