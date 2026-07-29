<?php
require_once __DIR__ . '/config/database.php';
$pdo = getDB();
$regions = $pdo->query("SELECT id, code, name_en, name_fr FROM regions ORDER BY id ASC")->fetchAll();
print_r($regions);
