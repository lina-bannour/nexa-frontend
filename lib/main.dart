import 'package:flutter/material.dart';
import 'core/api/api_client.dart';
import 'core/theme/nexa_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/exercises/presentation/exercises_screen.dart';
import 'features/leaderboard/presentation/leaderboard_screen.dart';
import 'features/contests/presentation/concours_screen.dart';
import 'features/admin/presentation/admin_shell.dart';
import 'features/home/presentation/profile_screen.dart';

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
  bool _isAdmin = false;
  bool _checkingRole = false;
  int _currentTab = 0;
  int? _xpToast;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final has = await ApiClient.hasToken();
    if (!has) {
      setState(() => _isLoggedIn = false);
      return;
    }
    await _resolveRole();
    setState(() => _isLoggedIn = true);
  }

  Future<void> _resolveRole() async {
    setState(() => _checkingRole = true);
    try {
      final profile = await ApiClient.getProfile();
      setState(() => _isAdmin = profile['role'] == 'ADMIN');
    } catch (_) {
      // If the profile fetch fails (e.g. expired/invalid token), fall back
      // to the student experience rather than blocking the app entirely.
      setState(() => _isAdmin = false);
    } finally {
      setState(() => _checkingRole = false);
    }
  }

  void _onLogin() async {
    await _resolveRole();
    setState(() { _isLoggedIn = true; _currentTab = 0; });
  }

  void _onLogout() async {
    await ApiClient.clearToken();
    setState(() { _isLoggedIn = false; _isAdmin = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return LoginScreen(onLogin: _onLogin);
    }

    if (_checkingRole) {
      return const Scaffold(
        backgroundColor: NexaColors.navy,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_isAdmin) {
      return AdminShell(onLogout: _onLogout);
    }

    final screens = [
      HomeScreen(
        onGoExercises: () => setState(() => _currentTab = 1),
        onGoLeaderboard: () => setState(() => _currentTab = 3),
      ),
      const ExercisesScreen(),
      const ConcoursScreen(),      
      const LeaderboardScreen(),
      ProfileScreen(onLogout: _onLogout),
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
              _navItem(4, '👤', 'Profil'),
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
