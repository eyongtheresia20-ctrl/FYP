<?php
// ============================================================
//  MINESEC LST — Assessment & Results API
//  MINESEC Learning Style Test (L.S.T / T.S.A)
// ============================================================

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once __DIR__ . '/../config/database.php';

function respond($success, $message, $data = [], $code = 200) {
    http_response_code($code);
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data'    => $data
    ]);
    exit();
}

function respondError($message, $code = 400) {
    respond(false, $message, [], $code);
}

$action = $_GET['action'] ?? '';
$pdo    = getDB();

if ($action === 'submit_assessment') {
    $raw  = file_get_contents('php://input');
    $body = json_decode($raw, true);

    $studentUserId = $body['user_id'] ?? null;
    $answers       = $body['answers'] ?? []; // Array of 10 integers (1, 2, 3, or 4)
    $feedback      = $body['feedback'] ?? [];

    if (!$studentUserId) respondError('User ID is required.');
    if (count($answers) < 10) respondError('All 10 questions must be answered.');

    // Find student_id from users table
    $stmt = $pdo->prepare("SELECT id FROM students WHERE user_id = ?");
    $stmt->execute([$studentUserId]);
    $studentId = $stmt->fetchColumn();

    if (!$studentId) respondError('Student profile not found.', 404);

    // Calculate score counts
    // 1 = Auditory, 2 = Visual, 3 = Kinesthetic, 4 = Read/Write
    $auditory    = 0;
    $visual      = 0;
    $kinesthetic = 0;
    $readWrite   = 0;

    foreach ($answers as $ans) {
        $val = intval($ans);
        if ($val === 1) $auditory++;
        else if ($val === 2) $visual++;
        else if ($val === 3) $kinesthetic++;
        else if ($val === 4) $readWrite++;
    }

    // Percentages out of 10
    $vPct = ($visual / 10) * 100;
    $aPct = ($auditory / 10) * 100;
    $kPct = ($kinesthetic / 10) * 100;
    $rPct = ($readWrite / 10) * 100;

    // Determine primary learning style
    $scores = [
        'Auditory'    => $auditory,
        'Visual'      => $visual,
        'Kinesthetic' => $kinesthetic,
        'Read/Write'  => $readWrite,
    ];

    arsort($scores);
    $topScore = reset($scores);
    $topStyles = [];
    foreach ($scores as $style => $score) {
        if ($score === $topScore) {
            $topStyles[] = $style;
        }
    }

    $primaryStyle = (count($topStyles) > 1) 
        ? implode('-', $topStyles) . ' (Dual Style)'
        : $topStyles[0];

    // Insert assessment record
    $stmt = $pdo->prepare("
        INSERT INTO assessments (student_id, visual_score, auditory_score, kinesthetic_score, read_write_score, learning_style, completed_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ");
    $stmt->execute([$studentId, $vPct, $aPct, $kPct, $rPct, $primaryStyle]);
    $assessmentId = $pdo->lastInsertId();

    // AI Recommendation generator
    $aiRecommendations = generateAIRecommendations($primaryStyle, $visual, $auditory, $kinesthetic, $readWrite);

    // Insert or update results table
    $stmt = $pdo->prepare("
        INSERT INTO results (student_id, assessment_id, learning_style, summary_en, summary_fr)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
            assessment_id = VALUES(assessment_id),
            learning_style = VALUES(learning_style),
            summary_en = VALUES(summary_en),
            summary_fr = VALUES(summary_fr)
    ");
    $stmt->execute([
        $studentId,
        $assessmentId,
        $primaryStyle,
        $aiRecommendations['en'],
        $aiRecommendations['fr']
    ]);

    respond(true, 'Assessment submitted successfully.', [
        'assessment_id'    => $assessmentId,
        'learning_style'   => $primaryStyle,
        'scores' => [
            'visual'      => $vPct,
            'auditory'    => $aPct,
            'kinesthetic' => $kPct,
            'read_write'  => $rPct,
        ],
        'counts' => [
            'visual'      => $visual,
            'auditory'    => $auditory,
            'kinesthetic' => $kinesthetic,
            'read_write'  => $readWrite,
        ],
        'recommendations' => $aiRecommendations
    ]);

} else if ($action === 'get_result' || $action === 'get_student_result') {
    $paramId = $_GET['user_id'] ?? $_GET['student_id'] ?? null;
    if (!$paramId) respondError('User ID or Student ID is required.');

    $stmt = $pdo->prepare("SELECT id FROM students WHERE user_id = ? OR id = ?");
    $stmt->execute([$paramId, $paramId]);
    $studentId = $stmt->fetchColumn();

    if (!$studentId) respondError('Student profile not found.', 404);

    // Fetch ALL assessments for this student
    $stmtAll = $pdo->prepare("
        SELECT a.id, a.visual_score, a.auditory_score, a.kinesthetic_score, a.read_write_score, 
               a.learning_style, r.summary_en, r.summary_fr, a.completed_at
        FROM assessments a
        LEFT JOIN results r ON r.assessment_id = a.id
        WHERE a.student_id = ?
        ORDER BY a.completed_at DESC, a.id DESC
    ");
    $stmtAll->execute([$studentId]);
    $allAssessments = $stmtAll->fetchAll(PDO::FETCH_ASSOC);

    if (empty($allAssessments)) {
        respond(true, 'No assessment completed yet.', ['completed' => false, 'history' => []]);
    }

    // Calculate COMPOSITE (Average across all attempts)
    $totalAttempts = count($allAssessments);
    $sumV = 0; $sumA = 0; $sumK = 0; $sumR = 0;
    $historyList = [];

    foreach ($allAssessments as $ass) {
        $v = floatval($ass['visual_score']);
        $a = floatval($ass['auditory_score']);
        $k = floatval($ass['kinesthetic_score']);
        $r = floatval($ass['read_write_score']);

        $sumV += $v;
        $sumA += $a;
        $sumK += $k;
        $sumR += $r;

        $historyList[] = [
            'id'             => intval($ass['id']),
            'learning_style' => $ass['learning_style'],
            'scores'         => ['visual' => $v, 'auditory' => $a, 'kinesthetic' => $k, 'read_write' => $r],
            'summary_en'     => $ass['summary_en'] ?? '',
            'summary_fr'     => $ass['summary_fr'] ?? '',
            'completed_at'   => $ass['completed_at'],
        ];
    }

    $avgV = round($sumV / $totalAttempts, 1);
    $avgA = round($sumA / $totalAttempts, 1);
    $avgK = round($sumK / $totalAttempts, 1);
    $avgR = round($sumR / $totalAttempts, 1);

    // Determine composite primary learning style from averaged percentages
    $avgScores = [
        'Auditory'    => $avgA,
        'Visual'      => $avgV,
        'Kinesthetic' => $avgK,
        'Read/Write'  => $avgR,
    ];
    arsort($avgScores);
    $topAvgScore = reset($avgScores);
    $topAvgStyles = [];
    foreach ($avgScores as $stName => $stScore) {
        if ($stScore === $topAvgScore) {
            $topAvgStyles[] = $stName;
        }
    }
    $compositeStyle = (count($topAvgStyles) > 1)
        ? implode('-', $topAvgStyles) . ' (Dual Style)'
        : $topAvgStyles[0];

    $compositeRec = generateAIRecommendations($compositeStyle, $avgV, $avgA, $avgK, $avgR);

    // Trend analysis across multiple test attempts
    $trendEn = "";
    $trendFr = "";
    if ($totalAttempts > 1) {
        $firstAttempt  = $allAssessments[$totalAttempts - 1];
        $latestAttempt = $allAssessments[0];
        $latestStyle   = $latestAttempt['learning_style'];
        $firstStyle    = $firstAttempt['learning_style'];

        if ($latestStyle === $firstStyle) {
            $trendEn = "Over your $totalAttempts test attempts, your dominant learning style has remained consistently $latestStyle. You demonstrate a clear and well-established learning preference.";
            $trendFr = "Au fil de vos $totalAttempts tentatives, votre style d'apprentissage dominant est resté constamment $latestStyle. Vous présentez une préférence d'apprentissage claire et affirmée.";
        } else {
            $trendEn = "Across your $totalAttempts test attempts, your dominant learning style evolved from $firstStyle to $latestStyle. This indicates developing versatility and adapting your study habits to new subject demands.";
            $trendFr = "Au cours de vos $totalAttempts tentatives, votre style d'apprentissage dominant a évolué de $firstStyle à $latestStyle. Cela indique une grande adaptabilité de vos méthodes d'étude.";
        }
    }

    $latest = $allAssessments[0];

    respond(true, 'Assessment results fetched successfully.', [
        'completed'      => true,
        'attempt_count'  => $totalAttempts,
        'learning_style' => $latest['learning_style'],
        'scores' => [
            'visual'      => floatval($latest['visual_score']),
            'auditory'    => floatval($latest['auditory_score']),
            'kinesthetic' => floatval($latest['kinesthetic_score']),
            'read_write'  => floatval($latest['read_write_score']),
        ],
        'summary_en'     => $latest['summary_en'] ?? '',
        'summary_fr'     => $latest['summary_fr'] ?? '',
        'completed_at'   => $latest['completed_at'],

        // Composite multi-attempt recommendation & averages
        'composite' => [
            'learning_style'  => $compositeStyle,
            'scores' => [
                'visual'      => $avgV,
                'auditory'    => $avgA,
                'kinesthetic' => $avgK,
                'read_write'  => $avgR,
            ],
            'recommendations' => $compositeRec,
            'trend_en'        => $trendEn,
            'trend_fr'        => $trendFr,
        ],

        // Full history of all attempts
        'history' => $historyList
    ]);

} else {
    respondError('Invalid action.', 404);
}

function generateAIRecommendations($style, $v = 0, $a = 0, $k = 0, $r = 0) {
    $recEn = "";
    $recFr = "";

    if (str_contains($style, 'Auditory')) {
        $recEn .= "• Listen to recorded lectures and podcasts.\n• Read your notes aloud or explain concepts to a study partner.\n• Use rhythmic memory devices and rhymes to remember formulas.";
        $recFr .= "• Écoutez les cours enregistrés et les podcasts.\n• Lisez vos notes à voix haute ou expliquez les concepts à un camarade.\n• Utilisez des répétitions rythmiques et des rimes pour mémoriser.";
    } 
    if (str_contains($style, 'Visual')) {
        if ($recEn != "") { $recEn .= "\n\n"; $recFr .= "\n\n"; }
        $recEn .= "• Use color-coded highlighters, mind maps, and diagrams.\n• Watch educational video tutorials and visual demonstrations.\n• Visualize concepts in your mind when recalling notebook pages.";
        $recFr .= "• Utilisez du surlignage couleur, des cartes mentales et des diagrammes.\n• Regardez des tutoriels vidéo éducatifs et des démonstrations visuelles.\n• Visualisez les pages de votre cahier dans votre esprit.";
    } 
    if (str_contains($style, 'Kinesthetic')) {
        if ($recEn != "") { $recEn .= "\n\n"; $recFr .= "\n\n"; }
        $recEn .= "• Study while walking around the room or holding stress objects.\n• Participate in practical experiments, role-play, and hands-on activities.\n• Take short active breaks between study sessions.";
        $recFr .= "• Étudiez en marchant dans la pièce ou en manipulant un objet.\n• Participez aux travaux pratiques, jeux de rôle et activités manuelles.\n• Prenez de courtes pauses actives entre les sessions d'étude.";
    } 
    if (str_contains($style, 'Read/Write')) {
        if ($recEn != "") { $recEn .= "\n\n"; $recFr .= "\n\n"; }
        $recEn .= "• Write detailed summaries and re-write key points in your own words.\n• Create lists, glossaries, and flashcards for formulas and terms.\n• Read textbooks silently and take structured bulleted notes.";
        $recFr .= "• Rédigez des résumés détaillés et réécrivez les points clés avec vos propres mots.\n• Créez des listes, glossaires et fiches pour les formules et termes.\n• Lisez vos manuels en silence et prenez des notes structurées.";
    }

    return ['en' => $recEn, 'fr' => $recFr];
}

