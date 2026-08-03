<?php
require_once __DIR__ . '/config/database.php';
$db = getDB();

foreach (['users', 'students', 'teachers', 'principals', 'delegates', 'schools'] as $t) {
    try {
        $cols = $db->query("DESCRIBE `$t`")->fetchAll(PDO::FETCH_COLUMN);
        echo "$t columns: " . implode(', ', $cols) . "\n";
    } catch (Exception $e) {
        echo "$t error: " . $e->getMessage() . "\n";
    }
}
