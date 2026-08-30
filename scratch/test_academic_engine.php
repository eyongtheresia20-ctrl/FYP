<?php
require_once 'c:/Users/COUNTESS/Desktop/FYP/backend/services/vark_academic_engine.php';

echo "--- TEST 1: Uni-modal Auditory (Auditory=5, Visual=1, Kinesthetic=0, Read/Write=0) ---\n";
$res1 = VarkAcademicEngine::evaluate(5, 1, 0, 0);
print_r($res1);

echo "\n--- TEST 2: Bi-modal (Auditory=5, Read/Write=5) ---\n";
$res2 = VarkAcademicEngine::evaluate(5, 0, 0, 5);
print_r($res2);

echo "\n--- TEST 3: Tri-modal (Visual=3, Kinesthetic=3, Read/Write=3) ---\n";
$res3 = VarkAcademicEngine::evaluate(0, 3, 3, 3);
print_r($res3);

echo "\n--- TEST 4: Quad-modal (2, 2, 2, 2) ---\n";
$res4 = VarkAcademicEngine::evaluate(2, 2, 2, 2);
print_r($res4);
