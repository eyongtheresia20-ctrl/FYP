<?php
// ============================================================
//  MINESEC LST — Create Dedicated Tables for Principals,
//  Divisional Delegates, Regional Delegates & Admins
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- CREATING DEDICATED TABLES FOR PRINCIPALS, DELEGATES & ADMINS ---\n";
    $pdo->exec("SET FOREIGN_KEY_CHECKS = 0;");

    // 1. PRINCIPALS TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS principals (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id       INT UNSIGNED NOT NULL UNIQUE,
            staff_id      VARCHAR(50) UNIQUE,
            school_id     INT UNSIGNED NULL,
            school_name   VARCHAR(200) NULL,
            region        VARCHAR(100) NULL,
            division      VARCHAR(100) NULL,
            password_hash VARCHAR(255) NULL,
            security_code VARCHAR(255) NULL,
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 2. DIVISIONAL DELEGATES TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS divisional_delegates (
            id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id         INT UNSIGNED NOT NULL UNIQUE,
            staff_id        VARCHAR(50) UNIQUE,
            delegation_name VARCHAR(200) NULL,
            region          VARCHAR(100) NULL,
            division        VARCHAR(100) NULL,
            password_hash   VARCHAR(255) NULL,
            security_code   VARCHAR(255) NULL,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 3. REGIONAL DELEGATES TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS regional_delegates (
            id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id         INT UNSIGNED NOT NULL UNIQUE,
            staff_id        VARCHAR(50) UNIQUE,
            delegation_name VARCHAR(200) NULL,
            region          VARCHAR(100) NULL,
            password_hash   VARCHAR(255) NULL,
            security_code   VARCHAR(255) NULL,
            created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 4. ADMINS TABLE (MINESEC ADMIN)
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS admins (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id       INT UNSIGNED NOT NULL UNIQUE,
            staff_id      VARCHAR(50) UNIQUE,
            title         VARCHAR(150) NULL,
            password_hash VARCHAR(255) NULL,
            security_code VARCHAR(255) NULL,
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    echo "Dedicated tables created successfully.\n";

    // 5. Ensure School Exists
    $stmt = $pdo->prepare("SELECT id FROM schools WHERE code = 'LT_NGAOUNDAL'");
    $stmt->execute();
    $schoolId = $stmt->fetchColumn();

    if (!$schoolId) {
        $pdo->prepare("
            INSERT INTO schools (code, name, region, division, town)
            VALUES ('LT_NGAOUNDAL', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal')
        ")->execute();
        $schoolId = $pdo->lastInsertId();
    }

    $schoolName = 'LYCEE TECHNIQUE DE NGAOUNDAL';
    $region     = 'ADAMOUA';
    $division   = 'DJEREM';

    // Helper to insert or get unactivated user
    $createUnactivatedUser = function($name, $email, $role, $phone) use ($pdo, $schoolId, $region, $division) {
        $stmt = $pdo->prepare("SELECT id FROM users WHERE phone = ? OR email = ?");
        $stmt->execute([$phone, $email]);
        $u = $stmt->fetch();

        if ($u) {
            $pdo->prepare("
                UPDATE users
                SET full_name = ?, role = ?, school_id = ?, region = ?, division = ?,
                    is_activated = 0, password_hash = NULL, security_code = NULL, phone = ?
                WHERE id = ?
            ")->execute([$name, $role, $schoolId, $region, $division, $phone, $u['id']]);
            return $u['id'];
        } else {
            $pdo->prepare("
                INSERT INTO users (full_name, email, role, phone, school_id, region, division, is_activated, is_active, password_hash, security_code)
                VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1, NULL, NULL)
            ")->execute([$name, $email, $role, $phone, $schoolId, $region, $division]);
            return $pdo->lastInsertId();
        }
    };

    // --- A. SEED PRINCIPAL ROW IN principals TABLE ---
    $prnUserId = $createUnactivatedUser('Mme. Etoa Christine', 'etoa.c@minesec.cm', 'principal', 'PRN202601');
    $pdo->prepare("DELETE FROM principals WHERE user_id = ? OR staff_id = 'PRN202601'")->execute([$prnUserId]);
    $pdo->prepare("
        INSERT INTO principals (user_id, staff_id, school_id, school_name, region, division)
        VALUES (?, 'PRN202601', ?, ?, ?, ?)
    ")->execute([$prnUserId, $schoolId, $schoolName, $region, $division]);

    // --- B. SEED DIVISIONAL DELEGATE ROW IN divisional_delegates TABLE ---
    $delUserId = $createUnactivatedUser('M. Bikoi Joseph', 'bikoi.j@minesec.cm', 'divisional_delegate', 'DEL202601');
    $pdo->prepare("DELETE FROM divisional_delegates WHERE user_id = ? OR staff_id = 'DEL202601'")->execute([$delUserId]);
    $pdo->prepare("
        INSERT INTO divisional_delegates (user_id, staff_id, delegation_name, region, division)
        VALUES (?, 'DEL202601', 'Délégation Départementale du Djérem', ?, ?)
    ")->execute([$delUserId, $region, $division]);

    // --- C. SEED REGIONAL DELEGATE ROW IN regional_delegates TABLE ---
    $regUserId = $createUnactivatedUser('Dr. Fouda Alphonse', 'fouda.a@minesec.cm', 'regional_delegate', 'REG202601');
    $pdo->prepare("DELETE FROM regional_delegates WHERE user_id = ? OR staff_id = 'REG202601'")->execute([$regUserId]);
    $pdo->prepare("
        INSERT INTO regional_delegates (user_id, staff_id, delegation_name, region)
        VALUES (?, 'REG202601', 'Délégation Régionale de l\'Adamaoua', ?)
    ")->execute([$regUserId, $region]);

    // --- D. SEED ADMIN ROW IN admins TABLE ---
    $admUserId = $createUnactivatedUser('MINESEC Inspector General', 'admin@minesec.cm', 'admin', 'ADM202601');
    $pdo->prepare("DELETE FROM admins WHERE user_id = ? OR staff_id = 'ADM202601'")->execute([$admUserId]);
    $pdo->prepare("
        INSERT INTO admins (user_id, staff_id, title)
        VALUES (?, 'ADM202601', 'MINESEC Inspector General')
    ")->execute([$admUserId]);

    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    echo "SUCCESS: Tables and pre-registered accounts created for all 4 roles:\n";
    echo "1. Table 'principals':          Staff ID 'PRN202601' (Mme. Etoa Christine)\n";
    echo "2. Table 'divisional_delegates': Staff ID 'DEL202601' (M. Bikoi Joseph)\n";
    echo "3. Table 'regional_delegates':   Staff ID 'REG202601' (Dr. Fouda Alphonse)\n";
    echo "4. Table 'admins':               Staff ID 'ADM202601' (MINESEC Inspector General)\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
