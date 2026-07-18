import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';

/// Shown right after registration (the account is created unverified but the
/// user is still signed in immediately, matching the backend's behavior).
/// Verification isn't required to use the app, so this screen can be
/// skipped — it just nudges the user to confirm their email.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final VoidCallback onDone;
  const VerifyEmailScreen({super.key, required this.email, required this.onDone});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  bool _success = false;
  String? _error;
  String? _info;

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _error = 'Le code doit contenir 6 chiffres');
      return;
    }
    setState(() { _loading = true; _error = null; _info = null; });
    try {
      await ApiClient.verifyEmail(widget.email, _codeController.text.trim());
      setState(() => _success = true);
    } catch (_) {
      setState(() => _error = 'Code invalide ou expiré. Réessayez ou renvoyez un code.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _error = null; _info = null; });
    try {
      await ApiClient.resendVerification(widget.email);
      setState(() => _info = 'Un nouveau code a été envoyé.');
    } catch (_) {
      setState(() => _error = 'Impossible de renvoyer le code pour le moment.');
    } finally {
      setState(() => _resending = false);
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
                child: _success ? _successView() : _codeView(),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onDone,
                child: const Text('Plus tard', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_unread_outlined, color: NexaColors.blue, size: 40),
        const SizedBox(height: 12),
        const Text('Vérifiez votre email',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.navy)),
        const SizedBox(height: 8),
        Text('Un code à 6 chiffres a été envoyé à ${widget.email}.',
            style: const TextStyle(color: NexaColors.txt2, fontSize: 13)),
        const SizedBox(height: 20),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8)),
            child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
          ),
        ],
        if (_info != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFE8F1FF), borderRadius: BorderRadius.circular(8)),
            child: Text(_info!, style: const TextStyle(color: NexaColors.blue, fontSize: 13)),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _verify,
            style: ElevatedButton.styleFrom(
              backgroundColor: NexaColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Vérifier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _resending ? null : _resend,
          child: Text(_resending ? 'Envoi...' : 'Renvoyer le code',
              style: const TextStyle(color: NexaColors.blue, fontWeight: FontWeight.w600)),
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
        const Text('Email vérifié !',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: NexaColors.navy),
            textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: NexaColors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Continuer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ],
    );
  }
}
