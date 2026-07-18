import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showRegister = false;

  // Register fields
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _ecoleController = TextEditingController();
  String? _selectedFiliere;
  final List<String> _filieres = ['MP', 'PC', 'TSI', 'BIO', 'TECHNO'];

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.login(_emailController.text.trim(), _passwordController.text);
      widget.onLogin();
    } catch (e) {
      setState(() => _error = _extractError(e, 'Email ou mot de passe incorrect'));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _extractError(Object e, String fallback) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
    } catch (_) {}
    return fallback;
  }

  Future<void> _register() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        filiere: _selectedFiliere,
        ecole: _ecoleController.text.isEmpty ? null : _ecoleController.text,
      );
      if (!mounted) return;
      // Registration signs the user in immediately even though the account
      // isn't verified yet — nudge them to verify, but don't block access.
      final email = _emailController.text.trim();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(email: email, onDone: widget.onLogin),
      ));
    } catch (e) {
      setState(() => _error = 'Erreur lors de l\'inscription');
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
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4FACFF), NexaColors.blue],
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, height: 1)),
                      Text('Next Engineers Exp. & Academy', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Plateforme de révision · Prépas TN',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 40),

              // Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(_showRegister ? 'Créer un compte' : 'Connexion',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.navy)),
                    const SizedBox(height: 20),

                    if (_showRegister) ...[
                      _field(_prenomController, 'Prénom', Icons.person_outline),
                      const SizedBox(height: 12),
                      _field(_nomController, 'Nom', Icons.person_outline),
                      const SizedBox(height: 12),
                      _field(_ecoleController, 'École (optionnel)', Icons.school_outlined),
                      const SizedBox(height: 12),
                      _filiereDropdown(),
                      const SizedBox(height: 12),
                    ],

                    _field(_emailController, 'Email', Icons.email_outlined, type: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _field(_passwordController, 'Mot de passe', Icons.lock_outlined, obscure: true),

                    if (!_showRegister) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading ? null : () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => ForgotPasswordScreen(
                                onDone: () => Navigator.of(context).pop(),
                              ),
                            ));
                          },
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                          child: const Text('Mot de passe oublié ?',
                              style: TextStyle(color: NexaColors.blue, fontWeight: FontWeight.w600, fontSize: 12)),
                        ),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
                      ),
                    ],

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : (_showRegister ? _register : _login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: NexaColors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_showRegister ? "S'inscrire" : 'Se connecter',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() { _showRegister = !_showRegister; _error = null; }),
                      child: Text(
                        _showRegister ? 'Déjà un compte ? Se connecter' : "Pas de compte ? S'inscrire",
                        style: const TextStyle(color: NexaColors.blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {TextInputType? type, bool obscure = false}) {
    return TextField(
      controller: c,
      keyboardType: type,
      obscureText: obscure,
      onSubmitted: (_) => _showRegister ? _register() : _login(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _filiereDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFiliere,
      decoration: InputDecoration(
        labelText: 'Filière',
        prefixIcon: const Icon(Icons.school, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: _filieres.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
      onChanged: (v) => setState(() => _selectedFiliere = v),
    );
  }
}
