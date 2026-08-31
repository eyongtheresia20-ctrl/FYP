# 1. Update lib/services/vark_academic_engine.dart
with open('lib/services/vark_academic_engine.dart', 'r', encoding='utf-8') as f:
    dart_code = f.read()

old_educator_eval_dart = """    if (totalAssessed == 0) {
      if (isNationalLevel) {
        return {
          'en': "• National Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently underway nationwide across secondary and technical schools.\\n\\n"
                "• Universal Multimodal Educational Policy: All pedagogical inspectors, regional delegates, and educators must encourage and balance all 4 learning modalities equally (Visual, Auditory, Read/Write, Kinesthetic) across all academic curricula.\\n\\n"
                "• National Assessment Supervision: Mobilize regional and divisional delegations to ensure all enrolled secondary students complete their diagnostic VARK test.",
          'fr': "• Stratégie Multimodale Nationale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans l'ensemble des établissements secondaires et techniques du territoire.\\n\\n"
                "• Politique Éducative Multimodale Globale : L'ensemble des inspecteurs pédagogiques, délégués régionaux et enseignants doivent encourager équitablement les 4 modalités d'apprentissage (Visuel, Auditif, Lecture/Écriture, Kinesthésique).\\n\\n"
                "• Suivi National des Évaluations : Mobiliser les délégations régionales et départementales pour que l'ensemble des élèves complètent leur test diagnostique.",
        };
      } else if (isSchoolLevel) {
        return {
          'en': "• Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently in progress across classes in $contextName.\\n\\n"
                "• School-Wide Multimodal Instruction: Head teachers and pedagogical staff should encourage all learning styles equally by ensuring every subject incorporates verbal lectures, visual diagrams, structured texts, and practical exercises.\\n\\n"
                "• Diagnostic Supervision: Coordinate with class teachers to ensure all enrolled students complete their diagnostic VARK test.",
          'fr': "• Stratégie Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans les classes de $contextName.\\n\\n"
                "• Enseignement Multimodal Global : Les équipes pédagogiques doivent encourager équitablement tous les styles d'apprentissage en combinant explications orales, supports visuels, fiches écrites et travaux pratiques.\\n\\n"
                "• Suivi Diagnostique : Coordonnez avec les professeurs principaux pour que l'ensemble des élèves complètent leur évaluation.",
        };
      } else {
        return {
          'en': "• Multimodal Teaching Strategy (Diagnostic Phase): No students have completed the VARK assessment in $contextName yet.\\n\\n"
                "• Differentiated Classroom Engagement: Encourage and stimulate all learning styles equally through multimodal instruction—combining oral explanations, whiteboard diagrams, written notes, and hands-on exercises.\\n\\n"
                "• Assessment Coordination: Encourage all students in this class to complete their diagnostic test on the platform.",
          'fr': "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Aucun élève n'a encore complété le test VARK en $contextName.\\n\\n"
                "• Enseignement Inclusif & Équilibré : Encouragez et mobilisez équitablement tous les styles d'apprentissage (explications orales, schémas au tableau, notes écrites et exercices pratiques).\\n\\n"
                "• Coordination Diagnostique : Invitez tous les élèves de cette classe à passer leur évaluation sur la plateforme.",
        };
      }
    }"""

