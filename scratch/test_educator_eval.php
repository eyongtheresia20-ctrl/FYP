<?php
require_once 'c:/Users/COUNTESS/Desktop/FYP/backend/services/vark_academic_engine.php';

echo "=== TEST 1: Lycée Technique (Auditory=2, Visual=0, Kinesthetic=0, Read/Write=0) ===\n";
$res1 = VarkAcademicEngine::evaluateForEducators(2, 0, 0, 0, 'LYCEE TECHNIQUE DE NGAOUNDAL');
echo $res1['recommendation_en'] . "\n\n";

echo "=== TEST 2: Future School with Auditory=2, Visual=1 ===\n";
$res2 = VarkAcademicEngine::evaluateForEducators(2, 1, 0, 0, 'LYCEE BILINGUE DE NGAOUNDAL');
echo $res2['recommendation_en'] . "\n\n";
