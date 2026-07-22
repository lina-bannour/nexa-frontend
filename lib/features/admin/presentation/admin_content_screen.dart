import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  String _view = 'exercices';
  List<dynamic> _exercises = [];
  List<dynamic> _contests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiClient.getAdminExercises(),
        ApiClient.getAdminContests(),
      ]);
      setState(() {
        _exercises = results[0];
        _contests = results[1];
      });
    } catch (_) {
      setState(() => _error = 'Impossible de charger le contenu.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteExercise(String id) async {
    try {
      await ApiClient.deleteAdminExercise(id);
      if (mounted) { showAdSnack(context, 'Exercice supprimé'); _load(); }
    } catch (_) {
      if (mounted) showAdSnack(context, 'Échec de la suppression', error: true);
    }
  }

  Future<void> _deleteContest(String id) async {
    try {
      await ApiClient.deleteAdminContest(id);
      if (mounted) { showAdSnack(context, 'Concours supprimé'); _load(); }
    } catch (_) {
      if (mounted) showAdSnack(context, 'Échec de la suppression', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: NexaColors.blue));
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: NexaColors.txt2)),
          const SizedBox(height: 12),
          AdBtn(label: 'Réessayer', onPressed: _load),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: NexaColors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: NexaColors.blueLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  _tabBtn('exercices', '📚 Exercices'),
                  _tabBtn('concours', '🏁 Concours'),
                ]),
              ),
              if (_view == 'exercices')
                AdBtn(label: 'Ajouter', icon: Icons.add, small: true, onPressed: _openCreateExercise)
              else if (_view == 'concours')
                AdBtn(label: 'Ajouter', icon: Icons.add, small: true, onPressed: _openCreateContest),
            ],
          ),
          const SizedBox(height: 16),
          if (_view == 'exercices') ..._exercises.map(_exerciseCard) else ..._contests.map(_contestCard),
          if (_view == 'exercices' && _exercises.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun exercice', style: TextStyle(color: NexaColors.txt3)))),
          if (_view == 'concours' && _contests.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun concours', style: TextStyle(color: NexaColors.txt3)))),
        ],
      ),
    );
  }

  Widget _tabBtn(String id, String label) {
    final active = _view == id;
    return GestureDetector(
      onTap: () => setState(() => _view = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: active ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? NexaColors.navy : NexaColors.txt3)),
      ),
    );
  }

  Widget _exerciseCard(dynamic ex) {
    final choix = (ex['choix'] as List<dynamic>? ?? []);
    final attemptsCount = (ex['_count']?['attempts']) ?? 0;
    return AdCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${ex['titre'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _miniTag('${ex['matiere'] ?? ''}', NexaColors.blue),
                      const SizedBox(width: 6),
                      _miniTag('${ex['difficulte'] ?? ''}', NexaColors.purple),
                    ]),
                  ],
                ),
              ),
              Text('${ex['xpBase'] ?? 0} XP', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: NexaColors.gold)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${choix.length} choix · $attemptsCount tentatives', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AdBtn(label: 'Éditer', icon: Icons.edit_outlined, small: true, variant: AdBtnVariant.secondary, onPressed: () => _openEditExercise(ex))),
            const SizedBox(width: 8),
            AdBtn(label: '', icon: Icons.delete_outline, small: true, variant: AdBtnVariant.red, onPressed: () => _confirmDelete(
              title: 'Supprimer cet exercice ?',
              message: '${ex['titre']} sera définitivement supprimé.',
              onConfirm: () => _deleteExercise(ex['id']),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _contestCard(dynamic c) {
    final count = c['_count'] ?? {};
    return AdCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c['titre'] ?? ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(children: [
                      _miniTag('${c['annee'] ?? ''}', NexaColors.navy),
                      const SizedBox(width: 6),
                      _miniTag('${c['filiere'] ?? ''}', NexaColors.blue),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${count['questions'] ?? 0} questions · ${count['sessions'] ?? 0} sessions', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: AdBtn(label: 'Éditer', icon: Icons.edit_outlined, small: true, variant: AdBtnVariant.secondary, onPressed: () => _openEditContest(c))),
            const SizedBox(width: 8),
            AdBtn(label: '', icon: Icons.delete_outline, small: true, variant: AdBtnVariant.red, onPressed: () => _confirmDelete(
              title: 'Supprimer ce concours ?',
              message: '${c['titre']} sera définitivement supprimé.',
              onConfirm: () => _deleteContest(c['id']),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _miniTag(String label, Color color) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _confirmDelete({required String title, required String message, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () { Navigator.of(ctx).pop(); onConfirm(); },
            child: const Text('Supprimer', style: TextStyle(color: NexaColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openEditExercise(dynamic ex) {
    showAdModal(context, title: "Modifier l'exercice", child: _ExerciseFormContent(
      exercise: ex,
      onSaved: () { Navigator.of(context).pop(); _load(); },
    ));
  }

  void _openCreateExercise() {
    showAdModal(context, title: 'Nouvel exercice', child: _ExerciseFormContent(
      exercise: null,
      onSaved: () { Navigator.of(context).pop(); _load(); },
    ));
  }

  void _openEditContest(dynamic c) {
    showAdModal(context, title: 'Modifier le concours', child: _ContestFormContent(
      contest: c,
      onSaved: () { Navigator.of(context).pop(); _load(); },
    ));
  }

  void _openCreateContest() {
    showAdModal(context, title: 'Nouveau concours', child: _CreateContestFormContent(
      onSaved: () { Navigator.of(context).pop(); _load(); },
    ));
  }
}

/// Create/edit form for an exercise. Editing a title/matiere/difficulte/xp
/// doesn't touch the choices; choices are only replaced together (matching
/// the backend, which replaces the whole choice set atomically when
/// provided at all).
class _ExerciseFormContent extends StatefulWidget {
  final dynamic exercise; // null = create
  final VoidCallback onSaved;
  const _ExerciseFormContent({required this.exercise, required this.onSaved});

  @override
  State<_ExerciseFormContent> createState() => _ExerciseFormContentState();
}

class _ExerciseFormContentState extends State<_ExerciseFormContent> {
  late TextEditingController _titre;
  late TextEditingController _enonce;
  late TextEditingController _solution;
  late TextEditingController _xp;
  late TextEditingController _hint1, _hint2;
  String _matiere = 'MATHEMATIQUES';
  String _difficulte = 'UN_ETOILE';
  final List<TextEditingController> _choiceControllers = [];
  int _correctIndex = 0;
  bool _saving = false;

  bool get _isCreate => widget.exercise == null;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _titre = TextEditingController(text: ex?['titre'] ?? '');
    _enonce = TextEditingController(text: ex?['enonce'] ?? '');
    _solution = TextEditingController(text: ex?['solutionDetaillee'] ?? '');
    _xp = TextEditingController(text: '${ex?['xpBase'] ?? 10}');
    _hint1 = TextEditingController(text: ex?['hint1'] ?? '');
    _hint2 = TextEditingController(text: ex?['hint2'] ?? '');
    _matiere = ex?['matiere'] ?? 'MATHEMATIQUES';
    _difficulte = ex?['difficulte'] ?? 'UN_ETOILE';

    final existingChoices = (ex?['choix'] as List<dynamic>?) ?? [];
    if (existingChoices.isNotEmpty) {
      for (var i = 0; i < existingChoices.length; i++) {
        _choiceControllers.add(TextEditingController(text: existingChoices[i]['label'] ?? ''));
        if (existingChoices[i]['isCorrect'] == true) _correctIndex = i;
      }
    } else {
      _choiceControllers.addAll([TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()]);
    }
  }

  Future<void> _save() async {
    final choix = _choiceControllers.asMap().entries
        .where((e) => e.value.text.trim().isNotEmpty)
        .map((e) => {'label': e.value.text.trim(), 'isCorrect': e.key == _correctIndex})
        .toList();

    if (_titre.text.trim().isEmpty || _enonce.text.trim().isEmpty || _solution.text.trim().isEmpty || choix.length < 2) {
      showAdSnack(context, 'Titre, énoncé, solution et au moins 2 choix sont requis', error: true);
      return;
    }
    if (!choix.any((c) => c['isCorrect'] == true)) {
      showAdSnack(context, 'Sélectionnez la bonne réponse', error: true);
      return;
    }

    setState(() => _saving = true);
    final data = {
      'titre': _titre.text.trim(),
      'matiere': _matiere,
      'difficulte': _difficulte,
      'enonce': _enonce.text.trim(),
      'solutionDetaillee': _solution.text.trim(),
      'xpBase': int.tryParse(_xp.text) ?? 10,
      if (_hint1.text.trim().isNotEmpty) 'hint1': _hint1.text.trim(),
      if (_hint2.text.trim().isNotEmpty) 'hint2': _hint2.text.trim(),
      'choix': choix,
    };

    try {
      if (_isCreate) {
        await ApiClient.createExercise(data);
        if (mounted) showAdSnack(context, 'Exercice créé');
      } else {
        await ApiClient.updateAdminExercise(widget.exercise['id'], data);
        if (mounted) showAdSnack(context, 'Exercice mis à jour');
      }
      widget.onSaved();
    } catch (_) {
      if (mounted) { showAdSnack(context, 'Échec de l\'enregistrement', error: true); setState(() => _saving = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdField(label: 'Titre', controller: _titre),
        AdDropdown(label: 'Matière', value: _matiere, options: const ['MATHEMATIQUES', 'PHYSIQUE', 'SCIENCES_INGENIEUR', 'AUTRE'], onChanged: (v) => setState(() => _matiere = v!)),
        AdDropdown(label: 'Difficulté', value: _difficulte, options: const ['UN_ETOILE', 'DEUX_ETOILES', 'TROIS_ETOILES'], onChanged: (v) => setState(() => _difficulte = v!)),
        AdField(label: 'XP de base', controller: _xp, keyboardType: TextInputType.number),
        AdField(label: 'Énoncé', controller: _enonce, maxLines: 3),
        AdField(label: 'Solution détaillée', controller: _solution, maxLines: 3),
        AdField(label: 'Indice 1 (optionnel)', controller: _hint1),
        AdField(label: 'Indice 2 (optionnel)', controller: _hint2),
        const Text('CHOIX (cochez la bonne réponse)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        ..._choiceControllers.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Radio<int>(value: e.key, groupValue: _correctIndex, onChanged: (v) => setState(() => _correctIndex = v!), activeColor: NexaColors.green),
                Expanded(
                  child: TextField(
                    controller: e.value,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Choix ${e.key + 1}',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      filled: true, fillColor: NexaColors.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: NexaColors.border)),
                    ),
                  ),
                ),
              ]),
            )),
        const SizedBox(height: 8),
        AdBtn(label: _isCreate ? 'Créer' : 'Enregistrer', full: true, loading: _saving, onPressed: _save),
      ],
    );
  }
}

/// Edit form for a contest — metadata only (title, year, filière, matière).
/// The backend also supports replacing the full question set via the same
/// PUT, but building a full QCM-question editor is out of scope here; use
/// the exercise-style question builder if that becomes needed later.
class _ContestFormContent extends StatefulWidget {
  final dynamic contest;
  final VoidCallback onSaved;
  const _ContestFormContent({required this.contest, required this.onSaved});

  @override
  State<_ContestFormContent> createState() => _ContestFormContentState();
}

class _ContestFormContentState extends State<_ContestFormContent> {
  late TextEditingController _titre;
  late TextEditingController _annee;
  String _filiere = 'MP';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titre = TextEditingController(text: widget.contest['titre'] ?? '');
    _annee = TextEditingController(text: '${widget.contest['annee'] ?? ''}');
    _filiere = widget.contest['filiere'] ?? 'MP';
  }

  Future<void> _save() async {
    if (_titre.text.trim().isEmpty) {
      showAdSnack(context, 'Le titre est requis', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ApiClient.updateAdminContest(widget.contest['id'], {
        'titre': _titre.text.trim(),
        'annee': int.tryParse(_annee.text) ?? widget.contest['annee'],
        'filiere': _filiere,
      });
      if (mounted) showAdSnack(context, 'Concours mis à jour');
      widget.onSaved();
    } catch (_) {
      if (mounted) { showAdSnack(context, 'Échec de l\'enregistrement', error: true); setState(() => _saving = false); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdField(label: 'Titre', controller: _titre),
        AdField(label: 'Année', controller: _annee, keyboardType: TextInputType.number),
        AdDropdown(label: 'Filière', value: _filiere, options: const ['MP', 'PC', 'TSI', 'BIO', 'TECHNO'], onChanged: (v) => setState(() => _filiere = v!)),
        const SizedBox(height: 8),
        AdBtn(label: 'Enregistrer', full: true, loading: _saving, onPressed: _save),
      ],
    );
  }
}

class _CreateContestFormContent extends StatefulWidget {
  final VoidCallback onSaved;
  const _CreateContestFormContent({required this.onSaved});

  @override
  State<_CreateContestFormContent> createState() => _CreateContestFormContentState();
}

class _CreateContestFormContentState extends State<_CreateContestFormContent> {
  final _titre = TextEditingController();
  final _annee = TextEditingController(text: '${DateTime.now().year}');
  String _filiere = 'MP';
  String _matiere = 'MATHEMATIQUES';
  bool _saving = false;

  final List<_ContestQuestionInput> _questions = [];

  void _addQuestion() {
    setState(() {
      _questions.add(_ContestQuestionInput(
        enonceController: TextEditingController(),
        solutionController: TextEditingController(),
        xpController: TextEditingController(text: '10'),
        hint1Controller: TextEditingController(),
        hint2Controller: TextEditingController(),
        choiceControllers: [
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ],
        correctIndex: 0,
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  @override
  void dispose() {
    _titre.dispose();
    _annee.dispose();
    for (var q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final titleText = _titre.text.trim();
    final yearVal = int.tryParse(_annee.text) ?? DateTime.now().year;

    if (titleText.isEmpty) {
      showAdSnack(context, 'Le titre est requis', error: true);
      return;
    }

    if (_questions.isEmpty) {
      showAdSnack(context, 'Ajoutez au moins une question', error: true);
      return;
    }

    final List<Map<String, dynamic>> questionDataList = [];
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final enonce = q.enonceController.text.trim();
      final solution = q.solutionController.text.trim();
      final xpBase = int.tryParse(q.xpController.text) ?? 10;

      if (enonce.isEmpty || solution.isEmpty) {
        showAdSnack(context, 'Veuillez remplir l\'énoncé et la solution de la question ${i + 1}', error: true);
        return;
      }

      final choices = q.choiceControllers.asMap().entries
          .where((e) => e.value.text.trim().isNotEmpty)
          .map((e) => {'label': e.value.text.trim(), 'isCorrect': e.key == q.correctIndex})
          .toList();

      if (choices.length < 2) {
        showAdSnack(context, 'La question ${i + 1} doit avoir au moins 2 choix', error: true);
        return;
      }

      questionDataList.add({
        'ordre': i + 1,
        'enonce': enonce,
        'solutionDetaillee': solution,
        'xpBase': xpBase,
        if (q.hint1Controller.text.trim().isNotEmpty) 'hint1': q.hint1Controller.text.trim(),
        if (q.hint2Controller.text.trim().isNotEmpty) 'hint2': q.hint2Controller.text.trim(),
        'choix': choices,
      });
    }

    setState(() => _saving = true);

    try {
      await ApiClient.createContest({
        'titre': titleText,
        'annee': yearVal,
        'filiere': _filiere,
        'matiere': _matiere,
        'questions': questionDataList,
      });
      if (mounted) showAdSnack(context, 'Concours créé avec succès');
      widget.onSaved();
    } catch (e) {
      if (mounted) {
        showAdSnack(context, 'Échec de la création du concours', error: true);
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdField(label: 'Titre du Concours', controller: _titre),
        AdField(label: 'Année', controller: _annee, keyboardType: TextInputType.number),
        AdDropdown(label: 'Filière', value: _filiere, options: const ['MP', 'PC', 'TSI', 'BIO', 'TECHNO'], onChanged: (v) => setState(() => _filiere = v!)),
        AdDropdown(label: 'Matière', value: _matiere, options: const ['MATHEMATIQUES', 'PHYSIQUE', 'SCIENCES_INGENIEUR', 'AUTRE'], onChanged: (v) => setState(() => _matiere = v!)),
        
        const SizedBox(height: 16),
        const Text(
          'QUESTIONS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: NexaColors.navy),
        ),
        const SizedBox(height: 8),

        ..._questions.asMap().entries.map((entry) {
          final idx = entry.key;
          final q = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: NexaColors.blueLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NexaColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Question ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (_questions.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete, color: NexaColors.red, size: 20),
                        onPressed: () => setState(() => _questions.removeAt(idx)),
                      )
                  ],
                ),
                AdField(label: 'Énoncé de la question', controller: q.enonceController),
                AdField(label: 'Solution détaillée', controller: q.solutionController),
                AdField(label: 'XP Base', controller: q.xpController, keyboardType: TextInputType.number),
                AdField(label: 'Indice 1 (optionnel)', controller: q.hint1Controller),
                AdField(label: 'Indice 2 (optionnel)', controller: q.hint2Controller),
                const SizedBox(height: 8),
                const Text('Choix (cochez le correct) :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ...q.choiceControllers.asMap().entries.map((choiceEntry) {
                  final cIdx = choiceEntry.key;
                  final cCtrl = choiceEntry.value;
                  return Row(
                    children: [
                      Radio<int>(
                        value: cIdx,
                        groupValue: q.correctIndex,
                        onChanged: (val) => setState(() => q.correctIndex = val!),
                        activeColor: NexaColors.green,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextField(
                            controller: cCtrl,
                            decoration: InputDecoration(
                              hintText: 'Choix ${cIdx + 1}',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      )
                    ],
                  );
                }),
              ],
            ),
          );
        }),

        AdBtn(
          label: 'Ajouter une question',
          icon: Icons.add,
          variant: AdBtnVariant.secondary,
          onPressed: _addQuestion,
          full: true,
        ),
        const SizedBox(height: 16),
        AdBtn(
          label: 'Créer le concours',
          full: true,
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}

class _ContestQuestionInput {
  final TextEditingController enonceController;
  final TextEditingController solutionController;
  final TextEditingController xpController;
  final TextEditingController hint1Controller;
  final TextEditingController hint2Controller;
  final List<TextEditingController> choiceControllers;
  int correctIndex;

  _ContestQuestionInput({
    required this.enonceController,
    required this.solutionController,
    required this.xpController,
    required this.hint1Controller,
    required this.hint2Controller,
    required this.choiceControllers,
    required this.correctIndex,
  });

  void dispose() {
    enonceController.dispose();
    solutionController.dispose();
    xpController.dispose();
    hint1Controller.dispose();
    hint2Controller.dispose();
    for (var c in choiceControllers) {
      c.dispose();
    }
  }
}