new_educator_eval_dart = """    if (totalAssessed == 0) {
      if (isNationalLevel) {
        return {
          'en': "• National Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently underway nationwide across secondary and technical schools.\\n\\n"
                "• Universal Multimodal Pedagogical Directives:\\n"
                "  - Kinesthetic Directives (Hands-on & Experimental): Equip classrooms and technical workshops with concrete learning kits, lab demonstrations, practical exercises, and real-world case applications to actively engage tactile learners.\\n"
                "  - Visual Directives: Incorporate structured blackboard layouts, conceptual mind maps, flowcharts, and color-coded diagrams.\\n"
                "  - Auditory Directives: Maintain clear oral explanations, structured classroom discussions, verbal lecture summaries, and Q&A sessions.\\n"
                "  - Read/Write Directives: Provide comprehensive written lesson summaries, structured definitions, glossaries, and guided textbook reading.\\n\\n"
                "• National Diagnostic Supervision: Mobilize regional and divisional delegations to ensure all enrolled secondary students complete their diagnostic VARK test.",
          'fr': "• Stratégie Multimodale Nationale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans l'ensemble des établissements secondaires et techniques du territoire.\\n\\n"
                "• Directives Pédagogiques Multimodales Globales :\\n"
                "  - Directives Kinesthésiques (Pratique & Expérimentation) : Équipez les classes et ateliers de kits pratiques, démonstrations de laboratoire, exercices d'application et études de cas réels pour mobiliser activement les apprenants tactiles.\\n"
                "  - Directives Visuelles : Intégrez des schémas structurés au tableau, cartes mentales, organigrammes et synthèses en couleurs.\\n"
                "  - Directives Auditives : Maintenez des explications orales claires, des débats en classe, des récapitulatifs verbaux et des séances de questions/réponses.\\n"
                "  - Directives Lecture/Écriture : Fournissez des résumés de cours écrits structurés, des définitions précises, des glossaires et des lectures dirigées.\\n\\n"
                "• Suivi Diagnostique National : Mobilisez les délégations régionales et départementales pour que tous les élèves complètent leur évaluation.",
        };
      } else if (isSchoolLevel) {
        return {
          'en': "• School Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently in progress across classes in $contextName.\\n\\n"
                "• School-Wide Multimodal Directives:\\n"
                "  - Kinesthetic Learning (Practical & Hands-On): Integrate interactive laboratory experiments, workshop demonstrations, tangible problem sets, and practical assignments into daily lesson planning.\\n"
                "  - Visual Learning: Utilize whiteboard schematics, visual summaries, charts, and educational media in classrooms.\\n"
                "  - Auditory Learning: Conduct interactive oral lectures, structured student debates, and verbal recaps.\\n"
                "  - Read/Write Learning: Distribute structured printed handouts, textbook reading frameworks, and revision glossaries.\\n\\n"
                "• Diagnostic Supervision: Coordinate with teachers and the Dean of Studies to ensure all enrolled students complete their diagnostic test on the platform.",
          'fr': "• Stratégie Multimodale de l'Établissement (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans les classes de $contextName.\\n\\n"
                "• Directives Multimodales pour l'Établissement :\\n"
                "  - Apprentissage Kinesthésique (Pratique & Manipulation) : Intégrez des manipulations de laboratoire, des démonstrations pratiques, des résolutions d'exercices concrets et des cas réels.\\n"
                "  - Apprentissage Visuel : Utilisez des schémas au tableau, des synthèses visuelles, des graphiques et des supports illustrés.\\n"
                "  - Apprentissage Auditif : Maintenez des explications orales interactives, des débats et des synthèses verbales régulières.\\n"
                "  - Apprentissage Lecture/Écriture : Distribuez des fiches de synthèse imprimées, des plans de cours structurés et des glossaires.\\n\\n"
                "• Suivi Diagnostique : Coordonnez avec les enseignants et le censeur pour que tous les élèves complètent leur évaluation.",
        };
      } else {
        return {
          'en': "• Multimodal Classroom Strategy (Diagnostic Phase): No students have completed the VARK assessment in $contextName yet.\\n\\n"
                "• Differentiated Multimodal Directives for the Classroom:\\n"
                "  - Kinesthetic Engagement: Incorporate hands-on problem sets, laboratory experiments, role-play activities, and physical demonstrations to actively engage practical learners.\\n"
                "  - Visual Engagement: Combine whiteboard diagrams, mind maps, and color-coded visual charts.\\n"
                "  - Auditory Engagement: Provide clear oral lectures, structured student discussions, and verbal Q&A recaps.\\n"
                "  - Read/Write Engagement: Provide concise bulleted notes, key definitions, and guided textbook reading.\\n\\n"
                "• Assessment Coordination: Encourage all students in this class to complete their diagnostic test on the platform.",
          'fr': "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Aucun élève n'a encore complété le test VARK en $contextName.\\n\\n"
                "• Directives Multimodales pour la Classe :\\n"
                "  - Engagement Kinesthésique : Intégrez des exercices pratiques, manipulations en laboratoire, démonstrations et résolutions actives de problèmes.\\n"
                "  - Engagement Visuel : Combinez schémas au tableau, cartes mentales et synthèses visuelles colorées.\\n"
                "  - Engagement Auditif : Offrez des explications orales dynamiques, des échanges structurés et des récapitulatifs verbaux.\\n"
                "  - Engagement Lecture/Écriture : Fournissez des notes à puces claires, des définitions clés et des lectures guidées.\\n\\n"
                "• Coordination Diagnostique : Invitez tous les élèves de cette classe à passer leur évaluation sur la plateforme.",
        };
      }
    }"""

