with open(r'lib/views/dashboards/teacher_dashboard.dart', 'r', encoding='utf-8') as f:
    text = f.read()

if "import '../../services/vark_academic_engine.dart';" not in text:
    text = text.replace(
        "import '../../services/auth_service.dart';",
        "import '../../services/auth_service.dart';\nimport '../../services/vark_academic_engine.dart';"
    )

# Replace _generateClassroomRec
old_func_start = "  String _generateClassroomRec({"
old_func_end = "    return isEn ? recsEn.join('\\n') : recsFr.join('\\n');\n  }"

# Find and replace the whole function
idx_start = text.find(old_func_start)
idx_end = text.find(old_func_end) + len(old_func_end)

new_func = """  String _generateClassroomRec({
    required int vis,
    required int aud,
    required int kin,
    required int rw,
    required String className,
    required bool isEn,
  }) {
    final educatorRec = VarkAcademicEngine.evaluateForEducators(
      auditory: aud,
      visual: vis,
      kinesthetic: kin,
      readWrite: rw,
      contextName: className,
    );
    return isEn ? educatorRec['en']! : educatorRec['fr']!;
  }"""

if idx_start != -1 and idx_end != -1:
    text = text[:idx_start] + new_func + text[idx_end:]
    print("SUCCESS: REPLACED _generateClassroomRec IN TEACHER DASHBOARD")

with open(r'lib/views/dashboards/teacher_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(text)
