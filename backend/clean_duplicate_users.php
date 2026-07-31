<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();
$pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");
$pdo->exec("DELETE FROM users WHERE id IN (6, 7);");
$pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");
echo "Cleaned duplicate user rows 6 and 7.\n";
