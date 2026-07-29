<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();
$users = $pdo->query("SELECT u.id as user_id, u.full_name, u.role, st.class_name, st.mat_number, st.birth_date FROM users u LEFT JOIN students st ON st.user_id = u.id")->fetchAll();
print_r($users);
