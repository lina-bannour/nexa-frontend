import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../forum/presentation/forum_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onGoExercises;
  final VoidCallback onGoLeaderboard;

  const HomeScreen({
    super.key,
    required this.onGoExercises,
    required this.onGoLeaderboard,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiClient.getProfile();
      setState(() { _profile = p; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _levelName(int xp) {
    if (xp >= 5000) return 'Élite 🏆';
    if (xp >= 3500) return 'Maître ⭐';
    if (xp >= 2200) return 'Expert';
    if (xp >= 1400) return 'Avancé';
    if (xp >= 800) return 'Intermédiaire';
    if (xp >= 400) return 'Apprenti';
    if (xp >= 150) return 'Initié';
    return 'Novice';
  }

  int _nextLevelXp(int xp) {
    final levels = [150, 400, 800, 1400, 2200, 3500, 5000];
    for (final l in levels) { if (xp < l) return l; }
    return 5000;
  }

  int _currentLevelMin(int xp) {
    final levels = [0, 150, 400, 800, 1400, 2200, 3500, 5000];
    int min = 0;
    for (final l in levels) { if (xp >= l) min = l; }
    return min;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final xp = _profile?['xpTotal'] ?? 0;
    final nom = _profile?['nom'] ?? '';
    final prenom = _profile?['prenom'] ?? '';
    final filiere = _profile?['filiere'] ?? '';
    final attempts = _profile?['_count']?['attempts'] ?? 0;
    final levelName = _levelName(xp);
    final nextXp = _nextLevelXp(xp);
    final minXp = _currentLevelMin(xp);
    final progress = nextXp > minXp ? (xp - minXp) / (nextXp - minXp) : 1.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [NexaColors.navy, NexaColors.navy3],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: NexaColors.blue.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Smarter Prep. Better Rank. 🚀',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(prenom, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24)),
                        Text(filiere, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(children: [
                          Text(levelName, style: const TextStyle(color: NexaColors.gold, fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('$xp XP', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NexaProgressBar(value: progress, color: NexaColors.gold, height: 6),
                  const SizedBox(height: 6),
                  Text('${nextXp - xp} XP pour le prochain niveau',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Stats row
            Row(children: [
              _statCard('⚡', '$xp', 'XP', NexaColors.blue),
              const SizedBox(width: 8),
              _statCard('📝', '$attempts', 'Exs', NexaColors.purple),
              const SizedBox(width: 8),
              _statCard('🏆', '#1', 'Rang', NexaColors.gold),
              const SizedBox(width: 8),
              _statCard('🔥', '0', 'Jours', NexaColors.green),
            ]),
            const SizedBox(height: 14),

            // Quick actions
            const Text('ACCÈS RAPIDE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1)),
            const SizedBox(height: 9),
            Row(children: [
              Expanded(child: _actionBtn('📚', 'Exercices', NexaColors.blue, widget.onGoExercises)),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('🏆', 'Classement', NexaColors.gold, widget.onGoLeaderboard)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _actionBtn('💬', 'Forum', const Color(0xFFDB2777), () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const Scaffold(
                    body: SafeArea(child: ForumScreen()),
                  ),
                ));
              })),
              const SizedBox(width: 8),
              Expanded(child: _actionBtn('🤖', 'IA NEXA', NexaColors.purple, () {})),
            ]),
            const SizedBox(height: 14),

            // Profile summary
            NexaCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  NexaAvatar(name: '$prenom $nom', color: NexaColors.blue, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$prenom $nom', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(filiere, style: const TextStyle(color: NexaColors.txt3, fontSize: 12)),
                    const SizedBox(height: 6),
                    NexaTag(label: levelName, color: NexaColors.blue),
                  ])),
                ]),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String icon, String value, String label, Color color) {
    return Expanded(
      child: NexaCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
        ]),
      ),
    );
  }

  Widget _actionBtn(String icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: NexaColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: NexaColors.txt2)),
        ]),
      ),
    );
  }
}
