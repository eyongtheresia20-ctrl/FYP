<?php
$_GET['action'] = 'admin_analytics';
$_GET['user_id'] = '1';

ob_start();
require 'backend/api/dashboard.php';
$output = ob_get_clean();

$data = json_decode($output, true);
echo "Hierarchy for SUD-OUEST:\n";
foreach ($data['data']['national_hierarchy'] ?? [] as $reg) {
    if ($reg['name'] === 'SUD-OUEST') {
        print_r($reg);
    }
}
