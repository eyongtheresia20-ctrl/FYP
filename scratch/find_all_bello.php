<?php
require_once 'backend/config/database.php';
$db = getDB();

echo "=== TABLES ===\n";
$tables = $db->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
print_r($tables);

foreach ($tables as $t) {
    echo "\n=== TABLE $t ===\n";
    $cols = $db->query("SHOW COLUMNS FROM $t")->fetchAll(PDO::FETCH_ASSOC);
    $colNames = array_column($cols, 'Field');
    echo "Columns: " . implode(', ', $colNames) . "\n";

    // check rows matching Bello
    $where = [];
    foreach ($colNames as $c) {
        $where[] = "`$c` LIKE '%Bello%'";
    }
    if (!empty($where)) {
        $sql = "SELECT * FROM `$t` WHERE " . implode(' OR ', $where);
        try {
            $rows = $db->query($sql)->fetchAll(PDO::FETCH_ASSOC);
            if (!empty($rows)) {
                echo "Matches in $t (" . count($rows) . " rows):\n";
                print_r($rows);
            }
        } catch (Exception $e) {}
    }
}