if old_educator_eval_dart in dart_code:
    dart_code = dart_code.replace(old_educator_eval_dart, new_educator_eval_dart)
    print("SUCCESS: Updated evaluateForEducators in lib/services/vark_academic_engine.dart")
else:
    print("WARNING: old_educator_eval_dart not matched exact")

with open('lib/services/vark_academic_engine.dart', 'w', encoding='utf-8') as f:
    f.write(dart_code)

# 2. Update delegate_dashboard.dart line 1441 to pass isSchoolLevel: true
with open('lib/views/dashboards/delegate_dashboard.dart', 'r', encoding='utf-8') as f:
    del_code = f.read()

old_del_eval = """                                final educatorRec = VarkAcademicEngine.evaluateForEducators(
                                  auditory: scAudTotal,
                                  visual: scVisTotal,
                                  kinesthetic: scKinTotal,
                                  readWrite: scRwTotal,
                                  contextName: scName,
                                );"""

new_del_eval = """                                final educatorRec = VarkAcademicEngine.evaluateForEducators(
                                  auditory: scAudTotal,
                                  visual: scVisTotal,
                                  kinesthetic: scKinTotal,
                                  readWrite: scRwTotal,
                                  contextName: scName,
                                  isSchoolLevel: true,
                                );"""

if old_del_eval in del_code:
    del_code = del_code.replace(old_del_eval, new_del_eval)
    print("SUCCESS: Passed isSchoolLevel: true in delegate_dashboard.dart")
else:
    print("WARNING: old_del_eval not matched exact")

