<?php
// Test 1: Get Profile
$ch = curl_init('http://127.0.0.1:8080/minesec_api/api/auth.php?action=get_profile&user_id=8');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
echo "=== GET PROFILE USER 2 ===\n$res\n\n";

// Test 2: Update Profile
$payload = json_encode([
    'user_id'       => 2,
    'full_name'     => 'Bello Oumarou',
    'password'      => 'password123',
    'security_code' => '1234',
    'class_name'    => '1ère TI',
    'birth_date'    => '2007-03-12'
]);
$ch = curl_init('http://127.0.0.1:8080/minesec_api/api/auth.php?action=update_profile');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$res = curl_exec($ch);
echo "=== UPDATE PROFILE USER 2 ===\n$res\n\n";
