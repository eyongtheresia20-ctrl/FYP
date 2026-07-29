<?php
try {
    $pdoSrc = new PDO('mysql:host=localhost;dbname=school_bd;charset=utf8mb4', 'root', '');
    $pdoDst = new PDO('mysql:host=localhost;dbname=minesec_lst;charset=utf8mb4', 'root', '');

    echo "=== Syncing school_bd data to minesec_lst ===\n";

    // 1. Ensure columns in minesec_lst
    try {
        $pdoDst->exec("ALTER TABLE assessments ADD COLUMN read_write_score DECIMAL(5,2) DEFAULT 0.00 AFTER kinesthetic_score");
    } catch (Exception $e) {}

    try {
        $pdoDst->exec("ALTER TABLE assessments ADD COLUMN questionnaire_id INT(10) UNSIGNED NULL DEFAULT 1 AFTER student_id");
    } catch (Exception $e) {}

    try {
        $pdoDst->exec("ALTER TABLE results ADD COLUMN summary_en TEXT AFTER learning_style");
    } catch (Exception $e) {}

    try {
        $pdoDst->exec("ALTER TABLE results ADD COLUMN summary_fr TEXT AFTER summary_en");
    } catch (Exception $e) {}

    // 2. Sync users activation password & security code
    $srcUsers = $pdoSrc->query("SELECT * FROM users WHERE is_activated = 1")->fetchAll();
    foreach ($srcUsers as $u) {
        $stmt = $pdoDst->prepare("
            UPDATE users SET 
                password_hash = ?, 
                security_code = ?, 
                is_activated = ?, 
                activated_at = ?
            WHERE full_name = ? OR email = ?
        ");
        $stmt->execute([
            $u['password_hash'],
            $u['security_code'],
            $u['is_activated'],
            $u['activated_at'],
            $u['full_name'],
            $u['email']
        ]);
        echo "Updated activation for user: {$u['full_name']}\n";
    }

    // 3. Sync assessments & results
    $srcAssessments = $pdoSrc->query("SELECT * FROM assessments")->fetchAll();
    foreach ($srcAssessments as $a) {
        // Find matching student in minesec_lst
        $srcStudent = $pdoSrc->query("SELECT * FROM students WHERE id = {$a['student_id']}")->fetch();
        if ($srcStudent) {
            $dstStudentId = $pdoDst->query("SELECT id FROM students WHERE mat_number = '{$srcStudent['mat_number']}'")->fetchColumn();
            if ($dstStudentId) {
                $stmt = $pdoDst->prepare("
                    INSERT INTO assessments (student_id, questionnaire_id, visual_score, auditory_score, kinesthetic_score, read_write_score, learning_style, completed_at)
                    VALUES (?, 1, ?, ?, ?, ?, ?, ?)
                ");
                $stmt->execute([
                    $dstStudentId,
                    $a['visual_score'],
                    $a['auditory_score'],
                    $a['kinesthetic_score'],
                    $a['read_write_score'] ?? 0,
                    $a['learning_style'],
                    $a['completed_at']
                ]);
                $newAssId = $pdoDst->lastInsertId();
                echo "Inserted assessment #{$newAssId} for student #{$dstStudentId}\n";

                // Sync matching result
                $srcResult = $pdoSrc->query("SELECT * FROM results WHERE assessment_id = {$a['id']}")->fetch();
                if ($srcResult) {
                    $stmtR = $pdoDst->prepare("
                        INSERT INTO results (student_id, assessment_id, learning_style, summary_en, summary_fr)
                        VALUES (?, ?, ?, ?, ?)
                        ON DUPLICATE KEY UPDATE 
                            assessment_id = VALUES(assessment_id),
                            learning_style = VALUES(learning_style),
                            summary_en = VALUES(summary_en),
                            summary_fr = VALUES(summary_fr)
                    ");
                    $stmtR->execute([
                        $dstStudentId,
                        $newAssId,
                        $srcResult['learning_style'],
                        $srcResult['summary_en'],
                        $srcResult['summary_fr']
                    ]);
                    echo "Inserted result for student #{$dstStudentId}\n";
                }
            }
        }
    }

    echo "\n=== Migration to minesec_lst COMPLETE! ===\n";

} catch (Exception $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
