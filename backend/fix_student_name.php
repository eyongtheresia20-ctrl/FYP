<?php
require_once __DIR__ . '/config/database.php';
try {
    $pdo = getDB();

    // 1. Add full_name column to students table if missing
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NOT NULL DEFAULT '' AFTER user_id;");
    echo "Column full_name added to students.\n";

    // 2. Update the two existing students with their names
    $pdo->exec("UPDATE students SET full_name = 'Bello Oumarou' WHERE mat_number = 'AD2026001';");
    $pdo->exec("UPDATE students SET full_name = 'Amina Mohamadou' WHERE mat_number = 'AD2026002';");
    echo "Student names updated successfully.\n";

    // 3. Show result
    $stmt = $pdo->query("SELECT id, full_name, mat_number, class_name, gender, birth_date FROM students;");
    echo "\n--- STUDENTS TABLE ---\n";
    while ($row = $stmt->fetch()) {
        echo "ID: {$row['id']} | Name: {$row['full_name']} | Matricule: {$row['mat_number']} | Class: {$row['class_name']} | Gender: {$row['gender']} | DOB: {$row['birth_date']}\n";
    }

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
