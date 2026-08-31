# 1. Update admin_dashboard.dart
with open(r'lib/views/dashboards/admin_dashboard.dart', 'r', encoding='utf-8') as f:
    admin_code = f.read()

# Replace Tab 1 Header: 'National Educational Policy' -> 'Recommendations'
admin_code = admin_code.replace(
    "Text(_isEn ? 'National Educational Policy' : 'Directives Pédagogiques Nationales', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),",
    "Text(_isEn ? 'Recommendations' : 'Recommandations', style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 18)),"
)

# Replace Tab 2 Header in Container: 'National Pedagogical Strategy' -> 'Strategic Recommendations'
admin_code = admin_code.replace(
    "Text(_isEn ? 'National Pedagogical Strategy' : 'Stratégie Pédagogique Nationale', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5)),",
    "Text(_isEn ? 'Strategic Recommendations' : 'Recommandations Stratégiques', style: TextStyle(color: _text, fontWeight: FontWeight.w800, fontSize: 15.5)),"
)

# Fix hardcoded fallback for classes & teachers on newly created schools:
admin_code = admin_code.replace(
    "final totCls  = _parseInt(_classDetailsData!['total_classes'] ?? 2);",
    "final totCls  = _parseInt(_classDetailsData!['total_classes'] ?? 0);"
)
admin_code = admin_code.replace(
    "final totTch  = _parseInt(_classDetailsData!['total_teachers'] ?? 1);",
    "final totTch  = _parseInt(_classDetailsData!['total_teachers'] ?? 0);"
)

# Fix isSchoolLevel for school recommendation in admin_dashboard.dart
old_eval_sc = """                                  final educatorScRec = VarkAcademicEngine.evaluateForEducators(
                                    auditory: aud,
                                    visual: vis,
                                    kinesthetic: kin,
                                    readWrite: rw,
                                    contextName: scName,
                                  );"""

new_eval_sc = """                                  final educatorScRec = VarkAcademicEngine.evaluateForEducators(
                                    auditory: aud,
                                    visual: vis,
                                    kinesthetic: kin,
                                    readWrite: rw,
                                    contextName: scName,
                                    isSchoolLevel: true,
                                  );"""

if old_eval_sc in admin_code:
    admin_code = admin_code.replace(old_eval_sc, new_eval_sc)
    print("SUCCESS: SET isSchoolLevel: true FOR SCHOOL STATS")
else:
    print("WARNING: old_eval_sc not found exact match")

# Update _VarkPieChartPainter in admin_dashboard.dart
old_painter = """    if (total == 0) {
      final paint = Paint()..color = Colors.grey.withValues(alpha: 0.3);
      canvas.drawCircle(center, radius, paint);
      return;
    }"""

new_painter = """    if (total == 0) {
      // Draw a 4-color balanced multimodal preview ring (25% each) with dashed/soft appearance
      final rect = Rect.fromCircle(center: center, radius: radius);
      final colors = [
        const Color(0xFF3B82F6).withValues(alpha: 0.45), // Visual
        const Color(0xFFEC4899).withValues(alpha: 0.45), // Auditory
        const Color(0xFF10B981).withValues(alpha: 0.45), // Kinesthetic
        const Color(0xFFF59E0B).withValues(alpha: 0.45), // Read/Write
      ];
      const quarter = 3.141592653589793 / 2;
      double start = -3.141592653589793 / 2;
      for (int i = 0; i < 4; i++) {
        final p = Paint()..color = colors[i]..style = PaintingStyle.fill;
        canvas.drawArc(rect, start, quarter, true, p);
        start += quarter;
      }
      // Inner circle hole (donut effect) with 0% text
      final innerPaint = Paint()..color = const Color(0xFF1E293B);
      canvas.drawCircle(center, radius * 0.55, innerPaint);

      final textPainter = TextPainter(
        text: const TextSpan(
          text: '0%',
          style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
      return;
    }"""

if old_painter in admin_code:
    admin_code = admin_code.replace(old_painter, new_painter)
    print("SUCCESS: UPDATED PIE CHART PAINTER IN ADMIN DASHBOARD")
else:
    print("WARNING: old_painter not found in admin_code")

with open(r'lib/views/dashboards/admin_dashboard.dart', 'w', encoding='utf-8') as f:
    f.write(admin_code)

# 2. Also update _VarkPieChartPainter in delegate_dashboard.dart, principal_dashboard.dart, teacher_dashboard.dart
for file_path in [
    r'lib/views/dashboards/delegate_dashboard.dart',
    r'lib/views/dashboards/principal_dashboard.dart',
    r'lib/views/dashboards/teacher_dashboard.dart',
]:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    if old_painter in content:
        content = content.replace(old_painter, new_painter)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"SUCCESS: UPDATED PIE CHART PAINTER IN {file_path}")

print("ALL FILES UPDATED!")
