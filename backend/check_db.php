<?php
require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "Connected to database!\n";

    // Get active DB name
    $dbName = $pdo->query("SELECT DATABASE()")->fetchColumn();
    echo "Current DB Name: " . $dbName . "\n\n";

    $tables = $pdo->query("SHOW TABLES")->fetchAll(PDO::FETCH_COLUMN);
    echo "Tables: " . implode(', ', $tables) . "\n\n";

    foreach (['users', 'students', 'assessments', 'results'] as $tbl) {
        if (in_array($tbl, $tables)) {
            echo "--- Table: $tbl ---\n";
            $cols = $pdo->query("DESCRIBE `$tbl`")->fetchAll();
            foreach ($cols as $c) {
                echo "  {$c['Field']} ({$c['Type']})\n";
            }
            $count = $pdo->query("SELECT COUNT(*) FROM `$tbl`")->fetchColumn();
            echo "  Row Count: $count\n\n";
        }
    }

    echo "--- Users Data ---\n";
    $users = $pdo->query("SELECT id, full_name, email, role, phone, is_activated, is_active FROM users LIMIT 10")->fetchAll();
    print_r($users);

    echo "--- Students Data ---\n";
    $students = $pdo->query("SELECT * FROM students LIMIT 10")->fetchAll();
    print_r($students);

    echo "--- Assessments Data ---\n";
    $assessments = $pdo->query("SELECT * FROM assessments LIMIT 10")->fetchAll();
    print_r($assessments);

    echo "--- Results Data ---\n";
    $results = $pdo->query("SELECT * FROM results LIMIT 10")->fetchAll();
    print_r($results);

} catch (Exception $e) {
    echo "Database Error: " . $e->getMessage() . "\n";
}
