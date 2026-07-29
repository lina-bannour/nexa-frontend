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
  Map<String, dynamic>? _bareme;
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
      Map<String, dynamic>? bareme;
      try {
        bareme = await ApiClient.getBareme();
      } catch (_) {
        // Idem — le barème est informatif, pas bloquant.
      }
      setState(() {
        _profile = p;
        _rank = rank;
        _dailyMissions = missions;
        _bareme = bareme;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  static const _levels = [
    (name: 'Novice', xp: 0, icon: '🌱', color: Color(0xFF64748B)),
    (name: 'Initié', xp: 150, icon: '🔹', color: Color(0xFF0891B2)),
    (name: 'Apprenti', xp: 400, icon: '📘', color: NexaColors.blue),
    (name: 'Intermédiaire', xp: 800, icon: '⚙️', color: NexaColors.purple),
    (name: 'Avancé', xp: 1400, icon: '🚀', color: Color(0xFFD97706)),
    (name: 'Expert', xp: 2200, icon: '🎯', color: Color(0xFFC2410C)),
    (name: 'Maître', xp: 3500, icon: '⭐', color: NexaColors.blue),
    (name: 'Élite', xp: 5000, icon: '🏆', color: NexaColors.gold),
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
    final xp = (_profile?['xpTotal'] ?? 0) as int;
    final lvl = _currentLevel(xp);
    final nextLvl = _nextLevel(xp);
    final pct = nextLvl == null
        ? 100
        : (((xp - lvl.xp) / (nextLvl.xp - lvl.xp)) * 100).round().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('🎮 ', style: TextStyle(fontSize: 15)),
          const Text('Progression', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: NexaColors.navy)),
        ]),
        const Text('Niveaux, missions et badges NEXA', style: TextStyle(fontSize: 12, color: NexaColors.txt3)),
        const SizedBox(height: 12),

        // Level card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [lvl.color.withOpacity(0.12), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lvl.color.withOpacity(0.35), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('NIVEAU', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text('${lvl.icon} ${lvl.name}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: lvl.color)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$xp', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: NexaColors.navy)),
                      const Text('XP', style: TextStyle(fontSize: 11, color: NexaColors.txt3)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 7,
                  backgroundColor: NexaColors.bg,
                  valueColor: AlwaysStoppedAnimation(lvl.color),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${lvl.xp}', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
                  Text('$pct%', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
                  Text('${nextLvl?.xp ?? lvl.xp}', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('🏅 BADGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1)),
        const SizedBox(height: 10),
        _buildBadgesGrid(),

        const SizedBox(height: 20),
        const Text('⚡ BARÈME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1)),
        const SizedBox(height: 10),
        _buildBaremeGrid(),
      ],
    );
  }

  // ─── Badges: computed from real profile stats, not fake/static data ──────
  Widget _buildBadgesGrid() {
    final streak = (_profile?['streak'] ?? 0) as int;
    final attempts = (_profile?['_count']?['attempts'] ?? 0) as int;
    final solved = (_profile?['exercisesSolved'] ?? 0) as int;
    final postsCount = (_profile?['_count']?['posts'] ?? 0) as int;
    final contestsCompleted = (_profile?['contestsCompleted'] ?? 0) as int;
    final xp = (_profile?['xpTotal'] ?? 0) as int;
    final successRate = attempts > 0 ? solved / attempts : 0.0;

    final badges = [
      (icon: '🔥', label: 'Streak Master', unlocked: streak >= 7),
      (icon: '💯', label: 'QCM Expert', unlocked: attempts >= 20 && successRate >= 0.8),
      (icon: '⭐', label: 'Forum Actif', unlocked: postsCount >= 5),
      (icon: '🏁', label: 'Compétiteur', unlocked: contestsCompleted >= 3),
      (icon: '⭐', label: 'Maître', unlocked: xp >= 3500),
      (icon: '🏆', label: 'Élite', unlocked: xp >= 5000),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.05,
      children: badges.map((b) {
        return Container(
          decoration: BoxDecoration(
            color: b.unlocked ? NexaColors.goldLight : NexaColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: b.unlocked ? const Color(0xFFFDE68A) : NexaColors.border,
              style: BorderStyle.solid,
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(b.unlocked ? b.icon : '🔒', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                b.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: b.unlocked ? const Color(0xFFB45309) : NexaColors.txt3,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Barème: real, admin-configured XP economy (not hardcoded) ───────────
  Widget _buildBaremeGrid() {
    final b = _bareme;
    if (b == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Chargement du barème…', style: TextStyle(fontSize: 12, color: NexaColors.txt3)),
      );
    }
    final rows = [
      ('Réponse directe (0 indice)', '+${b['xpPerDirectAnswer']} XP bonus', NexaColors.green),
      ('1 indice utilisé', '-${b['hintPenaltyPercent1']}%', NexaColors.blue),
      ('2 indices utilisés', '-${b['hintPenaltyPercent2']}%', NexaColors.purple),
      ('3 indices utilisés', '-${b['hintPenaltyPercent3']}%', const Color(0xFFD97706)),
      ('4 indices utilisés', '-${b['hintPenaltyPercent4']}%', NexaColors.red),
      ('Publier sur le forum', '+${b['xpPerForumPost']} XP', const Color(0xFFDB2777)),
      ('Répondre sur le forum', '+${b['xpPerForumReply']} XP', const Color(0xFF0891B2)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 2.6,
      children: rows.map((r) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: NexaColors.border),
          ),
          child: Row(
            children: [
              Text(r.$2, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: r.$3)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(r.$1, style: const TextStyle(fontSize: 10, color: NexaColors.txt2), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  ({String name, int xp, String icon, Color color}) _currentLevel(int xp) {
    var current = _levels.first;
    for (final l in _levels) {
      if (xp >= l.xp) current = l;
    }
    return current;
  }

  ({String name, int xp, String icon, Color color})? _nextLevel(int xp) {
    for (final l in _levels) {
      if (xp < l.xp) return l;
    }
    return null;
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
