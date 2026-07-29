<?php
// ============================================================
//  MINESEC LST — Setup Regions, Divisions & Delegates Tables
// ============================================================

require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- CREATING REGIONS & DIVISIONS TABLES ---\n";

    // 1. REGIONS TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS regions (
            id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            code      VARCHAR(10)  NOT NULL UNIQUE,
            name_en   VARCHAR(100) NOT NULL,
            name_fr   VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 2. DIVISIONS TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS divisions (
            id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            region_id INT UNSIGNED NOT NULL,
            code      VARCHAR(20)  NOT NULL UNIQUE,
            name_en   VARCHAR(100) NOT NULL,
            name_fr   VARCHAR(100) NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (region_id) REFERENCES regions(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    // 3. DELEGATES TABLE
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS delegates (
            id            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
            user_id       INT UNSIGNED NOT NULL UNIQUE,
            delegate_type ENUM('regional', 'divisional') NOT NULL,
            region_id     INT UNSIGNED NULL,
            division_id   INT UNSIGNED NULL,
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id)     REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (region_id)   REFERENCES regions(id) ON DELETE SET NULL,
            FOREIGN KEY (division_id) REFERENCES divisions(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ");

    echo "Tables created successfully.\n";

    // 4. SEED THE 10 REGIONS OF CAMEROON
    $regionsData = [
        ['AD', 'Adamawa',     'Adamaoua'],
        ['CE', 'Center',      'Centre'],
        ['ES', 'East',        'Est'],
        ['EN', 'Far North',   'Extrême-Nord'],
        ['LT', 'Littoral',    'Littoral'],
        ['NO', 'North',       'Nord'],
        ['NW', 'North-West',  'Nord-Ouest'],
        ['OU', 'West',        'Ouest'],
        ['SU', 'South',       'Sud'],
        ['SW', 'South-West',  'Sud-Ouest'],
    ];

    $stmtRegion = $pdo->prepare("
        INSERT INTO regions (code, name_en, name_fr) VALUES (?, ?, ?)
        ON DUPLICATE KEY UPDATE name_en=VALUES(name_en), name_fr=VALUES(name_fr)
    ");

    foreach ($regionsData as $r) {
        $stmtRegion->execute($r);
    }
    echo "10 Regions seeded successfully.\n";

    // Helper to get region ID by code
    $getRegionId = function($code) use ($pdo) {
        $stmt = $pdo->prepare("SELECT id FROM regions WHERE code = ?");
        $stmt->execute([$code]);
        return $stmt->fetchColumn();
    };

    // 5. SEED DIVISIONS (SAMPLE DEPARTEMENTS FOR ALL REGIONS)
    $divisionsData = [
        // Adamawa (AD)
        [$getRegionId('AD'), 'DJEREM',      'Djerem',        'Djérem'],
        [$getRegionId('AD'), 'FARO_DEO',    'Faro-et-Déo',   'Faro-et-Déo'],
        [$getRegionId('AD'), 'MAYO_BANYO',  'Mayo-Banyo',    'Mayo-Banyo'],
        [$getRegionId('AD'), 'MBERE',       'Mbere',         'Mbéré'],
        [$getRegionId('AD'), 'VINA',        'Vina',          'Vina'],

        // Center (CE)
        [$getRegionId('CE'), 'MFOUNDI',     'Mfoundi',       'Mfoundi'],
        [$getRegionId('CE'), 'MEFOU_AFAMBA','Mefou-et-Afamba','Méfou-et-Afamba'],
        [$getRegionId('CE'), 'NYONG_SOO',   'Nyong-et-So\'o','Nyong-et-So\'o'],

        // Littoral (LT)
        [$getRegionId('LT'), 'WOURI',       'Wouri',         'Wouri'],
        [$getRegionId('LT'), 'SANAGA_MAR',  'Sanaga-Maritime','Sanaga-Maritime'],

        // North-West (NW)
        [$getRegionId('NW'), 'MEZAM',       'Mezam',         'Mezam'],
        [$getRegionId('NW'), 'BUI',         'Bui',           'Bui'],

        // South-West (SW)
        [$getRegionId('SW'), 'FAKO',        'Fako',          'Fako'],
        [$getRegionId('SW'), 'MEME',        'Meme',          'Meme'],
    ];

    $stmtDiv = $pdo->prepare("
        INSERT INTO divisions (region_id, code, name_en, name_fr) VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE name_en=VALUES(name_en), name_fr=VALUES(name_fr)
    ");

    foreach ($divisionsData as $d) {
        if ($d[0]) {
            $stmtDiv->execute($d);
        }
    }
    echo "Divisions seeded successfully.\n";

    echo "--- SETUP COMPLETE --- \n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
