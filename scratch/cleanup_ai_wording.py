import os

# 1. Update student_dashboard.dart
with open('lib/views/dashboards/student_dashboard.dart', 'r', encoding='utf-8') as f:
    st_code = f.read()

st_code = st_code.replace("Multi-Test AI Strategy", "Multi-Test Academic Strategy")
st_code = st_code.replace("Stratégie IA Multi-Tests", "Stratégie Académique Multi-Tests")
st_code = st_code.replace("generateAIRecommendations", "generateRecommendations")

with open('lib/views/dashboards/student_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(st_code)

# 2. Update offline_assessment_service.dart
with open('lib/services/offline_assessment_service.dart', 'r', encoding='utf-8') as f:
    off_code = f.read()

off_code = off_code.replace("generateAIRecommendations", "generateRecommendations")
off_code = off_code.replace("// AI Recommendations", "// Academic Recommendations")

with open('lib/services/offline_assessment_service.dart', 'w', encoding='utf-8') as f:
    f.write(off_code)

# 3. Update admin_dashboard.dart
with open('lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    adm_code = f.read()

adm_code = adm_code.replace("institutional VARK AI policy", "institutional VARK policy & recommendations")
adm_code = adm_code.replace("directives IA", "directives et recommandations")

with open('lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(adm_code)

# 4. Update backend/api/assessment.php
with open('backend/api/assessment.php', 'r', encoding='utf-8') as f:
    bk_code = f.read()

bk_code = bk_code.replace("generateAIRecommendations", "generateAcademicRecommendations")

with open('backend/api/assessment.php', 'w', encoding='utf-8') as f:
    f.write(bk_code)

# 5. Update localization.dart
with open('lib/core/localization.dart', 'r', encoding='utf-8') as f:
    loc_code = f.read()

loc_code = loc_code.replace("AI-Powered Learning Profile System", "Psychometric Learning Profile System")
loc_code = loc_code.replace("AI-driven VARK learning style assessment", "Standardized VARK learning style assessment")
loc_code = loc_code.replace("utilizing AI data insights", "utilizing psychometric diagnostic insights")

with open('lib/core/localization.dart', 'w', encoding='utf-8') as f:
    f.write(loc_code)

# 6. Update welcome_view.dart & about_view.dart
with open('lib/views/welcome_view.dart', 'r', encoding='utf-8') as f:
    wlc_code = f.read()

wlc_code = wlc_code.replace("AI-guided questionnaire", "Standardized VARK questionnaire")
wlc_code = wlc_code.replace("AI-Learning Style Tracker System", "Learning Style Tracker System")

with open('lib/views/welcome_view.dart', 'w', encoding='utf-8') as f:
    f.write(wlc_code)

with open('lib/views/about_view.dart', 'r', encoding='utf-8') as f:
    abt_code = f.read()

abt_code = abt_code.replace("We use AI to understand how each student learns best", "We use standardized VARK diagnostics to understand how each student learns best")

with open('lib/views/about_view.dart', 'w', encoding='utf-8') as f:
    f.write(abt_code)

print("SUCCESS: ALL 'AI' TERMINOLOGY REPLACED WITH PSYCHOMETRIC & ACADEMIC ORIENTATION!")
