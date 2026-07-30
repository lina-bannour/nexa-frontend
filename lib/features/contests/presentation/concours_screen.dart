import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../widgets/latex_text.dart';
import 'contest_photo_submission_screen.dart';

class ConcoursScreen extends StatefulWidget {
  const ConcoursScreen({super.key});

  @override
  State<ConcoursScreen> createState() => _ConcoursScreenState();
}

class _ConcoursScreenState extends State<ConcoursScreen> {
  List<dynamic> _contests = [];
  bool _loading = true;
  // Global solve mode chosen up front, before browsing contests: 'qcm' | 'photo'.
  String? _globalMode;
  Map<String, dynamic>? _activeContest;
  Map<String, dynamic>? _activeSession;
  String? _mode; // 'qcm' | 'photo'
  int _currentQuestionIndex = 0;
  bool _loadingDetail = false;

  final List<String> _filieres = ['MP', 'PT', 'PC', 'BG'];

  final Map<String, Color> _filiereColors = {
    'MP': NexaColors.blue,
    'PT': NexaColors.green,
    'PC': NexaColors.purple,
    'BG': const Color(0xFFDB2777),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final contests = await ApiClient.getContests();
      setState(() => _contests = contests);
    } catch (e) {
      setState(() => _contests = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  // Tapping a contest now goes straight into whichever mode was chosen
  // up front on the mode-selection screen (QCM or photo submission).
  void _openContestInGlobalMode(Map<String, dynamic> contest) {
    if (_globalMode == 'photo') {
      setState(() {
        _activeContest = contest;
        _mode = 'photo';
      });
    } else {
      _openContest(contest['id']);
    }
  }

  Widget _modeOption({required String icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NexaColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NexaColors.border),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: NexaColors.txt3)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: NexaColors.txt3),
          ],
        ),
      ),
    );
  }

  Future<void> _openContest(String id) async {
    setState(() => _loadingDetail = true);
    try {
      final contest = await ApiClient.getContest(id);
      final session = await ApiClient.startContestSession(id);
      setState(() {
        _activeContest = contest;
        _activeSession = session;
        _mode = 'qcm';
        _currentQuestionIndex = (session['questionsCompleted'] ?? 0);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur de chargement')));
    } finally {
      setState(() => _loadingDetail = false);
    }
  }

  void _back() => setState(() {
    _activeContest = null;
    _activeSession = null;
    _mode = null;
    _currentQuestionIndex = 0;
    if (_globalMode != null) _load();
  });

  // Group contests by filière first, then by année within each filière.
  Map<String, Map<int, List<dynamic>>> get _byFiliereThenYear {
    final map = <String, Map<int, List<dynamic>>>{};
    for (final c in _contests) {
      final filiere = (c['filiere'] ?? 'Autre') as String;
      final year = c['annee'] as int;
      map.putIfAbsent(filiere, () => <int, List<dynamic>>{});
      map[filiere]!.putIfAbsent(year, () => []).add(c);
    }
    // Order filières using the app's canonical order; unknown ones appended after.
    final ordered = <String, Map<int, List<dynamic>>>{};
    for (final f in _filieres) {
      if (map.containsKey(f)) ordered[f] = map[f]!;
    }
    for (final f in map.keys) {
      ordered.putIfAbsent(f, () => map[f]!);
    }
    // Sort years descending within each filière.
    for (final f in ordered.keys.toList()) {
      ordered[f] = Map.fromEntries(
        ordered[f]!.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
    }
    return ordered;
  }

  @override
  Widget build(BuildContext context) {
    if (_activeContest != null && _mode == 'photo') {
      return ContestPhotoSubmissionScreen(
        contest: _activeContest!,
        onBack: _back,
      );
    }
    if (_activeContest != null && _activeSession != null) {
      return ContestSessionView(
        contest: _activeContest!,
        session: _activeSession!,
        initialQuestionIndex: _currentQuestionIndex,
        onBack: _back,
      );
    }

    // First thing shown when opening Concours: pick QCM or Papier, before
    // browsing anything. The list only appears once a mode is chosen.
    if (_globalMode == null) {
      return _buildModeChooser();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🏁 Concours Nationaux',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.txt)),
            const SizedBox(height: 10),
            // Current mode indicator + switch button (replaces old filiere chips;
            // contests are now grouped by filière/année below instead).
            Row(children: [
              Icon(_globalMode == 'qcm' ? Icons.computer : Icons.camera_alt,
                size: 16, color: NexaColors.blue),
              const SizedBox(width: 6),
              Text(
                _globalMode == 'qcm' ? 'Mode : QCM interactif' : 'Mode : Résoudre sur papier',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: NexaColors.txt2)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _globalMode = null),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                child: const Text('Changer',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: NexaColors.blue)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _loading || _loadingDetail
            ? const Center(child: CircularProgressIndicator())
            : _contests.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('🏁', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text('Aucun concours disponible',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: NexaColors.txt)),
                  const SizedBox(height: 8),
                  const Text('Ajoutez des concours via l\'API',
                    style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
                ]))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _byFiliereThenYear.entries.map((filiereEntry) {
                    final filiere = filiereEntry.key;
                    final filiereColor = _filiereColors[filiere] ?? NexaColors.blue;
                    final totalInFiliere = filiereEntry.value.values.fold<int>(0, (sum, l) => sum + l.length);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, bottom: 8),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: filiereColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(filiere,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Text('$totalInFiliere concours',
                              style: const TextStyle(color: NexaColors.txt3, fontSize: 12)),
                          ]),
                        ),
                        ...filiereEntry.value.entries.map((yearEntry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text('Concours ${yearEntry.key}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NexaColors.txt2)),
                                ),
                                ...yearEntry.value.map((c) {
                                  final totalQuestions = c['_count']?['questions'] ?? 0;
                                  final myProgress = c['myProgress'] as Map<String, dynamic>?;
                                  return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: NexaCard(
                                    onTap: () => _openContestInGlobalMode(c),
                                    child: Row(children: [
                                      Container(
                                        width: 50, height: 50,
                                        decoration: BoxDecoration(
                                          color: filiereColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: filiereColor.withOpacity(0.3)),
                                        ),
                                        child: Center(
                                          child: Text(c['filiere'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800, fontSize: 13,
                                              color: filiereColor,
                                            )),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(c['titre'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          NexaTag(label: filiere, color: filiereColor),
                                          const SizedBox(width: 6),
                                          Text('$totalQuestions questions',
                                            style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
                                        ]),
                                        if (myProgress != null) ...[
                                          const SizedBox(height: 6),
                                          _progressBadge(myProgress, totalQuestions),
                                        ],
                                      ])),
                                      const Icon(Icons.chevron_right, color: NexaColors.txt3),
                                    ]),
                                  ),
                                );
                                }),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildModeChooser() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏁 Concours Nationaux',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: NexaColors.txt)),
          const SizedBox(height: 6),
          const Text('Comment voulez-vous résoudre les concours aujourd\'hui ?',
            style: TextStyle(color: NexaColors.txt3, fontSize: 14)),
          const SizedBox(height: 24),
          _modeOption(
            icon: '🖥️',
            title: 'QCM interactif',
            subtitle: 'Répondez directement dans l\'app, avec indices et correction instantanée.',
            onTap: () => setState(() {
              _globalMode = 'qcm';
              _load();
            }),
          ),
          const SizedBox(height: 12),
          _modeOption(
            icon: '📷',
            title: 'Résoudre sur papier',
            subtitle: 'Téléchargez le sujet officiel, résolvez sur copie, puis envoyez une photo de votre travail.',
            onTap: () => setState(() {
              _globalMode = 'photo';
              _load();
            }),
          ),
        ],
      ),
    );
  }

  Widget _progressBadge(Map<String, dynamic> myProgress, int totalQuestions) {
    final isCompleted = myProgress['isCompleted'] == true;
    final completed = myProgress['questionsCompleted'] ?? 0;
    final xp = myProgress['xpTotal'] ?? 0;

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: NexaColors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 12, color: NexaColors.green),
          const SizedBox(width: 4),
          Text('Terminé · $xp XP',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.green)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFD97706).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.play_circle_outline, size: 12, color: Color(0xFFD97706)),
        const SizedBox(width: 4),
        Text('En cours · $completed/$totalQuestions',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFD97706))),
      ]),
    );
  }

}

