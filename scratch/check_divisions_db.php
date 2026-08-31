<?php
require_once 'd:/xammp/htdocs/minesec_api/config/database.php';
$db = (new Database())->getConnection();

// Check if divisions table exists
$res = $db->query("SHOW TABLES LIKE 'divisions'");
if ($res && $res->rowCount() > 0) {
    echo "divisions table exists!\n";
    $cols = $db->query("SHOW COLUMNS FROM divisions")->fetchAll(PDO::FETCH_ASSOC);
    print_r($cols);
} else {
    echo "No separate divisions table. Divisions are stored directly in schools.division!\n";
}
