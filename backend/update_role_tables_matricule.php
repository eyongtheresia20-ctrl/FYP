<?php
// ============================================================
//  MINESEC LST — Standardize full_name and matricule Columns
//  Across All Dedicated Role Tables
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- ADDING FULL_NAME AND MATRICULE COLUMNS TO ALL ROLE TABLES ---\n";
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

    // 1. STUDENTS TABLE: Ensure full_name and matricule exist
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");
    $pdo->exec("ALTER TABLE students ADD COLUMN IF NOT EXISTS matricule VARCHAR(50) NULL AFTER class_name;");
    $pdo->exec("UPDATE students SET matricule = mat_number WHERE matricule IS NULL OR matricule = '';");

    // 2. TEACHERS TABLE: Ensure full_name and matricule exist
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");
    $pdo->exec("ALTER TABLE teachers ADD COLUMN IF NOT EXISTS matricule VARCHAR(50) NULL AFTER full_name;");
    $pdo->exec("UPDATE teachers SET matricule = staff_id WHERE matricule IS NULL OR matricule = '';");

    // 3. PRINCIPALS TABLE: Ensure full_name and matricule exist
    $pdo->exec("ALTER TABLE principals ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");
    $pdo->exec("ALTER TABLE principals ADD COLUMN IF NOT EXISTS matricule VARCHAR(50) NULL AFTER full_name;");
    $pdo->exec("UPDATE principals SET matricule = staff_id WHERE matricule IS NULL OR matricule = '';");

    // 4. DIVISIONAL_DELEGATES TABLE: Ensure full_name and matricule exist
    $pdo->exec("ALTER TABLE divisional_delegates ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");
    $pdo->exec("ALTER TABLE divisional_delegates ADD COLUMN IF NOT EXISTS matricule VARCHAR(50) NULL AFTER full_name;");
    $pdo->exec("UPDATE divisional_delegates SET matricule = staff_id WHERE matricule IS NULL OR matricule = '';");

    // 5. REGIONAL_DELEGATES TABLE: Ensure full_name and matricule exist
    $pdo->exec("ALTER TABLE regional_delegates ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");
    $pdo->exec("ALTER TABLE regional_delegates ADD COLUMN IF NOT EXISTS matricule VARCHAR(50) NULL AFTER full_name;");
    $pdo->exec("UPDATE regional_delegates SET matricule = staff_id WHERE matricule IS NULL OR matricule = '';");

    // 6. ADMINS TABLE: Ensure full_name and matricule exist
    $pdo->exec("ALTER TABLE admins ADD COLUMN IF NOT EXISTS full_name VARCHAR(150) NULL AFTER user_id;");
    $pdo->exec("ALTER TABLE admins ADD COLUMN IF NOT EXISTS matricule VARCHAR(50) NULL AFTER full_name;");
    $pdo->exec("UPDATE admins SET matricule = staff_id WHERE matricule IS NULL OR matricule = '';");

    // 7. SYNC full_name FROM users TABLE FOR ALL ROLES
    $pdo->exec("UPDATE students s JOIN users u ON u.id = s.user_id SET s.full_name = u.full_name;");
    $pdo->exec("UPDATE teachers t JOIN users u ON u.id = t.user_id SET t.full_name = u.full_name;");
    $pdo->exec("UPDATE principals p JOIN users u ON u.id = p.user_id SET p.full_name = u.full_name;");
    $pdo->exec("UPDATE divisional_delegates d JOIN users u ON u.id = d.user_id SET d.full_name = u.full_name;");
    $pdo->exec("UPDATE regional_delegates r JOIN users u ON u.id = r.user_id SET r.full_name = u.full_name;");
    $pdo->exec("UPDATE admins a JOIN users u ON u.id = a.user_id SET a.full_name = u.full_name;");

    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    echo "SUCCESS: 'full_name' and 'matricule' columns successfully added and synchronized across all role tables!\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
