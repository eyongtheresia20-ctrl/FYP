<?php
$ch = curl_init('http://127.0.0.1:8080/minesec_api/api/auth.php?action=matricule_login');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'matricule'     => 'AD2026001',
    'password'      => 'password123',
    'security_code' => '1234'
]));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$res = curl_exec($ch);
echo "Response: $res\n";
