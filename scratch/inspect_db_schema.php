<?php
$mysqli = new mysqli('127.0.0.1', 'root', '', 'minesec_lst');
if ($mysqli->connect_error) {
    die("Connection failed: " . $mysqli->connect_error);
}

$tables = ['users', 'students', 'teachers', 'principals', 'regional_delegates', 'divisional_delegates'];

foreach ($tables as $table) {
    echo "=== TABLE: $table ===\n";
    $res = $mysqli->query("DESCRIBE $table");
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            echo " - {$row['Field']} ({$row['Type']})\n";
        }
    } else {
        echo " (Table does not exist)\n";
    }
    echo "\n";
}
