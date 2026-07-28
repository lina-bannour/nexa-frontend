import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.getAdminAnalytics();
      setState(() => _data = data);
    } catch (_) {
      setState(() => _error = "Impossible de charger les statistiques.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: NexaColors.blue));
    }
    if (_error != null) return _errorView();

    final exercisePerf = _data?['exercisePerformance'] as Map<String, dynamic>? ?? {};
    final byMatiere = (exercisePerf['byMatiere'] as List<dynamic>? ?? []);
    final byDifficulte = (exercisePerf['byDifficulte'] as List<dynamic>? ?? []);
    final hardest = (exercisePerf['hardestExercises'] as List<dynamic>? ?? []);

    final contests = _data?['contests'] as Map<String, dynamic>? ?? {};
    final contestsByFiliere = (contests['byFiliere'] as List<dynamic>? ?? []);

    final forum = _data?['forum'] as Map<String, dynamic>? ?? {};

    final retention = _data?['retention'] as Map<String, dynamic>? ?? {};
    final streakBuckets = (retention['streakBuckets'] as List<dynamic>? ?? []);
    final usersByStatus = (retention['usersByStatus'] as List<dynamic>? ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      color: NexaColors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Performance des exercices', 'Taux de réussite par matière et difficulté'),
          const SizedBox(height: 10),
          AdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Par matière', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                if (byMatiere.isEmpty) _emptyHint() else ...byMatiere.map((m) => _rateRow(
                      label: _matiereLabel('${m['matiere']}'),
                      rate: (m['successRate'] ?? 0) as num,
                      subtitle: '${m['total'] ?? 0} tentatives',
                      color: NexaColors.blue,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Par difficulté', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                if (byDifficulte.isEmpty) _emptyHint() else ...byDifficulte.map((d) => _rateRow(
                      label: _difficulteLabel('${d['difficulte']}'),
                      rate: (d['successRate'] ?? 0) as num,
                      subtitle: '${d['total'] ?? 0} tentatives',
                      color: NexaColors.purple,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exercices les plus difficiles', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const Text('Taux de réussite le plus bas (min. 3 tentatives)', style: TextStyle(fontSize: 11, color: NexaColors.txt3)),
                const SizedBox(height: 10),
                if (hardest.isEmpty)
                  _emptyHint()
                else
                  ...hardest.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${e['titre'] ?? '—'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                                  Text('${_matiereLabel('${e['matiere']}')} · ${_difficulteLabel('${e['difficulte']}')} · ${e['attempts'] ?? 0} tentatives',
                                      style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
                                ],
                              ),
                            ),
                            AdTag(
                              label: '${e['successRate'] ?? 0}%',
                              color: const Color(0xFF991B1B),
                              bg: const Color(0xFFFEF2F2),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionTitle('Concours', 'Engagement et progression des sessions'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              AdStatCard(icon: '🏁', label: 'Sessions démarrées', value: '${contests['totalSessions'] ?? 0}', color: NexaColors.blue),
              AdStatCard(icon: '✅', label: 'Taux de complétion', value: '${contests['completionRate'] ?? 0}%', color: NexaColors.green),
              AdStatCard(icon: '⚡', label: 'XP moyen / session', value: '${contests['avgXpPerSession'] ?? 0}', color: NexaColors.gold),
              AdStatCard(icon: '🎯', label: 'Sessions terminées', value: '${contests['completedSessions'] ?? 0}', color: NexaColors.purple),
            ],
          ),
          if (contestsByFiliere.isNotEmpty) ...[
            const SizedBox(height: 12),
            AdCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sessions par filière', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 10),
                  ...contestsByFiliere.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text('${f['filiere'] ?? '—'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${f['sessions'] ?? 0} sessions', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
                            const SizedBox(width: 8),
                            Text('~${f['avgXp'] ?? 0} XP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.gold)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          _sectionTitle('Forum', 'Activité de la communauté'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              AdStatCard(icon: '💬', label: 'Discussions', value: '${forum['totalPosts'] ?? 0}', color: NexaColors.blue),
              AdStatCard(icon: '↩️', label: 'Réponses', value: '${forum['totalReplies'] ?? 0}', color: NexaColors.purple),
              AdStatCard(icon: '❤️', label: "J'aime", value: '${forum['totalLikes'] ?? 0}', color: const Color(0xFFDB2777)),
              AdStatCard(icon: '🚩', label: 'Signalements', value: '${forum['reportedPosts'] ?? 0}', color: NexaColors.red),
            ],
          ),
          const SizedBox(height: 20),

          _sectionTitle('Rétention', "Fidélité et statut des étudiants"),
          const SizedBox(height: 10),
          AdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Étudiants actifs (30 jours)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('${retention['monthlyActiveStudents'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NexaColors.blue)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Répartition des séries (streak)', style: TextStyle(fontSize: 11, color: NexaColors.txt3)),
                const SizedBox(height: 8),
                AdBarChart(
                  data: streakBuckets.map((b) => MapEntry('${b['bucket']}', (b['count'] ?? 0) as num)).toList(),
                  color: NexaColors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Statut des comptes', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 10),
                if (usersByStatus.isEmpty)
                  _emptyHint()
                else
                  ...usersByStatus.map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            AdTag.status('${s['status'] ?? ''}'),
                            const Spacer(),
                            Text('${s['count'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NexaColors.navy)),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
      ],
    );
  }

  Widget _emptyHint() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text('Pas encore de données.', style: TextStyle(color: NexaColors.txt3, fontSize: 12)),
    );
  }

  Widget _rateRow({required String label, required num rate, required String subtitle, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('$rate%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (rate.clamp(0, 100)) / 100,
              minHeight: 6,
              backgroundColor: NexaColors.bg,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
        ],
      ),
    );
  }

  String _matiereLabel(String m) {
    switch (m) {
      case 'MATHEMATIQUES':
        return 'Mathématiques';
      case 'PHYSIQUE':
        return 'Physique';
      case 'SCIENCES_INGENIEUR':
        return 'Sciences Ingénieur';
      default:
        return m.isEmpty ? '—' : m;
    }
  }

  String _difficulteLabel(String d) {
    switch (d) {
      case 'UN_ETOILE':
        return '★';
      case 'DEUX_ETOILES':
        return '★★';
      case 'TROIS_ETOILES':
        return '★★★';
      default:
        return d.isEmpty ? '—' : d;
    }
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: NexaColors.red, size: 40),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: NexaColors.txt2)),
          const SizedBox(height: 16),
          AdBtn(label: 'Réessayer', onPressed: _load),
        ]),
      ),
    );
  }
}
