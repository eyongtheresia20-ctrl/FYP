<?php
// 1. Test get_result for user_id = 2
$ch = curl_init('http://127.0.0.1:8080/minesec_api/api/assessment.php?action=get_result&user_id=2');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
echo "=== GET RESULT USER 2 ===\n$res\n\n";

// 2. Test submit_assessment for user_id = 2
$payload = json_encode([
    'user_id' => 2,
    'answers' => [1, 2, 3, 4, 1, 2, 3, 4, 1, 2],
]);
$ch = curl_init('http://127.0.0.1:8080/minesec_api/api/assessment.php?action=submit_assessment');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$res = curl_exec($ch);
echo "=== SUBMIT ASSESSMENT USER 2 ===\n$res\n\n";

// 3. Test get_result again for user_id = 2
$ch = curl_init('http://127.0.0.1:8080/minesec_api/api/assessment.php?action=get_result&user_id=2');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
echo "=== GET RESULT USER 2 AFTER SUBMIT ===\n$res\n\n";
