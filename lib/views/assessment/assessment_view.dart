import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/assessment_model.dart';
import '../../models/user_model.dart';
import '../../services/offline_assessment_service.dart';

class AssessmentView extends StatefulWidget {
  final UserModel user;
  final bool isDarkMode;
  final bool isEn;
  const AssessmentView({super.key, required this.user, required this.isDarkMode, required this.isEn});

  @override
  State<AssessmentView> createState() => _AssessmentViewState();
}

class _AssessmentViewState extends State<AssessmentView> {
  // Step 0: Intro, Step 1: Questionnaire (10 questions), Step 2: Results Screen
  int _currentStep = 0; 
  int _currentIdx = 0;
  final Map<int, int> _answers = {}; // question index -> option (1..4)

  // Feedback survey
  int _satisfactionLevel = 3;
  String _revealedStyle = 'Yes';

  // Timer (15 mins = 900s)
  late int _secondsLeft;
  Timer? _timer;

  bool _isEvaluating = false;
  Map<String, dynamic>? _evaluatedResult;
  String? _error;

  Color get _green  => const Color(0xFF006A4E);
  Color get _accent => const Color(0xFF34D399);
  Color get _bg     => widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
  Color get _card   => widget.isDarkMode ? const Color(0xFF162032) : Colors.white;
  Color get _text   => widget.isDarkMode ? Colors.white : const Color(0xFF0F172A);
  Color get _sub    => widget.isDarkMode ? Colors.white60 : const Color(0xFF475569);
  Color get _border => widget.isDarkMode ? const Color(0x33FFFFFF) : const Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _secondsLeft = 900; // 15 minutes
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        _evaluateAssessment();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _beginTest() {
    setState(() {
      _currentStep = 1;
      _secondsLeft = 900; // 15 mins
    });
    _startTimer();
  }

