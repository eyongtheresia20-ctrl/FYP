# 1. Update assessment_view.dart
with open(r'lib/views/assessment/assessment_view.dart', 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace(
    "widget.isEn ? '4. Instant AI Results' : '4. Résultats IA Instantanés'",
    "widget.isEn ? '4. Academic Profile & Strategy' : '4. Profil Académique & Stratégie'"
)
text = text.replace(
    "? 'Get your VARK learning profile, AI study recommendations, and a downloadable PDF report.'",
    "? 'Get your Neil Fleming VARK learning profile, standardized academic evaluation, and a downloadable PDF report.'"
)
text = text.replace(
    "widget.isEn ? 'AI ASSESSMENT EVALUATION' : 'ÉVALUATION DU TEST IA'",
    "widget.isEn ? 'ACADEMIC ASSESSMENT EVALUATION' : 'ÉVALUATION ACADÉMIQUE DU TEST'"
)
text = text.replace(
    "widget.isEn ? '🤖 AI Pedagogical Study Recommendations:' : '🤖 Recommandations Pédagogiques IA :'",
    "widget.isEn ? '🎓 Neil Fleming Academic Interpretation & Strategy:' : '🎓 Interprétation Académique & Stratégie (Neil Fleming) :'"
)

with open(r'lib/views/assessment/assessment_view.dart', 'w', encoding='utf-8') as f:
    f.write(text)

# 2. Update student_dashboard.dart
with open(r'lib/views/dashboards/student_dashboard.dart', 'r', encoding='utf-8') as f:
    st_text = f.read()

st_text = st_text.replace(
    "_isEn ? 'AI Recommendation for Test #$attemptNum' : 'Recommandation IA pour Test #$attemptNum'",
    "_isEn ? 'Academic Strategy for Test #$attemptNum' : 'Stratégie Académique pour Test #$attemptNum'"
)
st_text = st_text.replace(
    "_isEn ? 'AI Learning Recommendations' : 'Recommandations d\\'Apprentissage IA'",
    "_isEn ? 'Academic Interpretation & Learning Strategy' : 'Interprétation Académique & Stratégie d\\'Apprentissage'"
)
st_text = st_text.replace(
    "_isEn ? 'Tap to view full AI recommendation' : 'Appuyez pour voir la recommandation IA'",
    "_isEn ? 'Tap to view full academic strategy' : 'Appuyez pour voir la stratégie académique'"
)

with open(r'lib/views/dashboards/student_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(st_text)

# 3. Update principal_dashboard.dart
with open(r'lib/views/dashboards/principal_dashboard.dart', 'r', encoding='utf-8') as f:
    pr_text = f.read()

pr_text = pr_text.replace(
    "_isEn ? 'AI Strategic Pedagogical Policy Recommendations' : 'Recommandations Pédagogiques Stratégiques IA'",
    "_isEn ? 'Institutional Pedagogical Strategy & Directives' : 'Directives Pédagogiques Institutionnelles'"
)
pr_text = pr_text.replace(
    "'${_isEn ? \"AI Recommendation for\" : \"Recommandation IA pour\"} $cName:'",
    "'${_isEn ? \"Academic Strategy for\" : \"Stratégie Académique pour\"} $cName:'"
)
pr_text = pr_text.replace(
    "? 'Official MINESEC platform designed to diagnose student VARK learning preferences and generate actionable AI directives for tailored secondary education in Cameroon.'",
    "? 'Official MINESEC platform designed to evaluate student VARK learning preferences using Neil Fleming standardized grading scales and generate tailored pedagogical strategies.'"
)

with open(r'lib/views/dashboards/principal_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(pr_text)

print("SUCCESS: REFACTORED ALL AI LABELS TO NEIL FLEMING ACADEMIC TERMINOLOGY")
