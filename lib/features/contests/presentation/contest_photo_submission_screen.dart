import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';

/// "Solve on paper, submit a photo" mode — alternative to the interactive
/// QCM. The student downloads/consults the official subject, solves it on
/// paper, then photographs their work and sends it here.
///
/// NOTE: this screen only gets the photo captured and uploaded. Reviewing
/// and grading submitted photos (an admin-side workflow) is separate future
/// work, not built here — submissions just sit as PENDING until then.
class ContestPhotoSubmissionScreen extends StatefulWidget {
  final Map<String, dynamic> contest;
  final VoidCallback onBack;
  const ContestPhotoSubmissionScreen({super.key, required this.contest, required this.onBack});

  @override
  State<ContestPhotoSubmissionScreen> createState() => _ContestPhotoSubmissionScreenState();
}

class _ContestPhotoSubmissionScreenState extends State<ContestPhotoSubmissionScreen> {
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _existingSubmission;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    try {
      final sub = await ApiClient.getMyContestPhotoSubmission(widget.contest['id']);
      if (mounted) setState(() => _existingSubmission = sub);
    } catch (_) {
      // No submission yet, or the request failed — treat as "not submitted".
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Libellés d'affichage pour les codes stockés côté backend.
  static const Map<String, String> _filiereLabels = {
    'MP': 'Maths-Physique',
    'PT': 'Physique-Technologie',
    'PC': 'Physique-Chimie',
    'BG': 'Biologie-Géologie',
  };

  static const Map<String, String> _matiereLabels = {
    'MATHEMATIQUES': 'Mathématiques',
    'PHYSIQUE': 'Physique',
    'SCIENCES_INGENIEUR': 'Sciences de l\'Ingénieur',
    'AUTRE': 'Autre',
  };

  String? get _filiere => widget.contest['filiere'] as String?;
  String? get _matiere => widget.contest['matiere'] as String?;
  String get _filiereLabel => _filiereLabels[_filiere] ?? _filiere ?? '';
  String get _matiereLabel => _matiereLabels[_matiere] ?? _matiere ?? '';

  // Portail officiel : IPEIS — "Sujets et corrections" des concours
  // nationaux d'entrée aux cycles d'ingénieurs. La page classe les épreuves
  // par spécialité (onglets Maths-Physique / Physique-Chimie / Technologie /
  // Biologie-Géologie), puis par session et par matière. On transmet ces
  // trois informations en paramètres (utile si le site les exploite un
  // jour) et on les affiche aussi à l'écran, pour que l'étudiant sache
  // directement quel onglet/session/matière chercher une fois sur la page.
  String get _officialSubjectUrl {
    final annee = widget.contest['annee'];
    final uri = Uri.parse('https://ipeis.rnu.tn/fra/s1347/pages/448/Sujets-et-corrections');
    return uri.replace(queryParameters: {
      if (_filiere != null) 'filiere': _filiere,
      if (annee != null) 'annee': '$annee',
      if (_matiere != null) 'matiere': _matiere,
    }).toString();
  }

  Future<void> _openOfficialSubject() async {
    final uri = Uri.parse(_officialSubjectUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir le lien.")));
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
      if (picked != null) setState(() => _pickedImage = File(picked.path));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'accéder à l'image.")));
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: NexaColors.blue),
              title: const Text('Prendre une photo'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: NexaColors.blue),
              title: const Text('Choisir depuis la galerie'),
              onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_pickedImage == null) return;
    setState(() => _submitting = true);
    try {
      final bytes = await _pickedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final submission = await ApiClient.submitContestPhoto(widget.contest['id'], base64Image);
      if (mounted) setState(() => _existingSubmission = submission);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de l'envoi. Réessayez.")));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contest = widget.contest;
    return Scaffold(
      backgroundColor: NexaColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${contest['titre'] ?? 'Concours'}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NexaColors.txt),
                        overflow: TextOverflow.ellipsis),
                      const Text('Résoudre sur papier',
                        style: TextStyle(fontSize: 12, color: NexaColors.txt3)),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              child: _loading
                ? const Center(child: CircularProgressIndicator(color: NexaColors.blue))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _officialSubjectCard(),
                      const SizedBox(height: 16),
                      if (_existingSubmission != null)
                        _submissionStatusCard(_existingSubmission!)
                      else
                        _uploadSection(),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _officialSubjectCard() {
    final annee = widget.contest['annee'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NexaCard(
          onTap: _openOfficialSubject,
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: NexaColors.blueLight, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Text('📄', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voir le sujet officiel', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
                    const SizedBox(height: 2),
                    const Text('IPEIS · Sujets et corrections des concours nationaux',
                      style: TextStyle(fontSize: 11.5, color: NexaColors.txt3)),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, size: 18, color: NexaColors.blue),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // La page officielle liste tout par onglets ; on rappelle ici
        // précisément quoi y chercher (spécialité / session / matière).
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            if (_filiere != null) _infoChip('Spécialité', _filiereLabel),
            if (annee != null) _infoChip('Session', '$annee'),
            if (_matiere != null) _infoChip('Matière', _matiereLabel),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Sur le site officiel, sélectionnez cet onglet de spécialité puis cette session pour retrouver l\'épreuve et sa correction.',
          style: TextStyle(fontSize: 11, color: NexaColors.txt3, height: 1.4),
        ),
      ],
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: NexaColors.blueLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label : $value',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.blue),
      ),
    );
  }

  Widget _uploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Envoyez une photo de votre copie',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NexaColors.txt)),
        const SizedBox(height: 4),
        const Text('Une fois le sujet résolu sur papier, prenez une photo claire et lisible de votre travail.',
          style: TextStyle(fontSize: 12.5, color: NexaColors.txt3)),
        const SizedBox(height: 14),

        GestureDetector(
          onTap: _showPickerOptions,
          child: Container(
            width: double.infinity,
            height: _pickedImage != null ? 260 : 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NexaColors.border, style: BorderStyle.solid),
            ),
            clipBehavior: Clip.antiAlias,
            child: _pickedImage != null
              ? Stack(fit: StackFit.expand, children: [
                  Image.file(_pickedImage!, fit: BoxFit.cover),
                  Positioned(
                    right: 8, top: 8,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _showPickerOptions,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ),
                ])
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 32, color: NexaColors.txt3),
                      SizedBox(height: 8),
                      Text('Ajouter une photo', style: TextStyle(color: NexaColors.txt3, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
          ),
        ),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_pickedImage == null || _submitting) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: NexaColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Envoyer ma copie', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _submissionStatusCard(Map<String, dynamic> submission) {
    final status = '${submission['status'] ?? 'PENDING'}';
    final isPending = status == 'PENDING';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(isPending ? Icons.hourglass_top_rounded : Icons.check_circle,
              color: isPending ? NexaColors.gold : NexaColors.green, size: 22),
            const SizedBox(width: 10),
            Text(isPending ? 'Copie envoyée' : 'Copie corrigée',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NexaColors.txt)),
          ]),
          const SizedBox(height: 8),
          Text(
            isPending
              ? 'Votre copie est en attente de correction. Vous serez notifié dès qu\'elle sera examinée.'
              : (submission['note'] != null && '${submission['note']}'.isNotEmpty
                  ? '${submission['note']}'
                  : 'Votre copie a été corrigée.'),
            style: const TextStyle(fontSize: 13, color: NexaColors.txt2),
          ),
        ],
      ),
    );
  }
}
