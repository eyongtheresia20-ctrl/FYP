<?php
require_once 'backend/config/helpers.php';
require_once 'backend/config/database.php';

$_GET['action'] = 'get_overview';
$_GET['role'] = 'admin';
$_GET['user_id'] = '1';

ob_start();
require 'backend/api/dashboard.php';
$output = ob_get_clean();

$data = json_decode($output, true);
echo "Hierarchy check for SUD-OUEST:\n";
foreach ($data['data']['national_hierarchy'] ?? [] as $reg) {
    if ($reg['name'] === 'SUD-OUEST' || $reg['name'] === 'SUD') {
        print_r($reg);
    }
}