with open('lib/views/dashboards/delegate_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(del_code)

# 3. Update backend/services/vark_academic_engine.php
with open('backend/services/vark_academic_engine.php', 'r', encoding='utf-8') as f:
    php_code = f.read()

old_php_eval = """        if ($totalAssessed === 0) {
            if ($isNationalLevel) {
                return [
                    'en' => "• National Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently underway nationwide across secondary and technical schools.\\n\\n"
                          . "• Universal Multimodal Educational Policy: All pedagogical inspectors, regional delegates, and educators must encourage and balance all 4 learning modalities equally (Visual, Auditory, Read/Write, Kinesthetic) across all academic curricula.\\n\\n"
                          . "• National Assessment Supervision: Mobilize regional and divisional delegations to ensure all enrolled secondary students complete their diagnostic VARK test.",
                    'fr' => "• Stratégie Multimodale Nationale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans l'ensemble des établissements secondaires et techniques du territoire.\\n\\n"
                          . "• Politique Éducative Multimodale Globale : L'ensemble des inspecteurs pédagogiques, délégués régionaux et enseignants doivent encourager équitablement les 4 modalités d'apprentissage (Visuel, Auditif, Lecture/Écriture, Kinesthésique).\\n\\n"
                          . "• Suivi National des Évaluations : Mobiliser les délégations régionales et départementales pour que l'ensemble des élèves complètent leur test diagnostique."
                ];
            } else if ($isSchoolLevel) {
                return [
                    'en' => "• Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently in progress across classes in {$contextName}.\\n\\n"
                          . "• School-Wide Multimodal Instruction: Head teachers and pedagogical staff should encourage all learning styles equally by ensuring every subject incorporates verbal lectures, visual diagrams, structured texts, and practical exercises.\\n\\n"
                          . "• Diagnostic Supervision: Coordinate with class teachers to ensure all enrolled students complete their diagnostic VARK test.",
                    'fr' => "• Stratégie Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans les classes de {$contextName}.\\n\\n"
                          . "• Enseignement Multimodal Global : Les équipes pédagogiques doivent encourager équitablement tous les styles d'apprentissage en combinant explications orales, supports visuels, fiches écrites et travaux pratiques.\\n\\n"
                          . "• Suivi Diagnostique : Coordonnez avec les professeurs principaux pour que l'ensemble des élèves complètent leur évaluation."
                ];
            } else {
                return [
                    'en' => "• Multimodal Teaching Strategy (Diagnostic Phase): No students have completed the VARK assessment in {$contextName} yet.\\n\\n"
                          . "• Differentiated Classroom Engagement: Encourage and stimulate all learning styles equally through multimodal instruction—combining oral explanations, whiteboard diagrams, written notes, and hands-on exercises.\\n\\n"
                          . "• Assessment Coordination: Encourage all students in this class to complete their diagnostic test on the platform.",
                    'fr' => "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Aucun élève n'a encore complété le test VARK en {$contextName}.\\n\\n"
                          . "• Enseignement Inclusif & Équilibré : Encouragez et mobilisez équitablement tous les styles d'apprentissage (explications orales, schémas au tableau, notes écrites et exercices pratiques).\\n\\n"
                          . "• Coordination Diagnostique : Invitez tous les élèves de cette classe à passer leur évaluation sur la plateforme."
                ];
            }
        }"""

new_php_eval = """        if ($totalAssessed === 0) {
            if ($isNationalLevel) {
                return [
                    'en' => "• National Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently underway nationwide across secondary and technical schools.\\n\\n"
                          . "• Universal Multimodal Pedagogical Directives:\\n"
                          . "  - Kinesthetic Directives (Hands-on & Experimental): Equip classrooms and technical workshops with concrete learning kits, lab demonstrations, practical exercises, and real-world case applications to actively engage tactile learners.\\n"
                          . "  - Visual Directives: Incorporate structured blackboard layouts, conceptual mind maps, flowcharts, and color-coded diagrams.\\n"
                          . "  - Auditory Directives: Maintain clear oral explanations, structured classroom discussions, verbal lecture summaries, and Q&A sessions.\\n"
                          . "  - Read/Write Directives: Provide comprehensive written lesson summaries, structured definitions, glossaries, and guided textbook reading.\\n\\n"
                          . "• National Diagnostic Supervision: Mobilize regional and divisional delegations to ensure all enrolled secondary students complete their diagnostic VARK test.",
                    'fr' => "• Stratégie Multimodale Nationale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans l'ensemble des établissements secondaires et techniques du territoire.\\n\\n"
                          . "• Directives Pédagogiques Multimodales Globales :\\n"
                          . "  - Directives Kinesthésiques (Pratique & Expérimentation) : Équipez les classes et ateliers de kits pratiques, démonstrations de laboratoire, exercices d'application et études de cas réels pour mobiliser activement les apprenants tactiles.\\n"
                          . "  - Directives Visuelles : Intégrez des schémas structurés au tableau, cartes mentales, organigrammes et synthèses en couleurs.\\n"
                          . "  - Directives Auditives : Maintenez des explications orales claires, des débats en classe, des récapitulatifs verbaux et des séances de questions/réponses.\\n"
                          . "  - Directives Lecture/Écriture : Fournissez des résumés de cours écrits structurés, des définitions précises, des glossaires et des lectures dirigées.\\n\\n"
                          . "• Suivi Diagnostique National : Mobilisez les délégations régionales et départementales pour que tous les élèves complètent leur évaluation."
                ];
            } else if ($isSchoolLevel) {
                return [
                    'en' => "• School Multimodal Strategy (Diagnostic Phase): Diagnostic VARK assessments are currently in progress across classes in {$contextName}.\\n\\n"
                          . "• School-Wide Multimodal Directives:\\n"
                          . "  - Kinesthetic Learning (Practical & Hands-On): Integrate interactive laboratory experiments, workshop demonstrations, tangible problem sets, and practical assignments into daily lesson planning.\\n"
                          . "  - Visual Learning: Utilize whiteboard schematics, visual summaries, charts, and educational media in classrooms.\\n"
                          . "  - Auditory Learning: Conduct interactive oral lectures, structured student debates, and verbal recaps.\\n"
                          . "  - Read/Write Learning: Distribute structured printed handouts, textbook reading frameworks, and revision glossaries.\\n\\n"
                          . "• Diagnostic Supervision: Coordinate with teachers and the Dean of Studies to ensure all enrolled students complete their diagnostic test on the platform.",
                    'fr' => "• Stratégie Multimodale de l'Établissement (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours dans les classes de {$contextName}.\\n\\n"
                          . "• Directives Multimodales pour l'Établissement :\\n"
                          . "  - Apprentissage Kinesthésique (Pratique & Manipulation) : Intégrez des manipulations de laboratoire, des démonstrations pratiques, des résolutions d'exercices concrets et des cas réels.\\n"
                          . "  - Apprentissage Visuel : Utilisez des schémas au tableau, des synthèses visuelles, des graphiques et des supports illustrés.\\n"
                          . "  - Apprentissage Auditif : Maintenez des explications orales interactives, des débats et des synthèses verbales régulières.\\n"
                          . "  - Apprentissage Lecture/Écriture : Distribuez des fiches de synthèse imprimées, des plans de cours structurés et des glossaires.\\n\\n"
                          . "• Suivi Diagnostique : Coordonnez avec les enseignants et le censeur pour que tous les élèves complètent leur évaluation."
                ];
            } else {
                return [
                    'en' => "• Multimodal Classroom Strategy (Diagnostic Phase): No students have completed the VARK assessment in {$contextName} yet.\\n\\n"
                          . "• Differentiated Multimodal Directives for the Classroom:\\n"
                          . "  - Kinesthetic Engagement: Incorporate hands-on problem sets, laboratory experiments, role-play activities, and physical demonstrations to actively engage practical learners.\\n"
                          . "  - Visual Engagement: Combine whiteboard diagrams, mind maps, and color-coded visual charts.\\n"
                          . "  - Auditory Engagement: Provide clear oral lectures, structured student discussions, and verbal Q&A recaps.\\n"
                          . "  - Read/Write Engagement: Provide concise bulleted notes, key definitions, and guided textbook reading.\\n\\n"
                          . "• Assessment Coordination: Encourage all students in this class to complete their diagnostic test on the platform.",
                    'fr' => "• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Aucun élève n'a encore complété le test VARK en {$contextName}.\\n\\n"
                          . "• Directives Multimodales pour la Classe :\\n"
                          . "  - Engagement Kinesthésique : Intégrez des exercices pratiques, manipulations en laboratoire, démonstrations et résolutions actives de problèmes.\\n"
                          . "  - Engagement Visuel : Combinez schémas au tableau, cartes mentales et synthèses visuelles colorées.\\n"
                          . "  - Engagement Auditif : Offrez des explications orales dynamiques, des échanges structurés et des récapitulatifs verbaux.\\n"
                          . "  - Engagement Lecture/Écriture : Fournissez des notes à puces claires, des définitions clés et des lectures guidées.\\n\\n"
                          . "• Coordination Diagnostique : Invitez tous les élèves de cette classe à passer leur évaluation sur la plateforme."
                ];
            }
        }"""

if old_php_eval in php_code:
    php_code = php_code.replace(old_php_eval, new_php_eval)
    print("SUCCESS: Updated evaluateForEducators in backend/services/vark_academic_engine.php")
else:
    print("WARNING: old_php_eval not matched exact")

with open('backend/services/vark_academic_engine.php', 'w', encoding='utf-8') as f:
    f.write(php_code)

print("ALL KINESTHETIC ENRICHMENTS COMPLETED!")
