<?php
require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    $dbName = $pdo->query("SELECT DATABASE()")->fetchColumn();
    echo "Fixing schema for database: $dbName...\n";

    // 1. Ensure read_write_score column in assessments table
    try {
        $pdo->exec("ALTER TABLE assessments ADD COLUMN read_write_score DECIMAL(5,2) DEFAULT 0.00 AFTER kinesthetic_score");
        echo "Added read_write_score column to assessments table.\n";
    } catch (Exception $e) {
        if (!str_contains($e->getMessage(), 'Duplicate column')) {
            echo "Note on assessments table: " . $e->getMessage() . "\n";
        }
    }

    // 2. Ensure summary_en and summary_fr in results table
    try {
        $pdo->exec("ALTER TABLE results ADD COLUMN summary_en TEXT AFTER learning_style");
    } catch (Exception $e) {}

    try {
        $pdo->exec("ALTER TABLE results ADD COLUMN summary_fr TEXT AFTER summary_en");
    } catch (Exception $e) {}

    echo "Schema migration complete for $dbName!\n";

} catch (Exception $e) {
    echo "Migration Error: " . $e->getMessage() . "\n";
}
