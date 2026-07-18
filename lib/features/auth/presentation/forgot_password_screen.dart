import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';

/// Two-step password reset flow:
///  1. Enter email -> POST /auth/forgot-password (always succeeds silently,
///     the backend never reveals whether the email exists)
///  2. Enter the 6-digit code from the email + a new password
///     -> POST /auth/reset-password
class ForgotPasswordScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ForgotPasswordScreen({super.key, required this.onDone});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  bool _success = false;
  String? _error;

  Future<void> _sendCode() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() => _error = 'Merci de saisir votre email');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.forgotPassword(_emailController.text.trim());
      setState(() => _codeSent = true);
    } catch (_) {
      // Backend never reveals whether the email exists — so any error here
      // is a real problem (network, server down), not "email not found".
      setState(() => _error = 'Une erreur est survenue. Réessayez.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_codeController.text.trim().length != 6 || _newPasswordController.text.length < 6) {
      setState(() => _error = 'Vérifiez le code (6 chiffres) et le mot de passe (6+ caractères)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.resetPassword(
        _emailController.text.trim(),
        _codeController.text.trim(),
        _newPasswordController.text,
      );
      setState(() => _success = true);
    } catch (_) {
      setState(() => _error = 'Code invalide ou expiré. Vérifiez et réessayez.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexaColors.navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                ),
                child: _success ? _successView() : (_codeSent ? _codeStepView() : _emailStepView()),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onDone,
                child: const Text('Retour à la connexion',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emailStepView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Mot de passe oublié',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.navy)),
        const SizedBox(height: 8),
        const Text('Saisissez votre email, on vous envoie un code de vérification.',
            style: TextStyle(color: NexaColors.txt2, fontSize: 13)),
        const SizedBox(height: 20),
        _field(_emailController, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
        if (_error != null) _errorBanner(),
        const SizedBox(height: 20),
        _primaryButton('Envoyer le code', _sendCode),
      ],
    );
  }

  Widget _codeStepView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Nouveau mot de passe',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.navy)),
        const SizedBox(height: 8),
        Text('Un code a été envoyé à ${_emailController.text.trim()}.',
            style: const TextStyle(color: NexaColors.txt2, fontSize: 13)),
        const SizedBox(height: 20),
        _field(_codeController, 'Code à 6 chiffres', Icons.pin_outlined,
            type: TextInputType.number, maxLength: 6),
        const SizedBox(height: 12),
        _field(_newPasswordController, 'Nouveau mot de passe', Icons.lock_outlined, obscure: true),
        if (_error != null) _errorBanner(),
        const SizedBox(height: 20),
        _primaryButton('Réinitialiser', _resetPassword),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : _sendCode,
          child: const Text('Renvoyer le code', style: TextStyle(color: NexaColors.blue)),
        ),
      ],
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.check_circle, color: NexaColors.green, size: 48),
        const SizedBox(height: 16),
        const Text('Mot de passe mis à jour',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: NexaColors.navy),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Vous pouvez maintenant vous reconnecter avec votre nouveau mot de passe.',
            style: TextStyle(color: NexaColors.txt2, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        _primaryButton('Retour à la connexion', widget.onDone),
      ],
    );
  }

  Widget _errorBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
        child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: NexaColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool obscure = false, int? maxLength}) {
    return TextField(
      controller: c,
      keyboardType: type,
      obscureText: obscure,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        counterText: '',
      ),
    );
  }
}
