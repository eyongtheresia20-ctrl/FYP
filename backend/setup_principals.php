<?php
// ============================================================
//  MINESEC LST — Setup Principals Table
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- CREATING PRINCIPALS TABLE ---\n";

    $pdo->exec("
        CREATE TABLE IF NOT EXISTS principals (
            id               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id          INT UNSIGNED NOT NULL UNIQUE,
            school_id        INT UNSIGNED NOT NULL UNIQUE,
            staff_id         VARCHAR(50)  UNIQUE,
            appointment_date DATE         NULL,
            created_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE CASCADE,
            FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    echo "Principals table created successfully.\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
