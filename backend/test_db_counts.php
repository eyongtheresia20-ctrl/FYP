<?php
require_once __DIR__ . '/config/database.php';
$db = getDB();

$tables = ['users', 'students', 'teachers', 'principals', 'delegates', 'schools', 'assessments', 'results', 'teacher_classes'];
foreach ($tables as $t) {
    try {
        $c = $db->query("SELECT COUNT(*) FROM `$t`")->fetchColumn();
        echo "$t: $c rows\n";
    } catch (Exception $e) {
        echo "$t: Table missing or error (" . $e->getMessage() . ")\n";
    }
}
