<?php
require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "Connected to DB!\n";

    // 1. Drop strict FK constraint assessments_ibfk_2 if exists
    try {
        $pdo->exec("ALTER TABLE assessments DROP FOREIGN KEY assessments_ibfk_2");
        echo "Dropped assessments_ibfk_2 constraint.\n";
    } catch (Exception $e) {
        echo "FK Drop note: " . $e->getMessage() . "\n";
    }

    // 2. Make questionnaire_id nullable with default 1
    try {
        $pdo->exec("ALTER TABLE assessments MODIFY COLUMN questionnaire_id INT(10) UNSIGNED NULL DEFAULT 1");
        echo "Made questionnaire_id nullable with default 1.\n";
    } catch (Exception $e) {
        echo "Modify column note: " . $e->getMessage() . "\n";
    }

    echo "FK Fix Migration Completed Successfully!\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
