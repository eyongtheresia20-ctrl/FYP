<?php
// ============================================================
//  MINESEC LST — Create Dedicated Tables for Principals,
//  Divisional Delegates, Regional Delegates & Admins
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- CREATING DEDICATED TABLES FOR PRINCIPALS, DELEGATES & ADMINS ---\n";
    // Ensure matricule and full_name columns exist on users and role tables
    try { $pdo->exec("ALTER TABLE users ADD COLUMN matricule VARCHAR(50) NULL;"); } catch (Exception $e) {}
    try { $pdo->exec("ALTER TABLE principals ADD COLUMN full_name VARCHAR(150) NULL, ADD COLUMN matricule VARCHAR(50) NULL;"); } catch (Exception $e) {}
    try { $pdo->exec("ALTER TABLE dean_of_studies ADD COLUMN full_name VARCHAR(150) NULL, ADD COLUMN matricule VARCHAR(50) NULL;"); } catch (Exception $e) {}
    try { $pdo->exec("ALTER TABLE regional_delegates ADD COLUMN full_name VARCHAR(150) NULL, ADD COLUMN matricule VARCHAR(50) NULL;"); } catch (Exception $e) {}
    try { $pdo->exec("ALTER TABLE admins ADD COLUMN full_name VARCHAR(150) NULL, ADD COLUMN matricule VARCHAR(50) NULL;"); } catch (Exception $e) {}

    // 1. PRINCIPALS TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS principals (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id       INT UNSIGNED NOT NULL UNIQUE,
            full_name     VARCHAR(150) NULL,
            matricule     VARCHAR(50) NULL,
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

    // 2. DEAN OF STUDIES TABLE (CENSEUR / DIRECTEUR DES ÉTUDES)
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS dean_of_studies (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id       INT UNSIGNED NOT NULL UNIQUE,
            full_name     VARCHAR(150) NULL,
            matricule     VARCHAR(50) NULL,
            staff_id      VARCHAR(50) UNIQUE,
            school_id     INT UNSIGNED NULL,
            school_name   VARCHAR(200) NULL,
            region        VARCHAR(100) NULL,
            division      VARCHAR(100) NULL,
            office_title  VARCHAR(150) DEFAULT 'Censeur / Directeur des Études',
            password_hash VARCHAR(255) NULL,
            security_code VARCHAR(255) NULL,
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 3. REGIONAL DELEGATES TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS regional_delegates (
            id              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id         INT UNSIGNED NOT NULL UNIQUE,
            full_name       VARCHAR(150) NULL,
            matricule       VARCHAR(50) NULL,
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
            full_name     VARCHAR(150) NULL,
            matricule     VARCHAR(50) NULL,
            staff_id      VARCHAR(50) UNIQUE,
            title         VARCHAR(150) NULL,
            password_hash VARCHAR(255) NULL,
            security_code VARCHAR(255) NULL,
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    echo "Dedicated tables created successfully.\n";

    // 5. Ensure School Exists (Lookup SCH001 / ID 1)
    $stmt = $pdo->prepare("SELECT id FROM schools WHERE code = 'SCH001' OR name LIKE '%LYCEE TECHNIQUE DE NGAOUNDAL%' ORDER BY id ASC LIMIT 1");
    $stmt->execute();
    $schoolId = $stmt->fetchColumn();

    if (!$schoolId) {
        $pdo->prepare("
            INSERT INTO schools (code, name, region, division, town)
            VALUES ('SCH001', 'LYCEE TECHNIQUE DE NGAOUNDAL', 'ADAMOUA', 'DJEREM', 'Ngaoundal')
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
                    is_activated = 0, password_hash = NULL, security_code = NULL, phone = ?, matricule = ?
                WHERE id = ?
            ")->execute([$name, $role, $schoolId, $region, $division, $phone, $phone, $u['id']]);
            return $u['id'];
        } else {
            $pdo->prepare("
                INSERT INTO users (full_name, email, role, phone, matricule, school_id, region, division, is_activated, is_active, password_hash, security_code)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 1, NULL, NULL)
            ")->execute([$name, $email, $role, $phone, $phone, $schoolId, $region, $division]);
            return $pdo->lastInsertId();
        }
    };

    // --- A. SEED PRINCIPAL ROW IN principals TABLE ---
    $prnUserId = $createUnactivatedUser('Mme. Etoa Christine', 'etoa.c@minesec.cm', 'principal', 'P2026001');
    $pdo->prepare("DELETE FROM principals WHERE user_id = ? OR staff_id = 'P2026001'")->execute([$prnUserId]);
    $pdo->prepare("
        INSERT INTO principals (user_id, full_name, matricule, staff_id, school_id, school_name, region, division)
        VALUES (?, 'Mme. Etoa Christine', 'P2026001', 'P2026001', ?, ?, ?, ?)
    ")->execute([$prnUserId, $schoolId, $schoolName, $region, $division]);

    // --- B. SEED DEAN OF STUDIES ROW IN dean_of_studies TABLE ---
    $deanUserId = $createUnactivatedUser('M. Bikoi Joseph', 'bikoi.j@minesec.cm', 'dean_of_studies', 'DS202601');
    $pdo->prepare("DELETE FROM dean_of_studies WHERE user_id = ? OR staff_id = 'DS202601'")->execute([$deanUserId]);
    $pdo->prepare("
        INSERT INTO dean_of_studies (user_id, full_name, matricule, staff_id, school_id, school_name, region, division, office_title)
        VALUES (?, 'M. Bikoi Joseph', 'DS202601', 'DS202601', ?, ?, ?, ?, 'Censeur / Directeur des Études')
    ")->execute([$deanUserId, $schoolId, $schoolName, $region, $division]);

    // --- C. SEED REGIONAL DELEGATE ROW IN regional_delegates TABLE ---
    $regUserId = $createUnactivatedUser('Dr. Fouda Alphonse', 'fouda.a@minesec.cm', 'regional_delegate', 'REG202601');
    $pdo->prepare("DELETE FROM regional_delegates WHERE user_id = ? OR staff_id = 'REG202601'")->execute([$regUserId]);
    $pdo->prepare("
        INSERT INTO regional_delegates (user_id, full_name, matricule, staff_id, delegation_name, region)
        VALUES (?, 'Dr. Fouda Alphonse', 'REG202601', 'REG202601', 'Délégation Régionale de l\'Adamaoua', ?)
    ")->execute([$regUserId, $region]);

    // --- D. SEED ADMIN ROW IN admins TABLE ---
    $admUserId = $createUnactivatedUser('MINESEC Inspector General', 'admin@minesec.cm', 'admin', 'ADM202601');
    $pdo->prepare("DELETE FROM admins WHERE user_id = ? OR staff_id = 'ADM202601'")->execute([$admUserId]);
    $pdo->prepare("
        INSERT INTO admins (user_id, full_name, matricule, staff_id, title)
        VALUES (?, 'MINESEC Inspector General', 'ADM202601', 'ADM202601', 'MINESEC Inspector General')
    ")->execute([$admUserId]);

    $pdo->exec("SET FOREIGN_KEY_CHECKS = 1;");

    echo "SUCCESS: Tables created and unactivated accounts seeded for Principal, Dean of Studies, Regional Delegate, and Admin.\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
