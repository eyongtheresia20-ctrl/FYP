<?php
$pdo = new PDO('mysql:host=localhost;dbname=minesec_lst;charset=utf8mb4', 'root', '');
$stmt = $pdo->prepare("UPDATE users SET full_name = 'Dr. Tchatchouang Paul' WHERE role = 'admin' OR full_name = 'MINESEC Inspector General'");
$stmt->execute();
echo "Updated " . $stmt->rowCount() . " admin row(s).\n";

$stmt2 = $pdo->query("SELECT id, full_name, matricule, email, role FROM users WHERE role = 'admin'");
$users = $stmt2->fetchAll(PDO::FETCH_ASSOC);
echo json_encode($users, JSON_PRETTY_PRINT);
