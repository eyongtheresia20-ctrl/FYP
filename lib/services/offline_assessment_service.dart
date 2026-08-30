import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../core/api_config.dart';

class OfflineAssessmentService {
  // ── 1. LOCAL EVALUATION ENGINE (OFFLINE FIRST) ──────────────────────────────
  static Future<Map<String, dynamic>> evaluateAndSave({
    required UserModel user,
    required List<int> answers,
    required bool isEn,
  }) async {
    // Count scores (1=Auditory, 2=Visual, 3=Kinesthetic, 4=Read/Write)
    int auditory = 0, visual = 0, kinesthetic = 0, readWrite = 0;
    for (int ans in answers) {
      if (ans == 1) auditory++;
      else if (ans == 2) visual++;
      else if (ans == 3) kinesthetic++;
      else if (ans == 4) readWrite++;
    }

    final vPct = (visual / 10.0) * 100;
    final aPct = (auditory / 10.0) * 100;
    final kPct = (kinesthetic / 10.0) * 100;
    final rPct = (readWrite / 10.0) * 100;

    final map = {
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

    final recommendations = generateAIRecommendations(primaryStyle);

    final resultData = {
      'completed': true,
      'learning_style': primaryStyle,
      'scores': {
        'visual': vPct,
        'auditory': aPct,
        'kinesthetic': kPct,
        'read_write': rPct,
      },
      'counts': {
        'visual': visual,
        'auditory': auditory,
        'kinesthetic': kinesthetic,
        'read_write': readWrite,
      },
      'summary_en': recommendations['en'],
      'summary_fr': recommendations['fr'],
      'completed_at': DateTime.now().toString().split('.')[0],
    };

    // Save locally in SharedPreferences for 100% offline access
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(resultData);
    await prefs.setString('vark_result_${user.id}', encoded);
    await prefs.setString('vark_latest_result', encoded);

    // Async sync with MySQL backend if online
    _syncWithBackend(user.id, answers, primaryStyle, vPct, aPct, kPct, rPct, recommendations);

    return resultData;
  }

  static Future<Map<String, dynamic>?> getStoredResult(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('vark_result_$userId') ?? prefs.getString('vark_latest_result');
    if (str != null) {
      return jsonDecode(str) as Map<String, dynamic>;
    }
    return null;
  }

  static void _syncWithBackend(
    int userId, List<int> answers, String style, double v, double a, double k, double r, Map<String, String> rec,
  ) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.assessmentUrl}?action=submit_assessment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'answers': answers,
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignore network errors — offline local result takes priority
    }
  }

  static Map<String, String> generateAIRecommendations(String style) {
    final List<String> partsEn = [];
    final List<String> partsFr = [];

    if (style.contains('Visual')) {
      partsEn.add("• Use color-coded highlighters, mind maps, and concept diagrams.\n• Watch educational video tutorials, animations, and visual demonstrations.\n• Visualize notebook pages and key formulas in your mind during study.");
      partsFr.add("• Utilisez du surlignage couleur, des cartes mentales et des schémas explicatifs.\n• Regardez des tutoriels vidéo éducatifs, des animations et démonstrations visuelles.\n• Visualisez les pages de vos cours et les formules clés dans votre esprit.");
    }
    if (style.contains('Auditory')) {
      partsEn.add("• Listen attentively to recorded lectures, podcasts, and verbal explanations.\n• Read your notes aloud and explain complex concepts to a study partner.\n• Use rhythmic memory devices, acronyms, and rhymes for memorization.");
      partsFr.add("• Écoutez attentivement les cours enregistrés, les podcasts et explications orales.\n• Lisez vos notes à voix haute et expliquez les concepts clés à un camarade.\n• Utilisez des répétitions rythmiques, des acronymes et des rimes pour mémoriser.");
    }
    if (style.contains('Kinesthetic')) {
      partsEn.add("• Study while walking around or holding tactile study objects (flashcards, models).\n• Participate in hands-on experiments, practical exercises, and role-playing.\n• Take short, active breaks (Pomodoro technique) between focused study sessions.");
      partsFr.add("• Étudiez en vous déplaçant ou en manipulant des supports tactiles (fiches, modèles).\n• Participez à des travaux pratiques, des expériences et exercices d'application.\n• Prenez de courtes pauses actives (technique Pomodoro) entre les sessions d'étude.");
    }
    if (style.contains('Read/Write')) {
      partsEn.add("• Write comprehensive summaries and rewrite main points in your own words.\n• Create structured glossaries, flashcards, and lists of formulas/terms.\n• Read textbooks silently and take structured bulleted notes.");
      partsFr.add("• Rédigez des résumés détaillés et réécrivez les points clés avec vos propres mots.\n• Créez des glossaires structurés, des fiches et des listes de formules et mots-clés.\n• Lisez les manuels en silence et prenez des notes structurées à puces.");
    }

    if (partsEn.isEmpty) {
      partsEn.add("• Combine visual diagrams with written summaries and active study sessions.\n• Review core concepts regularly using interactive practice exercises.");
      partsFr.add("• Combinez schémas visuels, résumés écrits et sessions d'étude actives.\n• Révisez régulièrement les concepts clés à l'aide d'exercices interactifs.");
    }

    return {
      'en': partsEn.join("\n\n"),
      'fr': partsFr.join("\n\n"),
    };
  }

  // ── 2. OFFICIAL MINESEC PDF GENERATOR & DIRECT DOWNLOAD ─────────────────────
  static Future<void> downloadPdfReport({
    required UserModel user,
    required Map<String, dynamic> resultData,
    required bool isEn,
  }) async {
    final pdf = pw.Document();
    final style = resultData['learning_style'] ?? 'VARK';
    final scores = resultData['scores'] as Map<String, dynamic>? ?? {};
    final summary = isEn ? resultData['summary_en'] : resultData['summary_fr'];
    final completedAt = resultData['completed_at'] ?? DateTime.now().toString().split('.')[0];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // MINESEC Official Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('REPUBLIQUE DU CAMEROUN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('Paix - Travail - Patrie', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('MINISTERE DES ENSEIGNEMENTS SECONDAIRES', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('REPUBLIC OF CAMEROON', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text('Peace - Work - Fatherland', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('MINISTRY OF SECONDARY EDUCATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.teal900),
              pw.SizedBox(height: 12),

              // Title
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      isEn ? 'LEARNING STYLE TEST (L.S.T) REPORT' : 'RAPPORT DU TEST DE STYLE D\'APPRENTISSAGE (T.S.A)',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    ),
                    pw.Text(isEn ? 'Official MINESEC Pedagogical Evaluation' : 'Évaluation Pédagogique Officielle MINESEC', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ),
              pw.SizedBox(height: 18),

              // Candidate Information Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal700),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  color: PdfColors.teal50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(children: [
                      pw.Text('Candidate Name: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(user.fullName),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('Role: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Student — MINESEC'),
                    ]),
                    pw.SizedBox(height: 4),
                    pw.Row(children: [
                      pw.Text('Date of Assessment: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(completedAt),
                    ]),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Dominant Style Result
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal800,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isEn ? 'PREFERRED LEARNING STYLE:' : 'STYLE D\'APPRENTISSAGE PREFERE :',
                      style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                    pw.Text(
                      style,
                      style: pw.TextStyle(color: PdfColors.yellow, fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // VARK Breakdown Table
              pw.Text(isEn ? 'VARK Score Breakdown:' : 'Detail des Scores VARK :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal700),
                data: [
                  [isEn ? 'Learning Style Dimension' : 'Dimension du Style', isEn ? 'Score (%)' : 'Score (%)'],
                  [isEn ? 'Visual (V)' : 'Visuel (V)', '${(scores['visual'] ?? 0).toInt()}%'],
                  [isEn ? 'Auditory / Aural (A)' : 'Auditif (A)', '${(scores['auditory'] ?? 0).toInt()}%'],
                  [isEn ? 'Kinesthetic (K)' : 'Kinesique (K)', '${(scores['kinesthetic'] ?? 0).toInt()}%'],
                  [isEn ? 'Read / Write (R)' : 'Lecture / Ecriture (R)', '${(scores['read_write'] ?? 0).toInt()}%'],
                ],
              ),
              pw.SizedBox(height: 20),

              // AI Recommendations
              pw.Text(isEn ? 'AI Pedagogical Recommendations:' : 'Recommandations Pedagogiques IA :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Text(summary ?? '', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MINESEC LST Automated Evaluation System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Text('MINESEC L.S.T Framework', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Direct PDF file download to device storage (bypasses print preview window)
    final pdfBytes = await pdf.save();
    final filename = 'MINESEC_LST_Report_${user.fullName.replaceAll(' ', '_')}.pdf';
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: filename,
    );
  }
}
