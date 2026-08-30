<?php
require_once 'c:/Users/COUNTESS/Desktop/FYP/backend/config/database.php';
$pdo = getDB();

$stmtVark = $pdo->query("
    SELECT 
        COUNT(DISTINCT st.id) AS assessed,
        SUM(CASE WHEN latest_a.learning_style LIKE '%Visual%' THEN 1 ELSE 0 END) AS visual,
        SUM(CASE WHEN latest_a.learning_style LIKE '%Auditory%' THEN 1 ELSE 0 END) AS auditory,
        SUM(CASE WHEN latest_a.learning_style LIKE '%Kinesthetic%' THEN 1 ELSE 0 END) AS kinesthetic,
        SUM(CASE WHEN latest_a.learning_style LIKE '%Read%' THEN 1 ELSE 0 END) AS rw_count
    FROM students st
    JOIN (
        SELECT a1.student_id, a1.learning_style
        FROM assessments a1
        INNER JOIN (
            SELECT student_id, MAX(id) as max_id
            FROM assessments
            GROUP BY student_id
        ) a2 ON a1.id = a2.max_id
    ) latest_a ON latest_a.student_id = st.id
");
$vark = $stmtVark->fetch(PDO::FETCH_ASSOC);
print_r($vark);