// ─── Contest Session View (question by question) ──────────────────────────────

class ContestSessionView extends StatefulWidget {
  final Map<String, dynamic> contest;
  final Map<String, dynamic> session;
  final int initialQuestionIndex;
  final VoidCallback onBack;

  const ContestSessionView({
    super.key,
    required this.contest,
    required this.session,
    required this.initialQuestionIndex,
    required this.onBack,
  });

  @override
  State<ContestSessionView> createState() => _ContestSessionViewState();
}

class _ContestSessionViewState extends State<ContestSessionView> {
  late int _currentIndex;
  late String _sessionId;
  int _hintsRevealed = 0;
  String? _selectedChoiceId;
  Map<String, dynamic>? _result;
  bool _submitting = false;
  int _totalXp = 0;

  // Free-text "guess before you see the choices" phase — recomputed per
  // question since hasReponseTexte varies question to question.
  bool _inTextPhase = false;
  final _textController = TextEditingController();
  int _textTries = 0;
  bool _checkingText = false;
  String? _textFeedback;
  static const _maxTextTries = 4;

  List<dynamic> get _questions =>
      List<dynamic>.from(widget.contest['questions'] ?? []);

  Map<String, dynamic>? get _currentQuestion =>
      _currentIndex < _questions.length ? _questions[_currentIndex] : null;

