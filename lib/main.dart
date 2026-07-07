import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/theme/nexa_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/exercises/presentation/exercises_screen.dart';
import 'features/leaderboard/presentation/leaderboard_screen.dart';
import 'features/forum/presentation/forum_screen.dart';
import 'features/contests/presentation/concours_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.loadToken();
  runApp(const NexaApp());
}

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXA',
      debugShowCheckedModeBanner: false,
      theme: NexaTheme.theme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isLoggedIn = false;
  int _currentTab = 0;
  int? _xpToast;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final has = await ApiClient.hasToken();
    setState(() => _isLoggedIn = has);
  }

  void _onLogin() {
    setState(() { _isLoggedIn = true; _currentTab = 0; });
  }

  void _onLogout() async {
    await ApiClient.clearToken();
    setState(() => _isLoggedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _onLogin);
    }

    final screens = [
      HomeScreen(
        onGoExercises: () => setState(() => _currentTab = 1),
        onGoLeaderboard: () => setState(() => _currentTab = 3),
      ),
      const ExercisesScreen(),
      const ConcoursScreen(),      
      const LeaderboardScreen(),
      _MenuScreen(onLogout: _onLogout),
    ];

    return Scaffold(
      body: Stack(children: [
        SafeArea(child: screens[_currentTab]),
        if (_xpToast != null)
          Positioned(
            top: 60, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [NexaColors.blue, NexaColors.purple]),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [BoxShadow(color: NexaColors.blue.withOpacity(0.5), blurRadius: 20)],
              ),
              child: Text('+$_xpToast XP ✨',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: NexaColors.border)),
          boxShadow: [BoxShadow(color: Color(0x14126BFF), blurRadius: 20, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(children: [
              _navItem(0, '⊞', 'Accueil'),
              _navItem(1, '📚', 'Exercices'),
              _navItem(2, '🏁', 'Concours'),
              _navItem(3, '🏆', 'Classement'),
              _navItem(4, '⋯', 'Plus'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, String icon, String label) {
    final active = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEEF3FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(icon, style: TextStyle(fontSize: 20,
              shadows: active ? [const Shadow(color: NexaColors.blue, blurRadius: 8)] : null)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? NexaColors.blue : NexaColors.txt3,
            )),
            if (active) Container(
              margin: const EdgeInsets.only(top: 2),
              width: 18, height: 2,
              decoration: BoxDecoration(color: NexaColors.blue, borderRadius: BorderRadius.circular(1)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MenuScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const _MenuScreen({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const SizedBox(height: 20),
        const Text('Plus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: NexaColors.txt)),
        const SizedBox(height: 30),
        ListTile(
          leading: const Icon(Icons.logout, color: NexaColors.red),
          title: const Text('Se déconnecter', style: TextStyle(color: NexaColors.red, fontWeight: FontWeight.w600)),
          onTap: onLogout,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          tileColor: const Color(0xFFFEF2F2),
        ),
      ]),
    );
  }
}