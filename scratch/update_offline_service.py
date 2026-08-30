with open(r'lib/services/offline_assessment_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

if "import 'vark_academic_engine.dart';" not in text:
    text = text.replace(
        "import '../core/api_config.dart';",
        "import '../core/api_config.dart';\nimport 'vark_academic_engine.dart';"
    )

# Replace evaluateAndSave in OfflineAssessmentService
old_evaluate = """    final map = {
      'Auditory': auditory,
      'Visual': visual,
      'Kinesthetic': kinesthetic,
      'Read/Write': readWrite,
    };
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topScore = sorted.first.value;
    final topStyles = sorted.where((MapEntry<String, int> e) => e.value == topScore).map((e) => e.key).toList();

    final primaryStyle = (topStyles.length > 1)
        ? '${topStyles.join('-')} (Dual Style)'
        : topStyles.first;

    final recommendations = generateAIRecommendations(primaryStyle);"""

new_evaluate = """    final eval = VarkAcademicEngine.evaluate(
      auditory: auditory,
      visual: visual,
      kinesthetic: kinesthetic,
      readWrite: readWrite,
    );

    final primaryStyle = eval.learningStyle;
    final recommendations = {
      'en': eval.fullRecommendationEn,
      'fr': eval.fullRecommendationFr,
    };"""

text = text.replace(old_evaluate, new_evaluate)

# Replace PDF text "AI Pedagogical Recommendations:"
text = text.replace(
    "isEn ? 'AI Pedagogical Recommendations:' : 'Recommandations Pedagogiques IA :'",
    "isEn ? 'Academic Interpretation & Learning Strategy (Neil Fleming L.S.T):' : 'Directives & Stratégies d\\'Apprentissage (L.S.T de Neil Fleming) :'"
)

# Update generateAIRecommendations bridge
old_gen = """  static Map<String, String> generateAIRecommendations(String style) {
    final partsEn = <String>[];
    final partsFr = <String>[];"""

new_gen = """  static Map<String, String> generateAIRecommendations(String style, {int v = 0, int a = 0, int k = 0, int r = 0}) {
    final eval = VarkAcademicEngine.evaluate(auditory: a, visual: v, kinesthetic: k, readWrite: r);
    return {
      'en': eval.fullRecommendationEn,
      'fr': eval.fullRecommendationFr,
    };
    final partsEn = <String>[];
    final partsFr = <String>[];"""

text = text.replace(old_gen, new_gen)

with open(r'lib/services/offline_assessment_service.dart', 'w', encoding='utf-8') as f:
    f.write(text)

print("SUCCESS: OFFLINE ASSESSMENT SERVICE UPDATED")
