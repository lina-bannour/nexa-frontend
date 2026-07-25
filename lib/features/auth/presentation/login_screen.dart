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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _ecoleController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _showRegister = false;
  bool _obscurePassword = true;
  String? _selectedFiliere;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  final List<String> _filieres = ['MP', 'PC', 'TSI', 'BIO', 'TECHNO'];

  static const _features = [
    ('📚', 'Exercices', 'QCM + indices'),
    ('🏁', 'Concours', 'Annales officielles'),
    ('🏆', 'Classement', 'XP en temps réel'),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _ecoleController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.login(_emailController.text.trim(), _passwordController.text);
      widget.onLogin();
    } catch (e) {
      setState(() => _error = _extractError(e, 'Email ou mot de passe incorrect'));
    } finally {
      if (mounted) setState(() => _loading = false);
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
    if (!_formKey.currentState!.validate()) return;
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
      final email = _emailController.text.trim();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(email: email, onDone: widget.onLogin),
      ));
    } catch (e) {
      setState(() => _error = _extractError(e, 'Erreur lors de l\'inscription'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _showRegister = !_showRegister;
      _error = null;
    });
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071428), NexaColors.navy, Color(0xFF0D2348)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative orbs
            Positioned(top: -80, right: -60, child: _glowOrb(180, NexaColors.blue.withOpacity(0.18))),
            Positioned(bottom: 120, left: -70, child: _glowOrb(160, NexaColors.purple.withOpacity(0.14))),
            Positioned(top: 200, left: 40, child: _glowOrb(60, NexaColors.gold.withOpacity(0.08))),

            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
                  child: Column(
                    children: [
                      _buildHero(),
                      const SizedBox(height: 28),
                      _buildFormCard(),
                      const SizedBox(height: 20),
                      Text(
                        'Classes Préparatoires · MP · PC · TSI · Bio',
                        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildHero() {
    return Column(
      children: [
        // Logo mark
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4FACFF), NexaColors.blue, NexaColors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(color: NexaColors.blue.withOpacity(0.45), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: const Center(
            child: Text('N', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'NEXA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 32,
            letterSpacing: 4,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Votre plateforme de révision',
          style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),

        // Feature pills
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _features.map((f) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Text(f.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 2),
                    Text(f.$2, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    Text(f.$3, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 8)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 40, offset: const Offset(0, 16)),
          BoxShadow(color: NexaColors.blue.withOpacity(0.08), blurRadius: 60, offset: const Offset(0, 24)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab switcher
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: NexaColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _tabButton('Connexion', !_showRegister),
                _tabButton('Inscription', _showRegister),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _showRegister ? 'Rejoignez la communauté' : 'Bon retour !',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.navy),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showRegister
                        ? 'Créez votre compte et commencez à réviser'
                        : 'Connectez-vous pour continuer votre progression',
                    style: const TextStyle(color: NexaColors.txt3, fontSize: 13),
                  ),
                  const SizedBox(height: 22),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Column(
                      children: [
                        if (_showRegister) ...[
                          Row(
                            children: [
                              Expanded(child: _field(_prenomController, 'Prénom', Icons.person_outline_rounded,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null)),
                              const SizedBox(width: 10),
                              Expanded(child: _field(_nomController, 'Nom', Icons.badge_outlined,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field(_ecoleController, 'École (optionnel)', Icons.school_outlined),
                          const SizedBox(height: 12),
                          _filiereDropdown(),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
                  ),

                  _field(
                    _emailController,
                    'Adresse email',
                    Icons.alternate_email_rounded,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email requis';
                      if (!v.contains('@')) return 'Email invalide';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _passwordController,
                    'Mot de passe',
                    Icons.lock_outline_rounded,
                    obscure: _obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: NexaColors.txt3,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Mot de passe requis';
                      if (_showRegister && v.length < 6) return 'Minimum 6 caractères';
                      return null;
                    },
                  ),

                  if (!_showRegister) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(
                                    onDone: () => Navigator.of(context).pop(),
                                  ),
                                ));
                              },
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(color: NexaColors.blue, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ),
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // Primary CTA
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [NexaColors.blue, Color(0xFF0052CC)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: NexaColors.blue.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _loading ? null : (_showRegister ? _register : _login),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showRegister ? "Créer mon compte" : 'Se connecter',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),

                  if (_showRegister) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user_outlined, size: 14, color: NexaColors.txt3.withOpacity(0.7)),
                        const SizedBox(width: 6),
                        const Text(
                          'Gratuit · Accès immédiat aux exercices',
                          style: TextStyle(color: NexaColors.txt3, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool active) {
    return Expanded(
      child: GestureDetector(
        onTap: active ? null : _toggleMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: active ? NexaColors.navy : NexaColors.txt3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? type,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      validator: validator,
      onFieldSubmitted: (_) => _showRegister ? _register() : _login(),
      style: const TextStyle(fontSize: 14, color: NexaColors.txt, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: NexaColors.txt3, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: NexaColors.txt3),
        suffixIcon: suffix,
        filled: true,
        fillColor: NexaColors.bg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
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
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.red, width: 1.5),
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
        fillColor: NexaColors.bg,
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
      onChanged: (v) => setState(() => _selectedFiliere = v),
    );
  }
}
