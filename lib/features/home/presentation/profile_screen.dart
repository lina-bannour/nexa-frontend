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
  List<dynamic> _dailyMissions = [];
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
      List<dynamic> missions = [];
      try {
        missions = await ApiClient.getDailyMissions();
      } catch (_) {
        // Idem pour les missions du jour — non bloquant.
      }
      setState(() {
        _profile = p;
        _rank = rank;
        _dailyMissions = missions;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  static const _levels = [
    (name: 'Novice', xp: 0, icon: '🌱'),
    (name: 'Initié', xp: 150, icon: '🔹'),
    (name: 'Apprenti', xp: 400, icon: '📘'),
    (name: 'Intermédiaire', xp: 800, icon: '⚙️'),
    (name: 'Avancé', xp: 1400, icon: '🚀'),
    (name: 'Expert', xp: 2200, icon: '🎯'),
    (name: 'Maître', xp: 3500, icon: '⭐'),
    (name: 'Élite', xp: 5000, icon: '🏆'),
  ];

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
    final postsCount = _profile?['_count']?['posts'] ?? 0;
    final contestsCompleted = _profile?['contestsCompleted'] ?? 0;
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

            // Missions du jour (reset daily, distinct from Progression below)
            _buildDailyMissionsSection(),
            const SizedBox(height: 24),

            // Progression Section (checklist + rank ladder)
            _buildProgressionSection(),
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

  Widget _buildDailyMissionsSection() {
    // "Utiliser l'IA NEXA" isn't returned by the backend (that feature
    // doesn't exist yet — see the note in the Progression checklist below),
    // so it's added here purely for display, always shown as "Bientôt"
    // and never completable, for consistency with that section.
    final missions = [
      ..._dailyMissions,
      {'key': 'AI', 'label': "Utiliser l'IA NEXA", 'xp': 10, 'completed': false, 'comingSoon': true},
    ];

    return Container(
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
          const Row(children: [
            Text('🎯 ', style: TextStyle(fontSize: 13)),
            Text(
              'MISSIONS DU JOUR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1),
            ),
          ]),
          const SizedBox(height: 12),
          ...missions.map((m) => _dailyMissionRow(
                icon: _missionIcon('${m['key']}'),
                label: '${m['label']}',
                xp: (m['xp'] ?? 0) as int,
                completed: m['completed'] == true,
                comingSoon: m['comingSoon'] == true,
              )),
        ],
      ),
    );
  }

  String _missionIcon(String key) {
    switch (key) {
      case 'EXERCISES': return '📝';
      case 'FORUM': return '💬';
      case 'CONTEST': return '🏁';
      case 'AI': return '🤖';
      default: return '🎯';
    }
  }

  Widget _dailyMissionRow({required String icon, required String label, required int xp, required bool completed, bool comingSoon = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: completed ? NexaColors.green.withOpacity(0.08) : (comingSoon ? NexaColors.bg : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: completed ? NexaColors.green.withOpacity(0.25) : NexaColors.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: comingSoon ? NexaColors.txt3 : NexaColors.txt,
              ),
            ),
          ),
          if (comingSoon)
            const Text('Bientôt', style: TextStyle(fontSize: 10, color: NexaColors.txt3, fontStyle: FontStyle.italic))
          else Row(
            children: [
              Text('+$xp XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: completed ? NexaColors.green : NexaColors.gold)),
              if (completed) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 15, color: NexaColors.green),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionSection() {
    final xp = _profile?['xpTotal'] ?? 0;
    final attempts = _profile?['_count']?['attempts'] ?? 0;
    final postsCount = _profile?['_count']?['posts'] ?? 0;
    final contestsCompleted = _profile?['contestsCompleted'] ?? 0;
    final levelName = _levelName(xp);

    return Container(
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
          const Text(
            'PROGRESSION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: NexaColors.txt3,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),

          // Checklist of engagement milestones
          _checklistRow(
            icon: '📝',
            label: '$attempts exercice${attempts > 1 ? 's' : ''} résolu${attempts > 1 ? 's' : ''}',
            done: attempts > 0,
          ),
          _checklistRow(
            icon: '💬',
            label: 'Publier sur le forum',
            done: postsCount > 0,
          ),
          _checklistRow(
            icon: '🏁',
            label: 'Compléter un concours',
            done: contestsCompleted > 0,
          ),
          _checklistRow(
            icon: '🤖',
            label: 'Utiliser l\'IA NEXA',
            done: false,
            comingSoon: true,
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: NexaColors.border),
          const SizedBox(height: 16),

          Row(
            children: [
              const Text('🚀 ', style: TextStyle(fontSize: 13)),
              Text(
                'NIVEAUX',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: NexaColors.txt3,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ..._levels.map((lvl) {
            final achieved = xp >= lvl.xp;
            final isCurrent = lvl.name == levelName.split(' ').first;
            return _levelRow(
              icon: lvl.icon,
              name: lvl.name,
              xpRequired: lvl.xp,
              achieved: achieved,
              isCurrent: isCurrent,
            );
          }),
        ],
      ),
    );
  }

  Widget _checklistRow({required String icon, required String label, required bool done, bool comingSoon = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: done ? NexaColors.green.withOpacity(0.08) : NexaColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: done ? NexaColors.green.withOpacity(0.25) : NexaColors.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: comingSoon ? NexaColors.txt3 : NexaColors.txt,
              ),
            ),
          ),
          if (comingSoon)
            const Text('Bientôt', style: TextStyle(fontSize: 10, color: NexaColors.txt3, fontStyle: FontStyle.italic))
          else
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: done ? NexaColors.green : NexaColors.txt3,
            ),
        ],
      ),
    );
  }

  Widget _levelRow({required String icon, required String name, required int xpRequired, required bool achieved, required bool isCurrent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isCurrent ? NexaColors.blue.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isCurrent ? NexaColors.blue.withOpacity(0.4) : NexaColors.border),
      ),
      child: Row(
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.lock_outline,
            size: 16,
            color: achieved ? NexaColors.green : NexaColors.txt3,
          ),
          const SizedBox(width: 8),
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCurrent ? NexaColors.blue : (achieved ? NexaColors.txt : NexaColors.txt3),
              ),
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: NexaColors.blue, borderRadius: BorderRadius.circular(20)),
              child: const Text('Actuel', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            )
          else
            Text('$xpRequired XP', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
        ],
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
