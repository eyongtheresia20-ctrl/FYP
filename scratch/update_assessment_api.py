import shutil
import os

# Create services directory in XAMPP
os.makedirs(r'd:/xammp/htdocs/minesec_api/services', exist_ok=True)
shutil.copy2(r'backend/services/vark_academic_engine.php', r'd:/xammp/htdocs/minesec_api/services/vark_academic_engine.php')

with open(r'backend/api/assessment.php', 'r', encoding='utf-8') as f:
    code = f.read()

# Replace the AI recommendation logic with VarkAcademicEngine
old_require = "require_once __DIR__ . '/../config/database.php';"
new_require = "require_once __DIR__ . '/../config/database.php';\nrequire_once __DIR__ . '/../services/vark_academic_engine.php';"

code = code.replace(old_require, new_require, 1)

old_submit_logic = """    // Percentages out of 10
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
    ]);"""

new_submit_logic = """    // Exact percentages
    $totalQuestions = count($answers);
    if ($totalQuestions <= 0) $totalQuestions = 10;

    $vPct = round(($visual / $totalQuestions) * 100);
    $aPct = round(($auditory / $totalQuestions) * 100);
    $kPct = round(($kinesthetic / $totalQuestions) * 100);
    $rPct = round(($readWrite / $totalQuestions) * 100);

    // Evaluate with Neil Fleming Standardized Academic Engine (Tables 3, 4, 5, 6 & Section 4.5.1)
    $eval = VarkAcademicEngine::evaluate($auditory, $visual, $kinesthetic, $readWrite);
    $primaryStyle = $eval['learning_style'];

    // Insert assessment record
    $stmt = $pdo->prepare("
        INSERT INTO assessments (student_id, visual_score, auditory_score, kinesthetic_score, read_write_score, learning_style, completed_at)
        VALUES (?, ?, ?, ?, ?, ?, NOW())
    ");
    $stmt->execute([$studentId, $vPct, $aPct, $kPct, $rPct, $primaryStyle]);
    $assessmentId = $pdo->lastInsertId();

    // Insert or update results table with exact Neil Fleming academic interpretation & strategies
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
        $eval['full_recommendation_en'],
        $eval['full_recommendation_fr']
    ]);

    respond(true, 'Assessment evaluated successfully according to Neil Fleming L.S.T Standardized Scales.', [
        'assessment_id'    => $assessmentId,
        'learning_style'   => $primaryStyle,
        'modality_type'    => $eval['modality_type'],
        'primary_category' => $eval['primary_category'],
        'primary_category_name_en' => $eval['primary_category_name_en'],
        'primary_category_name_fr' => $eval['primary_category_name_fr'],
        'prospects_summary_en'     => $eval['prospects_summary_en'],
        'prospects_summary_fr'     => $eval['prospects_summary_fr'],
        'academic_diagnostic_en'   => $eval['academic_diagnostic_en'],
        'academic_diagnostic_fr'   => $eval['academic_diagnostic_fr'],
        'learning_strategy_en'     => $eval['learning_strategy_en'],
        'learning_strategy_fr'     => $eval['learning_strategy_fr'],
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
        'recommendations' => [
            'en' => $eval['full_recommendation_en'],
            'fr' => $eval['full_recommendation_fr'],
        ]
    ]);"""

code = code.replace(old_submit_logic, new_submit_logic)

# Replace old generateAIRecommendations function with bridge to VarkAcademicEngine
old_func = """function generateAIRecommendations($style, $v = 0, $a = 0, $k = 0, $r = 0) {
    $partsEn = [];
    $partsFr = [];

    if (str_contains($style, 'Visual')) {
        $partsEn[] = "• Use color-coded highlighters, mind maps, and concept diagrams.\\n• Watch educational video tutorials, animations, and visual demonstrations.\\n• Visualize notebook pages and key formulas in your mind during study.";
        $partsFr[] = "• Utilisez du surlignage couleur, des cartes mentales et des schémas explicatifs.\\n• Regardez des tutoriels vidéo éducatifs, des animations et démonstrations visuelles.\\n• Visualisez les pages de vos cours et les formules clés dans votre esprit.";
    }
    if (str_contains($style, 'Auditory')) {
        $partsEn[] = "• Listen attentively to recorded lectures, podcasts, and verbal explanations.\\n• Read your notes aloud and explain complex concepts to a study partner.\\n• Use rhythmic memory devices, acronyms, and rhymes for memorization.";
        $partsFr[] = "• Écoutez attentivement les cours enregistrés, les podcasts et explications orales.\\n• Lisez vos notes à voix haute et expliquez les concepts clés à un camarade.\\n• Utilisez des répétitions rythmiques, des acronymes et des rimes pour mémoriser.";
    }
    if (str_contains($style, 'Kinesthetic')) {
        $partsEn[] = "• Study while walking around or holding tactile study objects (flashcards, models).\\n• Participate in hands-on experiments, practical exercises, and role-playing.\\n• Take short, active breaks (Pomodoro technique) between focused study sessions.";
        $partsFr[] = "• Étudiez en vous déplaçant ou en manipulant des supports tactiles (fiches, modèles).\\n• Participez à des travaux pratiques, des expériences et exercices d'application.\\n• Prenez de courtes pauses actives (technique Pomodoro) entre les sessions d'étude.";
    }
    if (str_contains($style, 'Read/Write')) {
        $partsEn[] = "• Write comprehensive summaries and rewrite main points in your own words.\\n• Create structured glossaries, flashcards, and lists of formulas/terms.\\n• Read textbooks silently and take structured bulleted notes.";
        $partsFr[] = "• Rédigez des résumés détaillés et réécrivez les points clés avec vos propres mots.\\n• Créez des glossaires structurés, des fiches et des listes de formules et mots-clés.\\n• Lisez les manuels en silence et prenez des notes structurées à puces.";
    }

    // Default fallback if style string didn't match standard names
    if (empty($partsEn)) {
        $partsEn[] = "• Combine visual diagrams with written summaries and active study sessions.\\n• Review core concepts regularly using interactive practice exercises.";
        $partsFr[] = "• Combinez schémas visuels, résumés écrits et sessions d'étude actives.\\n• Révisez régulièrement les concepts clés à l'aide d'exercices interactifs.";
    }

    return [
        'en' => implode("\\n\\n", $partsEn),
        'fr' => implode("\\n\\n", $partsFr)
    ];
}"""

new_func = """function generateAIRecommendations($style, $v = 0, $a = 0, $k = 0, $r = 0) {
    // Exact academic evaluation via Neil Fleming Standardized Tables
    $eval = VarkAcademicEngine::evaluate($a, $v, $k, $r);
    return [
        'en' => $eval['full_recommendation_en'],
        'fr' => $eval['full_recommendation_fr']
    ];
}"""

code = code.replace(old_func, new_func)

with open(r'backend/api/assessment.php', 'w', encoding='utf-8') as f:
    f.write(code)

shutil.copy2(r'backend/api/assessment.php', r'd:/xammp/htdocs/minesec_api/api/assessment.php')
print("SUCCESSFULLY SYNCED ASSESSMENT.PHP WITH NEIL FLEMING ACADEMIC ENGINE")
