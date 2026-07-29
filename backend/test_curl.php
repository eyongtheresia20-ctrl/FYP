<?php
$ch = curl_init('http://127.0.0.1:8080/minesec_api/api/auth.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
$err = curl_error($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
echo "HTTP Code: $code\n";
echo "Curl Error: $err\n";
echo "Response: " . substr($res, 0, 300) . "\n";