  List<String> get _hints {
    final q = _currentQuestion;
    if (q == null) return [];
    return [q['hint1'], q['hint2'], q['hint3'], q['hint4']]
        .where((h) => h != null)
        .cast<String>()
        .toList();
  }

  List<Map<String, dynamic>> get _choices {
    return List<Map<String, dynamic>>.from(_currentQuestion?['choix'] ?? []);
  }

  int get _expectedXp {
    final xpBase = _currentQuestion?['xpBase'] ?? 10;
    final penalties = [0, 10, 20, 30, 40];
    final penalty = penalties[_hintsRevealed.clamp(0, 4)];
    return (xpBase * (1 - penalty / 100)).floor();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialQuestionIndex;
    _sessionId = widget.session['id'];
    _totalXp = widget.session['xpTotal'] ?? 0;
    _inTextPhase = _currentQuestion?['hasReponseTexte'] == true;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkTextAnswer() async {
    final guess = _textController.text.trim();
    if (guess.isEmpty || _checkingText || _currentQuestion == null) return;
    setState(() { _checkingText = true; _textFeedback = null; });
    try {
      final res = await ApiClient.checkContestTextAnswer(
        _sessionId, _currentQuestion!['id'], guess,
      );
      if (res['correct'] == true) {
        setState(() {
          _result = {
            'isCorrect': true,
            'xpEarned': res['xpEarned'],
            'solution': res['solution'],
            'questionsCompleted': res['questionsCompleted'],
            'totalQuestions': res['totalQuestions'],
            'isCompleted': res['isCompleted'],
          };
          _totalXp += (res['xpEarned'] as int? ?? 0);
        });
        return;
      }
      _textTries++;
      if (_textTries >= _maxTextTries) {
        setState(() => _inTextPhase = false);
      } else {
        setState(() => _textFeedback = 'Incorrect — essai $_textTries/$_maxTextTries. Réessayez !');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur, réessayez')));
    } finally {
      if (mounted) setState(() => _checkingText = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedChoiceId == null || _currentQuestion == null) return;
    setState(() => _submitting = true);
    try {
      final result = await ApiClient.submitContestAnswer(
        _sessionId,
        _currentQuestion!['id'],
        _selectedChoiceId!,
        _hintsRevealed,
      );
      setState(() {
        _result = result;
        _totalXp += (result['xpEarned'] as int? ?? 0);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la soumission')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _hintsRevealed = 0;
      _selectedChoiceId = null;
      _result = null;
      _inTextPhase = _currentQuestion?['hasReponseTexte'] == true;
      _textController.clear();
      _textTries = 0;
      _textFeedback = null;
    });
  }

  bool get _isCompleted => _result?['isCompleted'] == true ||
      _currentIndex >= _questions.length;

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('Aucune question disponible'),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: widget.onBack, child: const Text('Retour')),
      ]));
    }

    if (_isCompleted && _result != null) return _buildSummary();

    final q = _currentQuestion;
    if (q == null) return _buildSummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Header
        GestureDetector(
          onTap: widget.onBack,
          child: const Row(children: [
            Icon(Icons.arrow_back_ios, size: 14, color: NexaColors.txt3),
            Text('Concours', style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 14),

        // Progress bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: NexaColors.blueLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Question ${_currentIndex + 1}/${_questions.length}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NexaColors.blue)),
              Text('$_totalXp XP cumulés',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFB45309))),
            ]),
            const SizedBox(height: 8),
            NexaProgressBar(
              value: (_currentIndex) / _questions.length,
              color: NexaColors.blue,
              height: 6,
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // XP badge
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: NexaColors.goldLight, borderRadius: BorderRadius.circular(20)),
            child: Text('+$_expectedXp XP',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFB45309))),
          ),
          if (_hintsRevealed > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('-${_hintsRevealed * 10}% XP',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFD97706))),
            ),
          ],
        ]),
        const SizedBox(height: 12),

        // Enonce
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NexaColors.blueLight,
            borderRadius: BorderRadius.circular(12),
            border: const Border(left: BorderSide(color: NexaColors.blue, width: 4)),
          ),
          child: LatexText(q['enonce'] ?? '',
            style: const TextStyle(fontSize: 15, fontFamily: 'monospace', color: NexaColors.txt, height: 1.7)),
        ),
        const SizedBox(height: 20),

        // ── FREE-TEXT PHASE: guess before the choices are ever shown ──
        if (_inTextPhase && _result == null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NexaColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: NexaColors.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('✍️ Écrivez votre réponse',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
                Text('Essai ${_textTries + 1}/$_maxTextTries',
                  style: const TextStyle(fontSize: 12, color: NexaColors.txt3, fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _textController,
                onSubmitted: (_) => _checkTextAnswer(),
                decoration: InputDecoration(
                  hintText: 'Votre réponse...',
                  filled: true, fillColor: NexaColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: NexaColors.border)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              if (_textFeedback != null) ...[
                const SizedBox(height: 8),
                Text(_textFeedback!, style: const TextStyle(color: NexaColors.red, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _checkingText ? null : _checkTextAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NexaColors.blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: _checkingText
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Vérifier ma réponse', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 6),
              Text('4 essais libres, puis indices et choix multiples si besoin.',
                style: TextStyle(fontSize: 11, color: NexaColors.txt3)),
            ]),
          ),
          const SizedBox(height: 20),
        ],

        // Hints
        if (!_inTextPhase && _hints.isNotEmpty && _result == null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Indices (${_hintsRevealed}/${_hints.length})',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NexaColors.txt)),
              if (_hintsRevealed < _hints.length)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _hintsRevealed++),
                  icon: const Icon(Icons.lightbulb_outline, size: 16),
                  label: Text('Indice ${_hintsRevealed + 1} (-10% XP)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NexaColors.blue,
                    side: const BorderSide(color: NexaColors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              else
                const NexaTag(label: 'Tous utilisés', color: NexaColors.txt3),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_hintsRevealed, (i) {
            final colors = [NexaColors.blue, NexaColors.purple, const Color(0xFFD97706), NexaColors.red];
            final bgs = [NexaColors.blueLight, NexaColors.purpleLight, const Color(0xFFFEF3C7), const Color(0xFFFEF2F2)];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgs[i % bgs.length],
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                border: Border(left: BorderSide(color: colors[i % colors.length], width: 3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('INDICE ${i + 1}  •  -10% XP',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors[i % colors.length], letterSpacing: 0.5)),
                const SizedBox(height: 4),
                LatexText(_hints[i], style: const TextStyle(fontSize: 13, color: NexaColors.txt2, height: 1.6)),
              ]),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Choices
        if (!_inTextPhase && _result == null) ...[
          const Text('Choisissez votre réponse :',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
          const SizedBox(height: 12),
          ..._choices.asMap().entries.map((entry) {
            final i = entry.key;
            final choice = entry.value;
            final selected = _selectedChoiceId == choice['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedChoiceId = choice['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? NexaColors.blueLight : NexaColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? NexaColors.blue : NexaColors.border, width: selected ? 1.5 : 1),
                ),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: selected ? NexaColors.blue : NexaColors.blueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(child: Text(String.fromCharCode(65 + i),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                        color: selected ? Colors.white : NexaColors.blue))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(choice['label'] ?? '',
                    style: TextStyle(
                      color: selected ? NexaColors.blue : NexaColors.txt,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400))),
                ]),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedChoiceId == null || _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexaColors.blue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Valider', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],

        // Result for this question
        if (_result != null && !_isCompleted) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _result!['isCorrect'] == true ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _result!['isCorrect'] == true ? const Color(0xFF86EFAC) : const Color(0xFFFECACA)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  _result!['isCorrect'] == true ? Icons.check_circle : Icons.cancel,
                  color: _result!['isCorrect'] == true ? NexaColors.green : NexaColors.red, size: 24),
                const SizedBox(width: 8),
                Text(
                  _result!['isCorrect'] == true ? '+${_result!['xpEarned']} XP ! 🎯' : '0 XP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: _result!['isCorrect'] == true ? NexaColors.green : NexaColors.red)),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NexaColors.blueLight, borderRadius: BorderRadius.circular(10),
                  border: const Border(left: BorderSide(color: NexaColors.blue, width: 3)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📋 SOLUTION',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.blue, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  LatexText(_result!['solution'] ?? '',
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: NexaColors.txt2, height: 1.6)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexaColors.blue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'Question suivante (${_currentIndex + 2}/${_questions.length}) →',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [NexaColors.navy, NexaColors.navy3]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('🏁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Concours terminé !',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 8),
            Text('$_totalXp XP gagnés',
              style: const TextStyle(color: NexaColors.gold, fontWeight: FontWeight.w800, fontSize: 28)),
            const SizedBox(height: 4),
            Text('${_questions.length} questions complétées',
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ]),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: widget.onBack,
          style: ElevatedButton.styleFrom(
            backgroundColor: NexaColors.blue, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('← Retour aux concours', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
    );
  }
}