<?php
$ch = curl_init('http://localhost:8080/minesec_api/api/dashboard.php?action=principal_school&principal_id=11');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
echo "Principal API: " . curl_exec($ch) . "\n\n";

curl_setopt($ch, CURLOPT_URL, 'http://localhost:8080/minesec_api/api/dashboard.php?action=divisional_analytics&user_id=12');
echo "Divisional API: " . curl_exec($ch) . "\n\n";

curl_setopt($ch, CURLOPT_URL, 'http://localhost:8080/minesec_api/api/dashboard.php?action=regional_analytics&user_id=13');
echo "Regional API: " . curl_exec($ch) . "\n\n";

curl_setopt($ch, CURLOPT_URL, 'http://localhost:8080/minesec_api/api/dashboard.php?action=admin_analytics&user_id=14');
echo "Admin API: " . curl_exec($ch) . "\n";
