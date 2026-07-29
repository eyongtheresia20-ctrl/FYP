<?php
// Test Teacher Activation via API logic

require_once __DIR__ . '/config/database.php';

$pdo = getDB();

// 1. Test check_matricule for teacher T2026001
$matricule = 'T2026001';
$stmt = $pdo->prepare("
    SELECT u.id, u.full_name, u.role, u.is_activated, u.school_id, u.region, u.division,
           t.subject, t.staff_id, sc.name AS school_name
    FROM teachers t
    JOIN users u ON u.id = t.user_id
    LEFT JOIN schools sc ON sc.id = u.school_id
    WHERE t.staff_id = ?
");
$stmt->execute([$matricule]);
$teacher = $stmt->fetch();

echo "--- STEP 1: CHECK MATRICULE ---\n";
print_r($teacher);

// 2. Perform Activation: Teacher sets password 'teacherPass2026' and PIN '9876'
$passHash = hash('sha256', 'teacherPass2026');
$pinHash  = hash('sha256', '9876');

$pdo->prepare("UPDATE users SET password_hash = ?, security_code = ?, is_activated = 1, activated_at = NOW() WHERE id = ?")
    ->execute([$passHash, $pinHash, $teacher['id']]);
$pdo->prepare("UPDATE teachers SET password_hash = ?, security_code = ? WHERE user_id = ?")
    ->execute([$passHash, $pinHash, $teacher['id']]);

echo "\n--- STEP 2: TEACHER ACTIVATED ---\n";
$stmt = $pdo->prepare("SELECT u.full_name, u.is_activated, u.password_hash, u.security_code FROM users u WHERE u.id = ?");
$stmt->execute([$teacher['id']]);
print_r($stmt->fetch());

echo "\nActivation Test Completed Successfully!\n";
