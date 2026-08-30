import shutil

with open(r'backend/api/admin.php', 'r', encoding='utf-8') as f:
    text = f.read()

# Add require for VarkAcademicEngine
old_req = "require_once __DIR__ . '/../config/database.php';"
new_req = "require_once __DIR__ . '/../config/database.php';\nrequire_once __DIR__ . '/../services/vark_academic_engine.php';"

if old_req in text and "vark_academic_engine.php" not in text:
    text = text.replace(old_req, new_req, 1)

# In get_school_details: evaluate using VarkAcademicEngine
old_school_eval = """        $aiRecEn = "• Institutional Policy Directive for {$schoolName}: Coordinate with head teachers to complete VARK diagnostics and allocate audio-visual tools across all departments.\\n• Pedagogical Supervision: Conduct quarterly assessments to ensure auditory and visual learners receive balanced instruction.";
        $aiRecFr = "• Directive Institutionnelle pour {$schoolName} : Coordonnez avec les proviseurs pour finaliser les tests VARK et allouer du matériel audio-visuel.\\n• Supervision Pédagogique : Réalisez des bilans trimestriels pour assurer un enseignement multimodal adapté.";

        if ($assessed > 0) {
            if ($audCount >= $visCount && $audCount >= $kinCount && $audCount >= $rwCount) {
                $aiRecEn = "• Prioritize audio-visual equipment, public address systems, and recorded lecture archives for {$schoolName}.\\n• Organize school-wide debate competitions and verbal presentation seminars.";
                $aiRecFr = "• Priorisez les équipements audio-visuels, sonorisation et archives de cours pour {$schoolName}.\\n• Organisez des concours de débats et séminaires d'expression orale.";
            } elseif ($visCount >= $audCount && $visCount >= $kinCount && $visCount >= $rwCount) {
                $aiRecEn = "• Equip school libraries and classrooms with visual charts, projectors, and digital slide resources for {$schoolName}.\\n• Deploy infographic learning modules across science and technical departments.";
                $aiRecFr = "• Équipez les bibliothèques et salles de projecteurs et supports visuels pour {$schoolName}.\\n• Déployez des modules infographiques dans les départements scientifiques et techniques.";
            }
        }"""

new_school_eval = """        if ($assessed > 0) {
            $eval = VarkAcademicEngine::evaluate($audCount, $visCount, $kinCount, $rwCount);
            $aiRecEn = "• Institutional Academic Diagnosis ({$schoolName}): Dominant profile is {$eval['learning_style']} ({$eval['primary_category_name_en']}).\\n" .
                       "• Academic Prospects: {$eval['prospects_summary_en']}\\n\\n" .
                       $eval['learning_strategy_en'];

            $aiRecFr = "• Diagnostic Pédagogique Institutionnel ({$schoolName}) : Profil dominant {$eval['learning_style']} ({$eval['primary_category_name_fr']}).\\n" .
                       "• Perspectives Académiques : {$eval['prospects_summary_fr']}\\n\\n" .
                       $eval['learning_strategy_fr'];
        } else {
            $aiRecEn = "• Multimodal Diagnostic Phase: Diagnostic VARK assessments are in progress for {$schoolName}. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.";
            $aiRecFr = "• Phase Diagnostique Multimodale : Les évaluations diagnostiques VARK sont en cours pour {$schoolName}. Encouragez équitablement tous les styles d'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.";
        }"""

text = text.replace(old_school_eval, new_school_eval)

with open(r'backend/api/admin.php', 'w', encoding='utf-8') as f:
    f.write(text)

shutil.copy2(r'backend/api/admin.php', r'd:/xammp/htdocs/minesec_api/api/admin.php')
print("SUCCESSFULLY SYNCED ADMIN.PHP WITH NEIL FLEMING ACADEMIC ENGINE")
