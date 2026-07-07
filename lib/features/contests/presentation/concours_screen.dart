import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';

class ConcoursScreen extends StatefulWidget {
  const ConcoursScreen({super.key});

  @override
  State<ConcoursScreen> createState() => _ConcoursScreenState();
}

class _ConcoursScreenState extends State<ConcoursScreen> {
  List<dynamic> _contests = [];
  bool _loading = true;
  String? _selectedFiliere;
  Map<String, dynamic>? _activeContest;
  Map<String, dynamic>? _activeSession;
  int _currentQuestionIndex = 0;
  bool _loadingDetail = false;

  final List<String> _filieres = ['MP', 'PC', 'TSI', 'BIO', 'TECHNO'];

  final Map<String, Color> _filiereColors = {
    'MP': NexaColors.blue,
    'PC': NexaColors.purple,
    'TSI': NexaColors.green,
    'BIO': const Color(0xFFDB2777),
    'TECHNO': const Color(0xFFD97706),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final contests = await ApiClient.getContests(filiere: _selectedFiliere);
      setState(() => _contests = contests);
    } catch (e) {
      setState(() => _contests = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openContest(String id) async {
    setState(() => _loadingDetail = true);
    try {
      final contest = await ApiClient.getContest(id);
      final session = await ApiClient.startContestSession(id);
      setState(() {
        _activeContest = contest;
        _activeSession = session;
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
    _currentQuestionIndex = 0;
    _load();
  });

  // Group contests by year
  Map<int, List<dynamic>> get _byYear {
    final map = <int, List<dynamic>>{};
    for (final c in _contests) {
      final year = c['annee'] as int;
      map.putIfAbsent(year, () => []).add(c);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
  }

  @override
  Widget build(BuildContext context) {
    if (_activeContest != null && _activeSession != null) {
      return ContestSessionView(
        contest: _activeContest!,
        session: _activeSession!,
        initialQuestionIndex: _currentQuestionIndex,
        onBack: _back,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🏁 Concours Nationaux',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.txt)),
            const Text('Sujets officiels · QCM avec correction instantanée',
              style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
            const SizedBox(height: 14),
            // Filiere filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('Toutes', null),
                const SizedBox(width: 6),
                ..._filieres.map((f) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _chip(f, f),
                )),
              ]),
            ),
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
                  children: _byYear.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [NexaColors.navy, NexaColors.navy3]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('Concours ${entry.key}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Text('${entry.value.length} filière(s)',
                              style: const TextStyle(color: NexaColors.txt3, fontSize: 12)),
                          ]),
                        ),
                        ...entry.value.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: NexaCard(
                            onTap: () => _openContest(c['id']),
                            child: Row(children: [
                              Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  color: (_filiereColors[c['filiere']] ?? NexaColors.blue).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_filiereColors[c['filiere']] ?? NexaColors.blue).withOpacity(0.3)),
                                ),
                                child: Center(
                                  child: Text(c['filiere'] ?? '',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800, fontSize: 13,
                                      color: _filiereColors[c['filiere']] ?? NexaColors.blue,
                                    )),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c['titre'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  NexaTag(
                                    label: c['filiere'] ?? '',
                                    color: _filiereColors[c['filiere']] ?? NexaColors.blue,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('${c['_count']?['questions'] ?? 0} questions',
                                    style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
                                ]),
                              ])),
                              const Icon(Icons.chevron_right, color: NexaColors.txt3),
                            ]),
                          ),
                        )),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String? value) {
    final active = _selectedFiliere == value;
    return GestureDetector(
      onTap: () { setState(() => _selectedFiliere = value); _load(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? NexaColors.blueLight : NexaColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? NexaColors.blue : NexaColors.border),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? NexaColors.blue : NexaColors.txt3,
          )),
      ),
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
          child: Text(q['enonce'] ?? '',
            style: const TextStyle(fontSize: 15, fontFamily: 'monospace', color: NexaColors.txt, height: 1.7)),
        ),
        const SizedBox(height: 20),

        // Hints
        if (_hints.isNotEmpty && _result == null) ...[
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
                Text(_hints[i], style: const TextStyle(fontSize: 13, color: NexaColors.txt2, height: 1.6)),
              ]),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Choices
        if (_result == null) ...[
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
                  Text(_result!['solution'] ?? '',
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