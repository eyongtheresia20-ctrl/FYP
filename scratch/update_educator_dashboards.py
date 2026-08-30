import shutil

# Copy backend service to xammp
shutil.copy2(r'backend/services/vark_academic_engine.php', r'd:/xammp/htdocs/minesec_api/services/vark_academic_engine.php')

# 1. Update delegate_dashboard.dart
with open(r'lib/views/dashboards/delegate_dashboard.dart', 'r', encoding='utf-8') as f:
    del_text = f.read()

# Replace Tab 2 school recommendation title and text in delegate_dashboard.dart
old_del_rec_title = "_isEn ? 'Institutional Policy Recommendation for School' : 'Recommandation Pédagogique pour l\\'Établissement'"
new_del_rec_title = "_isEn ? 'Teaching Recommendations' : 'Recommandations pour l\\'Enseignement'"
del_text = del_text.replace(old_del_rec_title, new_del_rec_title)

old_del_eval_block = """                                final evalSchool = VarkAcademicEngine.evaluate(
                                  auditory: scAudTotal,
                                  visual: scVisTotal,
                                  kinesthetic: scKinTotal,
                                  readWrite: scRwTotal,
                                );

                                final scRec = (finalTotalSt == 0 || scAssessedTotal == 0)
                                    ? (_isEn
                                        ? '• Multimodal Diagnostic Phase: Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                        : '• Phase Diagnostique Multimodale : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                    : (_isEn
                                        ? "• Academic Diagnosis for $scName: ${evalSchool.learningStyle} (${evalSchool.primaryCategoryNameEn}).\\n"
                                          "• Academic Prospects: ${evalSchool.prospectsSummaryEn}\\n\\n"
                                          "${evalSchool.learningStrategyEn}"
                                        : "• Diagnostic Académique pour $scName : ${evalSchool.learningStyle} (${evalSchool.primaryCategoryNameFr}).\\n"
                                          "• Perspectives Académiques : ${evalSchool.prospectsSummaryFr}\\n\\n"
                                          "${evalSchool.learningStrategyFr}");"""

new_del_eval_block = """                                final educatorRec = VarkAcademicEngine.evaluateForEducators(
                                  auditory: scAudTotal,
                                  visual: scVisTotal,
                                  kinesthetic: scKinTotal,
                                  readWrite: scRwTotal,
                                  contextName: scName,
                                );
                                final scRec = _isEn ? educatorRec['en']! : educatorRec['fr']!;"""

if old_del_eval_block in del_text:
    del_text = del_text.replace(old_del_eval_block, new_del_eval_block)

# Replace Regional Overview Policy in Tab 1
old_del_tab1 = """    final evalTerritory = VarkAcademicEngine.evaluate(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
    );

    final String aiPolicy = _isEn
        ? "• Territorial Pedagogical Diagnosis: Dominant profile is ${evalTerritory.learningStyle} (${evalTerritory.primaryCategoryNameEn}).\\n"
          "• Academic Prospects & Resilience: ${evalTerritory.prospectsSummaryEn}\\n\\n"
          "${evalTerritory.learningStrategyEn}"
        : "• Diagnostic Pédagogique Territorial : Profil dominant ${evalTerritory.learningStyle} (${evalTerritory.primaryCategoryNameFr}).\\n"
          "• Perspectives Académiques & Résilience : ${evalTerritory.prospectsSummaryFr}\\n\\n"
          "${evalTerritory.learningStrategyFr}";"""

new_del_tab1 = """    final educatorTerritoryRec = VarkAcademicEngine.evaluateForEducators(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
      contextName: _currentUser.region ?? 'Regional Territory',
    );
    final String aiPolicy = _isEn ? educatorTerritoryRec['en']! : educatorTerritoryRec['fr']!;"""

if old_del_tab1 in del_text:
    del_text = del_text.replace(old_del_tab1, new_del_tab1)

with open(r'lib/views/dashboards/delegate_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(del_text)

# 2. Update admin_dashboard.dart
with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    adm_text = f.read()

# Replace Tab 2 title in admin_dashboard.dart
adm_text = adm_text.replace(
    "_isEn ? 'Institutional Policy Recommendation for School' : 'Recommandation Pédagogique pour l\\'Établissement'",
    "_isEn ? 'Teaching Recommendations' : 'Recommandations pour l\\'Enseignement'"
)

old_adm_tab2_block = """                                  final evalSc = VarkAcademicEngine.evaluate(auditory: aud, visual: vis, kinesthetic: kin, readWrite: rw);
                                  final aiRec = (totSt == 0 || assSt == 0)
                                      ? (_isEn
                                          ? '• Multimodal Diagnostic Phase: Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                          : '• Phase Diagnostique Multimodale : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                      : (_isEn
                                          ? "• Academic Diagnosis for $scName: ${evalSc.learningStyle} (${evalSc.primaryCategoryNameEn}).\\n"
                                            "• Academic Prospects: ${evalSc.prospectsSummaryEn}\\n\\n"
                                            "${evalSc.learningStrategyEn}"
                                          : "• Diagnostic Académique pour $scName : ${evalSc.learningStyle} (${evalSc.primaryCategoryNameFr}).\\n"
                                            "• Perspectives Académiques : ${evalSc.prospectsSummaryFr}\\n\\n"
                                            "${evalSc.learningStrategyFr}");"""

new_adm_tab2_block = """                                  final educatorScRec = VarkAcademicEngine.evaluateForEducators(
                                    auditory: aud,
                                    visual: vis,
                                    kinesthetic: kin,
                                    readWrite: rw,
                                    contextName: scName,
                                  );
                                  final aiRec = _isEn ? educatorScRec['en']! : educatorScRec['fr']!;"""

if old_adm_tab2_block in adm_text:
    adm_text = adm_text.replace(old_adm_tab2_block, new_adm_tab2_block)

# Replace National Strategy in Tab 1
old_adm_tab1 = """    final evalNational = VarkAcademicEngine.evaluate(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
    );

    final String aiStrategy = _isEn
        ? "• National Pedagogical Diagnosis: Dominant profile is ${evalNational.learningStyle} (${evalNational.primaryCategoryNameEn}).\\n"
          "• Academic Prospects & Resilience: ${evalNational.prospectsSummaryEn}\\n\\n"
          "${evalNational.learningStrategyEn}"
        : "• Diagnostic Pédagogique National : Profil dominant ${evalNational.learningStyle} (${evalNational.primaryCategoryNameFr}).\\n"
          "• Perspectives Académiques & Résilience : ${evalNational.prospectsSummaryFr}\\n\\n"
          "${evalNational.learningStrategyFr}";"""

new_adm_tab1 = """    final educatorNationalRec = VarkAcademicEngine.evaluateForEducators(
      auditory: audCount,
      visual: visCount,
      kinesthetic: kinCount,
      readWrite: rwCount,
      contextName: 'National Territory',
    );
    final String aiStrategy = _isEn ? educatorNationalRec['en']! : educatorNationalRec['fr']!;"""

if old_adm_tab1 in adm_text:
    adm_text = adm_text.replace(old_adm_tab1, new_adm_tab1)

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(adm_text)

print("SUCCESS: UPDATED EDUCATOR DASHBOARDS TO INCLUSIVE TEACHING RECOMMENDATIONS")
