<?php
require_once 'backend/config/database.php';
$pdo = getDB();

// Test the query for SUD-OUEST
$regName = 'SUD-OUEST';
$stmtDivs = $pdo->prepare("
    SELECT DISTINCT division_name FROM (
        SELECT UPPER(d.code) AS division_name FROM divisions d JOIN regions r ON r.id = d.region_id WHERE UPPER(r.name_fr) = UPPER(?) OR UPPER(r.name_en) = UPPER(?) OR UPPER(r.code) = UPPER(?)
        UNION
        SELECT UPPER(division) AS division_name FROM schools WHERE UPPER(region) = UPPER(?) AND division IS NOT NULL AND division != ''
    ) AS combined_divs
    WHERE division_name IS NOT NULL AND division_name != ''
    ORDER BY division_name
");
$stmtDivs->execute([$regName, $regName, $regName, $regName]);
$divList = $stmtDivs->fetchAll(PDO::FETCH_COLUMN);

echo "Divisions for SUD-OUEST:\n";
print_r($divList);
