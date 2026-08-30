<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
require_once __DIR__ . '/config/database.php';

try {
    $db = getDB();

    // Add matricule column if missing
    try {
        $db->exec("ALTER TABLE users ADD COLUMN matricule VARCHAR(100) DEFAULT NULL");
    } catch (Exception $e) {}

    // 1. Setup Students: Bello Oumarou (AD2026001) & Amina Mohamadou (AD2026002)
    $passHashBello = hash('sha256', 'maru444t');
    $secCodeBello  = '1234';
    $db->exec("UPDATE users SET password_hash = '$passHashBello', security_code = '$secCodeBello', is_activated = 1 WHERE matricule = 'AD2026001' OR id = 9");
    $db->exec("UPDATE students SET password_hash = '$passHashBello', security_code = '$secCodeBello' WHERE mat_number = 'AD2026001' OR matricule = 'AD2026001'");

    $passHashAmina = hash('sha256', 'amina123');
    $secCodeAmina  = '1234';
    $db->exec("UPDATE users SET password_hash = '$passHashAmina', security_code = '$secCodeAmina', is_activated = 1 WHERE id = 10 OR full_name LIKE '%Amina%'");
    $db->exec("UPDATE students SET password_hash = '$passHashAmina', security_code = '$secCodeAmina' WHERE mat_number = 'AD2026002' OR user_id = 10");

    // 2. Setup Teacher: M. Nguene Jacques (T2026001 / TCH2026001)
    $passHashTeacher = hash('sha256', 'teacher1');
    $secCodeTeacher  = '1234@';
    $db->exec("UPDATE users SET password_hash = '$passHashTeacher', security_code = '$secCodeTeacher', is_activated = 1, matricule = 'T2026001' WHERE id = 8 OR role = 'teacher'");
    $db->exec("UPDATE teachers SET password_hash = '$passHashTeacher', security_code = '$secCodeTeacher' WHERE matricule = 'T2026001' OR user_id = 8");

    // 3. Setup Principal: Mme. Etoa Christine (P2026001) - UNACTIVATED
    $db->exec("UPDATE users SET school_id = 1, password_hash = NULL, security_code = NULL, is_activated = 0, matricule = 'P2026001' WHERE id = 11 OR role = 'principal'");
    $db->exec("UPDATE principals SET school_id = 1, full_name = 'Mme. Etoa Christine', matricule = 'P2026001', staff_id = 'P2026001', password_hash = NULL, security_code = NULL WHERE staff_id = 'P2026001' OR user_id = 11");

    // 4. Setup Dean of Studies: M. Bikoi Joseph (DS202601) - UNACTIVATED
    $db->exec("UPDATE users SET school_id = 1, password_hash = NULL, security_code = NULL, is_activated = 0, matricule = 'DS202601', role = 'dean_of_studies' WHERE id = 12 OR role = 'dean_of_studies' OR role = 'divisional_delegate'");
    $db->exec("UPDATE dean_of_studies SET school_id = 1, full_name = 'M. Bikoi Joseph', matricule = 'DS202601', staff_id = 'DS202601', password_hash = NULL, security_code = NULL WHERE staff_id = 'DS202601' OR user_id = 12");

    // Clean up duplicate school row 7 if it exists
    $db->exec("DELETE FROM schools WHERE id = 7 OR code = 'LT_NGAOUNDAL'");

    // Assign sample teaching classes for Dean of Studies & Principal in teacher_classes table
    $db->exec("INSERT IGNORE INTO teacher_classes (teacher_id, school_id, class_name) VALUES (12, 1, '1ère TI')");
    $db->exec("INSERT IGNORE INTO teacher_classes (teacher_id, school_id, class_name) VALUES (11, 1, 'Terminale TI')");

    // 5. Setup Regional Delegate: Dr. Fouda Alphonse (REG202601 / RD2026001)
    $passHashReg = hash('sha256', 'regional1');
    $secCodeReg  = '123456@';
    $db->exec("UPDATE users SET password_hash = '$passHashReg', security_code = '$secCodeReg', is_activated = 1, matricule = 'REG202601' WHERE id = 13 OR role = 'regional_delegate'");

    // 6. Setup MINESEC Admin: MINESEC Inspector General (ADM202601)
    $passHashAdmin = hash('sha256', 'admin1');
    $secCodeAdmin  = '1234#';
    $db->exec("UPDATE users SET password_hash = '$passHashAdmin', security_code = '$secCodeAdmin', is_activated = 1, matricule = 'ADM202601' WHERE id = 14 OR role = 'admin'");
    $db->exec("UPDATE admins SET password_hash = '$passHashAdmin', security_code = '$secCodeAdmin' WHERE matricule = 'ADM202601' OR user_id = 14");

    echo json_encode([
        'success' => true,
        'message' => 'All actor credentials updated successfully in database.',
        'credentials' => [
            'teacher' => ['matricule' => 'T2026001', 'password' => 'teacher1', 'security_code' => '1234@'],
            'student_bello' => ['matricule' => 'AD2026001', 'password' => 'maru444t', 'security_code' => '1234'],
            'principal' => ['matricule' => 'P2026001', 'password' => 'principal1', 'security_code' => '12345'],
            'dean_of_studies' => ['matricule' => 'DS202601', 'password' => 'dean1', 'security_code' => '123456'],
            'regional_delegate' => ['matricule' => 'REG202601', 'password' => 'regional1', 'security_code' => '123456@'],
            'admin' => ['matricule' => 'ADM202601', 'password' => 'admin1', 'security_code' => '1234#'],
        ]
    ], JSON_PRETTY_PRINT);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
