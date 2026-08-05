<?php
$ch = curl_init('http://192.168.1.148:8080/minesec_api/api/admin.php?action=get_all_users');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 5);
$result = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$err = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Error: $err\n";
echo "Result snippet: " . substr($result, 0, 100) . "\n";
