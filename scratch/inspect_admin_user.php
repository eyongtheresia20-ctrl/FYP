<?php
$pdo = new PDO('mysql:host=localhost;dbname=minesec_lst;charset=utf8mb4', 'root', '');
$stmt = $pdo->query("SELECT id, full_name, matricule, email, role FROM users");
$users = $stmt->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($users, JSON_PRETTY_PRINT);
