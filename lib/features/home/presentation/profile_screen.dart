import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../forum/presentation/forum_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  int? _rank;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await ApiClient.getProfile();
      int? rank;
      try {
        final rankData = await ApiClient.getMyRank(period: 'global');
        rank = rankData['rank'] as int?; // null = pas encore classé
      } catch (_) {
        // Le rang est une info secondaire — son échec ne doit pas empêcher
        // d'afficher le reste du profil.
      }
      setState(() {
        _profile = p;
        _rank = rank;
        _loading = false;
      });
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: NexaColors.blue));
    }

    final xp = _profile?['xpTotal'] ?? 0;
    final nom = _profile?['nom'] ?? '';
    final prenom = _profile?['prenom'] ?? '';
    final filiere = _profile?['filiere'] ?? 'Non spécifiée';
    final ecole = _profile?['ecole'] ?? 'Non spécifiée';
    final attempts = _profile?['_count']?['attempts'] ?? 0;
    final levelName = _levelName(xp);
    final nextXp = _nextLevelXp(xp);
    final minXp = _currentLevelMin(xp);
    final progress = nextXp > minXp ? (xp - minXp) / (nextXp - minXp) : 1.0;

    return RefreshIndicator(
      onRefresh: _load,
      color: NexaColors.blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Profile Card
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [NexaColors.blue, NexaColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NexaColors.blue.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: NexaAvatar(
                      name: '$prenom $nom',
                      color: NexaColors.blue,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$prenom $nom',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: NexaColors.txt,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filiere,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: NexaColors.blue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ecole,
                    style: const TextStyle(
                      fontSize: 12,
                      color: NexaColors.txt3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Section
            Row(
              children: [
                _buildStatCard('🏆', _rank != null ? '#$_rank' : '—', 'Rang National', NexaColors.gold),
                const SizedBox(width: 12),
                _buildStatCard('📝', '$attempts', 'Résolus', NexaColors.purple),
                const SizedBox(width: 12),
                _buildStatCard('⚡', '$xp', 'Points XP', NexaColors.blue),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Bar / Gamification Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NexaColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Niveau : $levelName',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: NexaColors.txt,
                        ),
                      ),
                      Text(
                        '$xp XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: NexaColors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NexaProgressBar(value: progress, color: NexaColors.blue, height: 8),
                  const SizedBox(height: 8),
                  Text(
                    '${nextXp - xp} XP requis pour le niveau suivant',
                    style: const TextStyle(
                      color: NexaColors.txt3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NexaColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.forum_outlined, color: NexaColors.blue),
                    title: const Text(
                      'Forum de discussion',
                      style: TextStyle(fontWeight: FontWeight.w600, color: NexaColors.txt2),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: NexaColors.txt3),
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const Scaffold(
                          body: SafeArea(child: ForumScreen()),
                        ),
                      ));
                    },
                  ),
                  const Divider(height: 1, color: NexaColors.border),
                  ListTile(
                    leading: const Icon(Icons.logout, color: NexaColors.red),
                    title: const Text(
                      'Se déconnecter',
                      style: TextStyle(color: NexaColors.red, fontWeight: FontWeight.w600),
                    ),
                    onTap: widget.onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NexaColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: NexaColors.txt3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
