<?php
require_once 'backend/config/helpers.php';
require_once 'backend/config/database.php';

$pdo = getDB();

echo "Testing toggle_school_status...\n";
$_GET['action'] = 'toggle_school_status';
$body = ['id' => 1, 'is_active' => 1, 'name' => 'LYCEE BILINGUE DE NGAOUNDAL'];

// Let's test update_school
echo "Testing update_school...\n";
$stmt = $pdo->prepare("UPDATE schools SET name = ?, region = ?, division = ?, town = ? WHERE id = ?");
$stmt->execute(['LYCEE BILINGUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal', 1]);
echo "Updated school successfully!\n";
