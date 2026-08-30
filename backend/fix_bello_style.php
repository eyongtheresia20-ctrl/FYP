<?php
require_once __DIR__ . '/config/database.php';

try {
    $pdo = getDB();
    echo "--- UPDATING BELLO OUMAROU (AD2026001) TO AUDITORY ---\n";

    // 1. Update latest assessment record (id 41) to Auditory (100% Auditory)
    $stmt1 = $pdo->prepare("
        UPDATE assessments 
        SET visual_score = 0.00, 
            auditory_score = 100.00, 
            kinesthetic_score = 0.00, 
            read_write_score = 0.00, 
            learning_style = 'Auditory' 
        WHERE student_id = 9 AND id = 41
    ");
    $stmt1->execute();
    echo "• Updated assessments table (id 41) to Auditory (100%).\n";

    // 2. Update summary in results table
    $recEn = "• Listen attentively to recorded lectures, podcasts, and verbal explanations.\n• Read your notes aloud and explain complex concepts to a study partner.\n• Use rhythmic memory devices, acronyms, and rhymes for memorization.";
    $recFr = "• Écoutez attentivement les cours enregistrés, les podcasts et explications orales.\n• Lisez vos notes à voix haute et expliquez les concepts clés à un camarade.\n• Utilisez des répétitions rythmiques, des acronymes et des rimes pour mémoriser.";

    $stmt2 = $pdo->prepare("
        UPDATE results 
        SET learning_style = 'Auditory', 
            summary_en = ?, 
            summary_fr = ? 
        WHERE student_id = 9
    ");
    $stmt2->execute([$recEn, $recFr]);
    echo "• Updated results table summary for Bello to Auditory.\n";

    // 3. Print verification
    $stmtCheck = $pdo->query("
        SELECT a.id, a.student_id, a.learning_style, a.visual_score, a.auditory_score, a.completed_at 
        FROM assessments a 
        WHERE a.student_id = 9 
        ORDER BY a.completed_at DESC, a.id DESC LIMIT 1
    ");
    $latest = $stmtCheck->fetch(PDO::FETCH_ASSOC);
    echo "\n--- VERIFICATION (LATEST ASSESSMENT FOR BELLO) ---\n";
    print_r($latest);

    echo "\nSUCCESS: Bello Oumarou's dominant learning style is now AUDITORY!\n";

} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