  Future<void> _evaluateAssessment() async {
    if (_answers.length < 10) {
      setState(() => _error = widget.isEn
          ? 'Please answer all 10 questions before submitting.'
          : 'Veuillez répondre à toutes les 10 questions avant de soumettre.');
      return;
    }

    setState(() { _isEvaluating = true; _error = null; });
    _timer?.cancel();

    final answerList = List.generate(10, (i) => _answers[i] ?? 1);

    // Evaluate 100% offline using OfflineAssessmentService
    final result = await OfflineAssessmentService.evaluateAndSave(
      user: widget.user,
      answers: answerList,
      isEn: widget.isEn,
    );

    setState(() {
      _evaluatedResult = result;
      _isEvaluating = false;
      _currentStep = 2; // Jump to Results Screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        leading: BackButton(color: _text),
        title: Text(
          widget.isEn ? 'THE LEARNING STYLE TEST (L.S.T)' : 'LE TEST DU STYLE D\'APPRENTISSAGE (T.S.A)',
          style: TextStyle(color: _text, fontWeight: FontWeight.w900, fontSize: 15),
        ),
        centerTitle: true,
        actions: [
          if (_currentStep == 1)
            Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFFF5252), size: 16),
                  const SizedBox(width: 6),
                  Text(_formattedTime,
                      style: const TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 620),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: _currentStep == 0
                  ? _buildIntroScreen()
                  : _currentStep == 1
                      ? _buildQuestionnaireScreen()
                      : _buildResultScreen(),
            ),
          ),
        ),
      ),
    );
  }

  // ── STEP 0: TEST INTRODUCTION SCREEN ────────────────────────────────────────
  Widget _buildIntroScreen() {
    final instructions = [
      {
        'icon': Icons.assignment_outlined,
        'title': widget.isEn ? '1. Read Carefully' : '1. Lire Attentivement',
        'desc': widget.isEn
            ? 'Read each statement carefully from question I to X and reflect on your natural study habits.'
            : 'Lisez attentivement chaque affirmation de la question I à X et réfléchissez à vos habitudes d\'étude.',
      },
      {
        'icon': Icons.touch_app_outlined,
        'title': widget.isEn ? '2. Select One Answer' : '2. Choisir une Réponse',
        'desc': widget.isEn
            ? 'Choose only one answer per statement that best matches your preferred learning style.'
            : 'Choisissez une seule réponse par affirmation correspondant à votre style d\'apprentissage préféré.',
      },
      {
        'icon': Icons.timer_outlined,
        'title': widget.isEn ? '3. 15-Minute Timer' : '3. Chronomètre 15 Min',
        'desc': widget.isEn
            ? 'You have 10 to 15 minutes to complete all 10 questions. The timer will keep track.'
            : 'Vous disposez de 10 à 15 minutes pour répondre aux 10 questions. Le chronomètre est actif.',
      },
      {
        'icon': Icons.psychology_outlined,
        'title': widget.isEn ? '4. Instant AI Results' : '4. Résultats IA Instantanés',
        'desc': widget.isEn
            ? 'Get your VARK learning profile, AI study recommendations, and a downloadable PDF report.'
            : 'Obtenez votre profil VARK, des recommandations IA d\'étude et un rapport PDF téléchargeable.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header Title Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _green.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isEn
                          ? 'THE LEARNING STYLE TEST (L.S.T)'
                          : 'TEST DU STYLE D\'APPRENTISSAGE (T.S.A)',
                      style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Candidate Preview Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(widget.isEn ? 'Candidate Name:' : 'Nom du candidat :', widget.user.fullName),
              const SizedBox(height: 6),
              _infoRow(widget.isEn ? 'Unique ID:' : 'N° d\'Identifiant :', 'AD2026001'),
              const SizedBox(height: 6),
              _infoRow(widget.isEn ? 'School & Class:' : 'Établissement & Classe :', 'LT NGAOUNDAL — 1ère TI'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Title
        Text(
          widget.isEn ? 'Assessment Guidelines & Instructions' : 'Consignes & Instructions du Test',
          style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Instruction Feature Cards (Styled like Home Page Brief Items)
        ...instructions.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, color: _accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['desc'] as String,
                        style: TextStyle(color: _sub, fontSize: 12, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),

        // Start Assessment Button
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _beginTest,
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              widget.isEn ? 'Begin Test Now' : 'Commencer le Test',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Expanded(child: Text(value, style: TextStyle(color: _text, fontSize: 12.5, fontWeight: FontWeight.w600))),
      ],
    );
  }

  // ── STEP 1: QUESTIONNAIRE (10 QUESTIONS) ──────────────────────────────────
  Widget _buildQuestionnaireScreen() {
    final q = LstQuestions.list[_currentIdx];
    final options = widget.isEn ? q.optionsEn : q.optionsFr;
    final questionText = widget.isEn ? q.questionEn : q.questionFr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isEn ? 'Question ${_currentIdx + 1} of 10' : 'Question ${_currentIdx + 1} sur 10',
              style: TextStyle(color: _accent, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              '${((_answers.length / 10) * 100).toInt()}% ${widget.isEn ? 'Completed' : 'Complété'}',
              style: TextStyle(color: _sub, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (_currentIdx + 1) / 10,
            backgroundColor: _sub.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(_green),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 24),

        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFF5252).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFFF5252), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12.5))),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Question Text
        Text(
          questionText,
          style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
        ),
        const SizedBox(height: 20),

        // 4 Options
        ...List.generate(4, (i) {
          final optNum = i + 1;
          final isSelected = _answers[_currentIdx] == optNum;
          return GestureDetector(
            onTap: () => setState(() {
              _answers[_currentIdx] = optNum;
              _error = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? _green.withOpacity(0.15) : _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _accent : _border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? _green : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? _accent : _sub),
                    ),
                    child: Center(
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text('$optNum', style: TextStyle(color: _sub, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      options[i],
                      style: TextStyle(
                        color: isSelected ? _text : _sub,
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),

        // Navigation buttons
        Row(
          children: [
            if (_currentIdx > 0)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => setState(() => _currentIdx--),
                  child: Text(widget.isEn ? 'Previous' : 'Précédent',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
                ),
              ),
            if (_currentIdx > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _isEvaluating
                    ? null
                    : () {
                        if (_currentIdx < 9) {
                          setState(() => _currentIdx++);
                        } else {
                          _evaluateAssessment();
                        }
                      },
                child: _isEvaluating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _currentIdx == 9
                            ? (widget.isEn ? 'Submit Test' : 'Soumettre le Test')
                            : (widget.isEn ? 'Next Question' : 'Question Suivante'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 2: AI RESULTS & PDF DOWNLOAD SCREEN ──────────────────────────────
  Widget _buildResultScreen() {
    final res = _evaluatedResult ?? {};
    final style = res['learning_style'] ?? 'VARK';
    final scores = res['scores'] as Map<String, dynamic>? ?? {};
    final summary = widget.isEn ? res['summary_en'] : res['summary_fr'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emoji_events_rounded, color: _accent, size: 40),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            widget.isEn ? 'AI ASSESSMENT EVALUATION' : 'ÉVALUATION DU TEST IA',
            style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            widget.isEn ? 'Official L.S.T Result & Recommendations' : 'Résultat Officiel T.S.A & Recommandations',
            style: TextStyle(color: _sub, fontSize: 13),
          ),
        ),
        const SizedBox(height: 20),

        // Dominant Learning Style Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_green, const Color(0xFF009966)]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: _green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Text(
                widget.isEn ? 'YOUR PREFERRED LEARNING STYLE:' : 'VOTRE STYLE D\'APPRENTISSAGE PRÉFÉRÉ :',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                style,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // VARK Score Bars
        _scoreBar(widget.isEn ? 'Visual (V)' : 'Visuel (V)', (scores['visual'] ?? 0).toDouble(), const Color(0xFF3B82F6)),
        const SizedBox(height: 8),
        _scoreBar(widget.isEn ? 'Auditory (A)' : 'Auditif (A)', (scores['auditory'] ?? 0).toDouble(), const Color(0xFF10B981)),
        const SizedBox(height: 8),
        _scoreBar(widget.isEn ? 'Kinesthetic (K)' : 'Kinesthésique (K)', (scores['kinesthetic'] ?? 0).toDouble(), const Color(0xFFF59E0B)),
        const SizedBox(height: 8),
        _scoreBar(widget.isEn ? 'Read / Write (R)' : 'Lecture / Écriture (R)', (scores['read_write'] ?? 0).toDouble(), const Color(0xFF8B5CF6)),
        const SizedBox(height: 20),

        // AI Recommendations Box
        Text(
          widget.isEn ? '🤖 AI Pedagogical Study Recommendations:' : '🤖 Recommandations Pédagogiques IA :',
          style: TextStyle(color: _text, fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Text(
            summary ?? '',
            style: TextStyle(color: _sub, fontSize: 12.5, height: 1.5),
          ),
        ),
        const SizedBox(height: 24),

        // Download PDF Report Button
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            OfflineAssessmentService.downloadPdfReport(
              user: widget.user,
              resultData: res,
              isEn: widget.isEn,
            );
          },
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 22),
          label: Text(
            widget.isEn ? 'Download PDF Report' : 'Télécharger le Rapport PDF',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        const SizedBox(height: 12),

        // Return to Dashboard Button
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            widget.isEn ? 'Return to Dashboard' : 'Retour au Tableau de Bord',
            style: TextStyle(color: _text, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _scoreBar(String label, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: _text, fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${pct.toInt()}%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (pct / 100).clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}
