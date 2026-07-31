import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';

// Écran "Modifier mon compte" — permet à l'étudiant de mettre à jour son
// nom, prénom, école et sa filière (PUT /users/me), ainsi que de changer
// son mot de passe (PATCH /users/me/password, via un dialogue dédié).
// L'email n'est pas modifiable ici (pas de flux de re-vérification associé).
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? profile;

  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _ecoleController = TextEditingController();
  String? _selectedFiliere;

  bool _saving = false;
  String? _error;

  final List<String> _filieres = ['MP', 'PT', 'PC', 'BG'];

  @override
  void initState() {
    super.initState();
    _nomController.text = (widget.profile?['nom'] as String?) ?? '';
    _prenomController.text = (widget.profile?['prenom'] as String?) ?? '';
    _ecoleController.text = (widget.profile?['ecole'] as String?) ?? '';
    final currentFiliere = widget.profile?['filiere'] as String?;
    if (currentFiliere != null && _filieres.contains(currentFiliere)) {
      _selectedFiliere = currentFiliere;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _ecoleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ApiClient.updateProfile(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        ecole: _ecoleController.text.trim(),
        filiere: _selectedFiliere,
      );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: NexaColors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Impossible de mettre à jour le profil. Réessayez.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openChangePasswordDialog() async {
    await showDialog(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.profile?['email'] ?? '';

    return Scaffold(
      backgroundColor: NexaColors.bg,
      appBar: AppBar(
        title: const Text('Modifier mon compte'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'INFORMATIONS PERSONNELLES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1),
                ),
                const SizedBox(height: 12),

                _field(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez indiquer votre prénom' : null,
                ),
                const SizedBox(height: 16),
                _field(
                  controller: _nomController,
                  label: 'Nom',
                  icon: Icons.person_outline,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez indiquer votre nom' : null,
                ),
                const SizedBox(height: 16),

                // Email affiché à titre indicatif, non modifiable ici.
                TextFormField(
                  initialValue: email,
                  enabled: false,
                  style: const TextStyle(fontSize: 14, color: NexaColors.txt3, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: NexaColors.txt3, fontSize: 13),
                    prefixIcon: const Icon(Icons.email_outlined, size: 20, color: NexaColors.txt3),
                    filled: true,
                    fillColor: NexaColors.bg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'ÉTUDES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1),
                ),
                const SizedBox(height: 12),

                _field(
                  controller: _ecoleController,
                  label: 'École',
                  icon: Icons.school_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez indiquer votre école' : null,
                ),
                const SizedBox(height: 16),
                _filiereDropdown(),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: NexaColors.red, fontSize: 13)),
                ],

                const SizedBox(height: 28),
                NexaButton(
                  label: _saving ? 'Enregistrement...' : 'Enregistrer les modifications',
                  fullWidth: true,
                  onPressed: _saving ? null : _save,
                ),

                const SizedBox(height: 24),
                const Divider(color: NexaColors.border),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openChangePasswordDialog,
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Changer mon mot de passe'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NexaColors.txt2,
                    side: const BorderSide(color: NexaColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: NexaColors.txt, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: NexaColors.txt3, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: NexaColors.txt3),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.red, width: 1),
        ),
      ),
    );
  }

  Widget _filiereDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFiliere,
      decoration: InputDecoration(
        labelText: 'Filière',
        labelStyle: const TextStyle(color: NexaColors.txt3, fontSize: 13),
        prefixIcon: const Icon(Icons.category_outlined, size: 20, color: NexaColors.txt3),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.blue, width: 1.5),
        ),
      ),
      items: _filieres.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
      validator: (v) => v == null ? 'Veuillez sélectionner une filière' : null,
      onChanged: (v) => setState(() => _selectedFiliere = v),
    );
  }
}

// Dialogue autonome pour le changement de mot de passe : mot de passe
// actuel + nouveau + confirmation, avec la même validation (>= 6
// caractères) que l'inscription côté backend.
class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _saving = false;
  String? _error;
  bool _obscureCurrent = true;
  bool _obscureNew = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mot de passe modifié avec succès'),
          backgroundColor: NexaColors.green,
        ),
      );
    } catch (e) {
      setState(() {
        // Le backend renvoie 400 si le mot de passe actuel est incorrect ;
        // on garde un message générique côté UI pour rester simple.
        _error = 'Mot de passe actuel incorrect ou erreur réseau.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Changer mon mot de passe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Au moins 6 caractères' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureNew,
                decoration: const InputDecoration(labelText: 'Confirmer le nouveau mot de passe'),
                validator: (v) => (v != _newController.text) ? 'Les mots de passe ne correspondent pas' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: NexaColors.red, fontSize: 13)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Enregistrement...' : 'Confirmer'),
        ),
      ],
    );
  }
}
