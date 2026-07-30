import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';

/// Dedicated "Progression" screen — reached via the button on the profile
/// page. Matches the reference GamifScreen mockup: level card, today's
/// missions, badges, and the XP barème.
class ProgressionScreen extends StatefulWidget {
  const ProgressionScreen({super.key});

  @override
  State<ProgressionScreen> createState() => _ProgressionScreenState();
}

class _ProgressionScreenState extends State<ProgressionScreen> {
  Map<String, dynamic>? _profile;
  List<dynamic> _missions = [];
  Map<String, dynamic>? _bareme;
  bool _loading = true;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profile = await ApiClient.getProfile().catchError((_) => <String, dynamic>{});
    List<dynamic> missions = [];
    try {
      missions = await ApiClient.getDailyMissions();
    } catch (_) {
      // Non bloquant — la page reste utilisable sans les missions.
    }
    Map<String, dynamic>? bareme;
    try {
      bareme = await ApiClient.getBareme();
    } catch (_) {
      // Idem — informatif seulement.
    }
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _missions = missions;
      _bareme = bareme;
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexaColors.bg,
      appBar: AppBar(
        backgroundColor: NexaColors.bg,
        elevation: 0,
        foregroundColor: NexaColors.navy,
        title: const Text('🎮 Progression', style: TextStyle(fontWeight: FontWeight.w800, color: NexaColors.navy)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: NexaColors.blue))
            : RefreshIndicator(
                onRefresh: _load,
                color: NexaColors.blue,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Niveaux, missions et badges NEXA', style: TextStyle(fontSize: 12, color: NexaColors.txt3)),
                    const SizedBox(height: 14),
                    _levelCard(),
                    const SizedBox(height: 20),
                    const Text('🎯 MISSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _missionsList(),
                    const SizedBox(height: 20),
                    const Text('🏅 BADGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _badgesGrid(),
                    const SizedBox(height: 20),
                    const Text('⚡ BARÈME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    _baremeGrid(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _levelCard() {
    final xp = (_profile?['xpTotal'] ?? 0) as int;
    final lvl = _currentLevel(xp);
    final nextLvl = _nextLevel(xp);
    final pct = nextLvl == null
        ? 100
        : (((xp - lvl.xp) / (nextLvl.xp - lvl.xp)) * 100).round().clamp(0, 100);

    return Container(
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
    );
  }

  Widget _missionsList() {
    // "Utiliser l'IA NEXA" isn't returned by the backend (that feature
    // doesn't exist yet), shown here as always-locked for consistency with
    // the profile's Missions du jour card.
    final missions = [
      ..._missions,
      {'key': 'AI', 'label': "Utiliser l'IA NEXA", 'xp': 10, 'completed': false, 'comingSoon': true},
    ];

    return Column(
      children: missions.map((m) {
        final done = m['completed'] == true;
        final comingSoon = m['comingSoon'] == true;
        final icon = switch ('${m['key']}') {
          'EXERCISES' => '📝',
          'FORUM' => '💬',
          'CONTEST' => '🏁',
          'AI' => '🤖',
          _ => '🎯',
        };
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: done ? const Color(0xFFF0FDF4) : Colors.white,
            border: Border.all(color: done ? const Color(0xFF86EFAC) : NexaColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: done ? const Color(0xFFDCFCE7) : NexaColors.blueLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(icon, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '${m['label']}',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: comingSoon ? NexaColors.txt3 : (done ? const Color(0xFF166534) : NexaColors.txt),
                  ),
                ),
              ),
              if (comingSoon)
                const Text('Bientôt', style: TextStyle(fontSize: 10, color: NexaColors.txt3, fontStyle: FontStyle.italic))
              else ...[
                Text('+${m['xp']} XP', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: NexaColors.gold)),
                if (done) const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.check_circle, size: 14, color: NexaColors.green),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // Computed from real profile stats — no fake/static badge list.
  Widget _badgesGrid() {
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
            border: Border.all(color: b.unlocked ? const Color(0xFFFDE68A) : NexaColors.border),
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: b.unlocked ? const Color(0xFFB45309) : NexaColors.txt3),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Real, admin-configured XP economy (from GET /settings/bareme), not
  // hardcoded numbers that could drift from what's actually configured.
  Widget _baremeGrid() {
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
              Expanded(child: Text(r.$1, style: const TextStyle(fontSize: 10, color: NexaColors.txt2), overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
