import re

# ==============================================================================
# 1. UPDATE DELEGATE DASHBOARD (Empty schools encouragement)
# ==============================================================================
with open(r'lib/views/dashboards/delegate_dashboard.dart', 'r', encoding='utf-8') as f:
    del_text = f.read()

old_sc_rec = """                                final scRec = _isEn
                                    ? (selectedSchoolObj['ai_recommendation_en'] as String? ?? '• Institutional Policy Directive for $scName: Coordinate with head teachers to complete VARK diagnostics and allocate audio-visual tools across all departments.')
                                    : (selectedSchoolObj['ai_recommendation_fr'] as String? ?? '• Directive Institutionnelle pour $scName : Coordonnez avec les proviseurs pour finaliser les tests VARK et allouer du matériel audio-visuel.');"""

new_sc_rec = """                                final scRec = (finalTotalSt == 0 || scAssessedTotal == 0)
                                    ? (_isEn
                                        ? '• Multimodal Teaching Strategy (Diagnostic Phase): Diagnostic VARK assessments are in progress for $scName. Encourage all learning styles equally through multimodal instruction.\\n• Coordinate with head teachers to ensure all enrolled students complete their diagnostic VARK test on the platform.'
                                        : '• Stratégie Pédagogique Multimodale (Phase Diagnostique) : Les évaluations diagnostiques VARK sont en cours pour $scName. Encouragez équitablement tous les styles d\\'apprentissage.\\n• Coordonnez avec les proviseurs pour que tous les élèves inscrits complètent leur test VARK sur la plateforme.')
                                    : (_isEn
                                        ? (selectedSchoolObj['ai_recommendation_en'] as String? ?? '• Institutional Policy Directive for $scName: Coordinate with head teachers to complete VARK diagnostics and allocate audio-visual tools across all departments.')
                                        : (selectedSchoolObj['ai_recommendation_fr'] as String? ?? '• Directive Institutionnelle pour $scName : Coordonnez avec les proviseurs pour finaliser les tests VARK et allouer du matériel audio-visuel.'));"""

del_text = del_text.replace(old_sc_rec, new_sc_rec)

with open(r'lib/views/dashboards/delegate_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(del_text)

print('DELEGATE DASHBOARD UPDATED')
