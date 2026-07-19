import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic>? _settings;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  late TextEditingController _platformName;
  late TextEditingController _supportEmail;
  late TextEditingController _websiteUrl;
  late TextEditingController _xpDirectAnswer;
  late TextEditingController _xpForumPost;
  late TextEditingController _xpForumReply;
  late TextEditingController _penalty1, _penalty2, _penalty3, _penalty4;
  bool _maintenanceMode = false;

  @override
  void initState() {
    super.initState();
    _platformName = TextEditingController();
    _supportEmail = TextEditingController();
    _websiteUrl = TextEditingController();
    _xpDirectAnswer = TextEditingController();
    _xpForumPost = TextEditingController();
    _xpForumReply = TextEditingController();
    _penalty1 = TextEditingController();
    _penalty2 = TextEditingController();
    _penalty3 = TextEditingController();
    _penalty4 = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final s = await ApiClient.getAdminSettings();
      setState(() {
        _settings = s;
        _platformName.text = '${s['platformName'] ?? ''}';
        _supportEmail.text = '${s['supportEmail'] ?? ''}';
        _websiteUrl.text = '${s['websiteUrl'] ?? ''}';
        _xpDirectAnswer.text = '${s['xpPerDirectAnswer'] ?? 10}';
        _xpForumPost.text = '${s['xpPerForumPost'] ?? 3}';
        _xpForumReply.text = '${s['xpPerForumReply'] ?? 1}';
        _penalty1.text = '${s['hintPenaltyPercent1'] ?? 10}';
        _penalty2.text = '${s['hintPenaltyPercent2'] ?? 20}';
        _penalty3.text = '${s['hintPenaltyPercent3'] ?? 30}';
        _penalty4.text = '${s['hintPenaltyPercent4'] ?? 40}';
        _maintenanceMode = s['maintenanceMode'] == true;
      });
    } catch (_) {
      setState(() => _error = 'Impossible de charger les paramètres.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.updateAdminSettings({
        'platformName': _platformName.text.trim(),
        'supportEmail': _supportEmail.text.trim(),
        'websiteUrl': _websiteUrl.text.trim(),
        'xpPerDirectAnswer': int.tryParse(_xpDirectAnswer.text) ?? 10,
        'xpPerForumPost': int.tryParse(_xpForumPost.text) ?? 3,
        'xpPerForumReply': int.tryParse(_xpForumReply.text) ?? 1,
        'hintPenaltyPercent1': int.tryParse(_penalty1.text) ?? 10,
        'hintPenaltyPercent2': int.tryParse(_penalty2.text) ?? 20,
        'hintPenaltyPercent3': int.tryParse(_penalty3.text) ?? 30,
        'hintPenaltyPercent4': int.tryParse(_penalty4.text) ?? 40,
      });
      if (mounted) showAdSnack(context, 'Paramètres enregistrés');
    } catch (_) {
      if (mounted) showAdSnack(context, "Échec de l'enregistrement", error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleMaintenance(bool value) async {
    final previous = _maintenanceMode;
    setState(() => _maintenanceMode = value);
    try {
      await ApiClient.updateMaintenanceMode(value);
      if (mounted) {
        showAdSnack(context, value ? 'Mode maintenance activé' : 'Mode maintenance désactivé', error: value);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _maintenanceMode = previous);
        showAdSnack(context, 'Échec du changement de mode', error: true);
      }
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Maintenance mode — most consequential toggle, placed first
        AdCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🚧 Mode maintenance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                          _maintenanceMode ? "L'application est actuellement fermée aux étudiants." : 'Application accessible normalement.',
                          style: TextStyle(fontSize: 11, color: _maintenanceMode ? NexaColors.red : NexaColors.txt3),
                        ),
                      ],
                    ),
                  ),
                  Switch(value: _maintenanceMode, onChanged: _toggleMaintenance, activeColor: NexaColors.red),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AdCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌐 Général', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              AdField(label: 'Nom de la plateforme', controller: _platformName),
              AdField(label: 'URL plateforme', controller: _websiteUrl),
              AdField(label: 'Contact support', controller: _supportEmail, keyboardType: TextInputType.emailAddress),
            ],
          ),
        ),
        const SizedBox(height: 14),

        AdCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎮 Gamification', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 12),
              AdField(label: 'XP par réponse directe', controller: _xpDirectAnswer, keyboardType: TextInputType.number),
              AdField(label: 'XP par post forum', controller: _xpForumPost, keyboardType: TextInputType.number),
              AdField(label: 'XP par réponse forum', controller: _xpForumReply, keyboardType: TextInputType.number),
              const Text('PÉNALITÉ PAR INDICE UTILISÉ (%)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 0.6)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: _smallNumField('1er', _penalty1)),
                const SizedBox(width: 8),
                Expanded(child: _smallNumField('2e', _penalty2)),
                const SizedBox(width: 8),
                Expanded(child: _smallNumField('3e', _penalty3)),
                const SizedBox(width: 8),
                Expanded(child: _smallNumField('4e', _penalty4)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AdBtn(label: '💾 Enregistrer les modifications', full: true, loading: _saving, onPressed: _save),
      ],
    );
  }

  Widget _smallNumField(String label, TextEditingController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
        const SizedBox(height: 4),
        TextField(
          controller: c,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
            filled: true, fillColor: NexaColors.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: NexaColors.border)),
          ),
        ),
      ],
    );
  }
}
