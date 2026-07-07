import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<dynamic> _exercises = [];
  bool _loading = true;
  String? _selectedMatiere;
  Map<String, dynamic>? _activeExercise;
  bool _loadingDetail = false;

  final Map<String, String> _matiereLabels = {
    'MATHEMATIQUES': 'Maths',
    'PHYSIQUE': 'Physique',
    'SCIENCES_INGENIEUR': 'SI',
    'AUTRE': 'Autre',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ex = await ApiClient.getExercises(matiere: _selectedMatiere);
      setState(() => _exercises = ex);
    } catch (e) {
      setState(() => _exercises = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openExercise(String id) async {
    setState(() => _loadingDetail = true);
    try {
      final ex = await ApiClient.getExercise(id);
      setState(() => _activeExercise = ex);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur de chargement')));
      }
    } finally {
      setState(() => _loadingDetail = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeExercise != null) {
      return ExerciseDetailView(
        exercise: _activeExercise!,
        onBack: () => setState(() => _activeExercise = null),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📚 Exercices',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.txt)),
            const Text('4 indices progressifs → QCM → Solution',
              style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _filterChip('Tout', null),
                const SizedBox(width: 6),
                ..._matiereLabels.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _filterChip(e.value, e.key),
                )),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _loading || _loadingDetail
            ? const Center(child: CircularProgressIndicator())
            : _exercises.isEmpty
              ? const Center(child: Text('Aucun exercice disponible'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _exercises.length,
                  itemBuilder: (_, i) {
                    final ex = _exercises[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NexaCard(
                        onTap: () => _openExercise(ex['id']),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(ex['titre'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
                            const SizedBox(height: 4),
                            Text(_matiereLabels[ex['matiere']] ?? ex['matiere'],
                              style: const TextStyle(color: NexaColors.txt3, fontSize: 12)),
                            const SizedBox(height: 8),
                            DifficultyStars(difficulte: ex['difficulte'] ?? 'UN_ETOILE'),
                          ])),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: NexaColors.goldLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('+${ex['xpBase']} XP',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFFB45309))),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String? value) {
    final active = _selectedMatiere == value;
    return GestureDetector(
      onTap: () { setState(() => _selectedMatiere = value); _load(); },
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

// ─── Exercise Detail ─────────────────────────────────────────────────────────

class ExerciseDetailView extends StatefulWidget {
  final Map<String, dynamic> exercise;
  final VoidCallback onBack;

  const ExerciseDetailView({
    super.key,
    required this.exercise,
    required this.onBack,
  });

  @override
  State<ExerciseDetailView> createState() => _ExerciseDetailViewState();
}

class _ExerciseDetailViewState extends State<ExerciseDetailView> {
  int _hintsRevealed = 0;
  String? _selectedChoiceId;
  Map<String, dynamic>? _result;
  bool _submitting = false;

  List<String> get _hints {
    final ex = widget.exercise;
    return [ex['hint1'], ex['hint2'], ex['hint3'], ex['hint4']]
        .where((h) => h != null)
        .cast<String>()
        .toList();
  }

  List<Map<String, dynamic>> get _choices {
    return List<Map<String, dynamic>>.from(widget.exercise['choix'] ?? []);
  }

  int get _expectedXp {
    final xpBase = widget.exercise['xpBase'] ?? 10;
    final penalties = [0, 10, 20, 30, 40];
    final penalty = penalties[_hintsRevealed.clamp(0, 4)];
    return (xpBase * (1 - penalty / 100)).floor();
  }

  Future<void> _submit() async {
    if (_selectedChoiceId == null) return;
    setState(() => _submitting = true);
    try {
      final result = await ApiClient.submitAnswer(
        widget.exercise['id'],
        _selectedChoiceId!,
        _hintsRevealed,
      );
      setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la soumission')));
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final xpBase = ex['xpBase'] ?? 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // Back button
        GestureDetector(
          onTap: widget.onBack,
          child: const Row(children: [
            Icon(Icons.arrow_back_ios, size: 14, color: NexaColors.txt3),
            Text('Exercices', style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 14),

        // Title + XP
        Text(ex['titre'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: NexaColors.txt)),
        const SizedBox(height: 8),
        Row(children: [
          DifficultyStars(difficulte: ex['difficulte'] ?? 'UN_ETOILE'),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: NexaColors.goldLight,
              borderRadius: BorderRadius.circular(20),
            ),
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
        const SizedBox(height: 16),

        // Enonce
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NexaColors.blueLight,
            borderRadius: BorderRadius.circular(12),
            border: const Border(left: BorderSide(color: NexaColors.blue, width: 4)),
          ),
          child: Text(ex['enonce'] ?? '',
            style: const TextStyle(
              fontSize: 15, fontFamily: 'monospace',
              color: NexaColors.txt, height: 1.7,
            )),
        ),
        const SizedBox(height: 20),

        // ── HINTS SECTION (always shown if hints exist and not submitted) ──
        if (_hints.isNotEmpty && _result == null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Indices (${_hintsRevealed}/${_hints.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: NexaColors.txt),
              ),
              // ── THE HINT BUTTON ──
              if (_hintsRevealed < _hints.length)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _hintsRevealed++),
                  icon: const Icon(Icons.lightbulb_outline, size: 16),
                  label: Text('Indice ${_hintsRevealed + 1} (-10% XP)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NexaColors.blue,
                    side: const BorderSide(color: NexaColors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                )
              else
                const NexaTag(label: 'Tous les indices utilisés', color: NexaColors.txt3),
            ],
          ),
          const SizedBox(height: 10),

          // Revealed hints
          ...List.generate(_hintsRevealed, (i) {
            final hintColors = [
              NexaColors.blue,
              NexaColors.purple,
              const Color(0xFFD97706),
              NexaColors.red,
            ];
            final hintBgs = [
              NexaColors.blueLight,
              NexaColors.purpleLight,
              const Color(0xFFFEF3C7),
              const Color(0xFFFEF2F2),
            ];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: hintBgs[i % hintBgs.length],
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                border: Border(
                  left: BorderSide(color: hintColors[i % hintColors.length], width: 3),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  'INDICE ${i + 1}${i == 3 ? " (FINAL)" : ""}  •  -10% XP',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: hintColors[i % hintColors.length],
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_hints[i],
                  style: const TextStyle(
                    fontSize: 13, color: NexaColors.txt2, height: 1.6)),
              ]),
            );
          }),
          const SizedBox(height: 16),
        ],

        // ── QCM CHOICES (shown before submission) ──
        if (_result == null) ...[
          const Text('Choisissez votre réponse :',
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
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
                  border: Border.all(
                    color: selected ? NexaColors.blue : NexaColors.border,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: selected ? NexaColors.blue : NexaColors.blueLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + i),
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12,
                          color: selected ? Colors.white : NexaColors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(choice['label'] ?? '',
                      style: TextStyle(
                        color: selected ? NexaColors.blue : NexaColors.txt,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      )),
                  ),
                ]),
              ),
            );
          }),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedChoiceId == null || _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexaColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                : const Text('Valider ma réponse',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],

        // ── RESULT ──
        if (_result != null) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _result!['isCorrect'] == true
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _result!['isCorrect'] == true
                  ? const Color(0xFF86EFAC)
                  : const Color(0xFFFECACA),
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(
                  _result!['isCorrect'] == true
                    ? Icons.check_circle
                    : Icons.cancel,
                  color: _result!['isCorrect'] == true
                    ? NexaColors.green
                    : NexaColors.red,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  _result!['isCorrect'] == true
                    ? '+${_result!['xpEarned']} XP gagné ! 🎯'
                    : 'Mauvaise réponse — 0 XP',
                  style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: _result!['isCorrect'] == true
                      ? NexaColors.green
                      : NexaColors.red,
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NexaColors.blueLight,
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: NexaColors.blue, width: 4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('📋 SOLUTION',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: NexaColors.blue, letterSpacing: 1,
                    )),
                  const SizedBox(height: 8),
                  Text(_result!['solution'] ?? '',
                    style: const TextStyle(
                      fontSize: 13, fontFamily: 'monospace',
                      color: NexaColors.txt2, height: 1.7,
                    )),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onBack,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('← Retour aux exercices'),
            ),
          ),
        ],
      ]),
    );
  }
}