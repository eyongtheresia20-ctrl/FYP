<?php
// ============================================================
//  MINESEC LST — Database Configuration
// ============================================================

define('DB_HOST',     'localhost');
define('DB_PORT',     '3306');
define('DB_USER',     'root');
define('DB_PASS',     '');        // Default XAMPP root has no password
define('DB_CHARSET',  'utf8mb4');

function getDB(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        // Primary database: minesec_lst
        $databases = ['minesec_lst', 'school_bd'];
        $connected = false;

        foreach ($databases as $dbName) {
            try {
                $dsn = sprintf('mysql:host=%s;port=%s;dbname=%s;charset=%s', DB_HOST, DB_PORT, $dbName, DB_CHARSET);
                $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                    PDO::ATTR_EMULATE_PREPARES   => false,
                ]);
                $connected = true;
                break;
            } catch (PDOException $e) {
                continue;
            }
        }

        if (!$connected) {
            // Fallback connection without DB to create one if needed
            $dsn = sprintf('mysql:host=%s;port=%s;charset=%s', DB_HOST, DB_PORT, DB_CHARSET);
            $pdo = new PDO($dsn, DB_USER, DB_PASS, [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]);
        }
    }
    return $pdo;
}
