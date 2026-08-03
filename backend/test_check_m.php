<?php
$ch = curl_init('http://localhost:8080/minesec_api/api/auth.php?action=check_matricule');
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['matricule' => 'P2026001']));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
echo "P2026001 Result: " . $res . "\n";

curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['matricule' => 'DD2026001']));
echo "DD2026001 Result: " . curl_exec($ch) . "\n";

curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['matricule' => 'RD2026001']));
echo "RD2026001 Result: " . curl_exec($ch) . "\n";

curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode(['matricule' => 'ADMIN2026']));
echo "ADMIN2026 Result: " . curl_exec($ch) . "\n";
