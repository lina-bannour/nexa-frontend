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
  DateTime? _lastUpdated;

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
      setState(() {
        _data = data;
        _lastUpdated = DateTime.now();
      });
    } catch (_) {
      setState(() => _error = "Impossible de charger les statistiques.");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator(color: NexaColors.blue));
    }
    if (_error != null && _data == null) return _errorView();

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _topBar(),
          const SizedBox(height: 18),

          _sectionHeader(
            emoji: '📊',
            title: 'Performance des exercices',
            subtitle: 'Taux de réussite par matière et difficulté',
            color: NexaColors.blue,
          ),
          const SizedBox(height: 12),
          _elevated(
            AdCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardLabel('Par matière'),
                  const SizedBox(height: 6),
                  if (byMatiere.isEmpty)
                    _emptyHint()
                  else
                    ...byMatiere.map((m) => _rateRow(
                          emoji: _matiereEmoji('${m['matiere']}'),
                          label: _matiereLabel('${m['matiere']}'),
                          rate: (m['successRate'] ?? 0) as num,
                          subtitle: '${m['total'] ?? 0} tentatives',
                          color: NexaColors.blue,
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _elevated(
            AdCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardLabel('Par difficulté'),
                  const SizedBox(height: 6),
                  if (byDifficulte.isEmpty)
                    _emptyHint()
                  else
                    ...byDifficulte.map((d) => _rateRow(
                          emoji: _difficulteEmoji('${d['difficulte']}'),
                          label: _difficulteLabel('${d['difficulte']}'),
                          rate: (d['successRate'] ?? 0) as num,
                          subtitle: '${d['total'] ?? 0} tentatives',
                          color: _difficulteColor('${d['difficulte']}'),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _elevated(
            AdCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _cardLabel('Exercices les plus difficiles'),
                            const Text('Taux de réussite le plus bas (min. 3 tentatives)',
                                style: TextStyle(fontSize: 11, color: NexaColors.txt3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (hardest.isEmpty)
                    _emptyHint()
                  else
                    ...hardest.asMap().entries.map((entry) {
                      final rank = entry.key + 1;
                      final e = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _rankBadge(rank),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${e['titre'] ?? '—'}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_matiereLabel('${e['matiere']}')} · ${_difficulteLabel('${e['difficulte']}')} · ${e['attempts'] ?? 0} tentatives',
                                    style: const TextStyle(fontSize: 10, color: NexaColors.txt3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AdTag(
                              label: '${e['successRate'] ?? 0}%',
                              color: const Color(0xFF991B1B),
                              bg: const Color(0xFFFEF2F2),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          _sectionHeader(
            emoji: '🏆',
            title: 'Concours',
            subtitle: 'Engagement et progression des sessions',
            color: NexaColors.gold,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _elevated(AdStatCard(icon: '🏁', label: 'Sessions démarrées', value: '${contests['totalSessions'] ?? 0}', color: NexaColors.blue)),
              _elevated(AdStatCard(icon: '✅', label: 'Taux de complétion', value: '${contests['completionRate'] ?? 0}%', color: NexaColors.green)),
              _elevated(AdStatCard(icon: '⚡', label: 'XP moyen / session', value: '${contests['avgXpPerSession'] ?? 0}', color: NexaColors.gold)),
              _elevated(AdStatCard(icon: '🎯', label: 'Sessions terminées', value: '${contests['completedSessions'] ?? 0}', color: NexaColors.purple)),
            ],
          ),
          if (contestsByFiliere.isNotEmpty) ...[
            const SizedBox(height: 12),
            _elevated(
              AdCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _cardLabel('Sessions par filière'),
                    const SizedBox(height: 8),
                    ...contestsByFiliere.map((f) {
                      final sessions = (f['sessions'] ?? 0) as num;
                      final maxSessions = contestsByFiliere
                          .map((x) => (x['sessions'] ?? 0) as num)
                          .fold<num>(0, (a, b) => a > b ? a : b);
                      final pct = maxSessions == 0 ? 0.0 : sessions / maxSessions;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _filiereChip('${f['filiere'] ?? '—'}'),
                                const Spacer(),
                                Text('${f['sessions'] ?? 0} sessions', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
                                const SizedBox(width: 8),
                                Text('~${f['avgXp'] ?? 0} XP', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.gold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 5,
                                backgroundColor: NexaColors.bg,
                                valueColor: const AlwaysStoppedAnimation(NexaColors.gold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),

          _sectionHeader(
            emoji: '💬',
            title: 'Forum',
            subtitle: 'Activité de la communauté',
            color: NexaColors.purple,
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _elevated(AdStatCard(icon: '💬', label: 'Discussions', value: '${forum['totalPosts'] ?? 0}', color: NexaColors.blue)),
              _elevated(AdStatCard(icon: '↩️', label: 'Réponses', value: '${forum['totalReplies'] ?? 0}', color: NexaColors.purple)),
              _elevated(AdStatCard(icon: '❤️', label: "J'aime", value: '${forum['totalLikes'] ?? 0}', color: const Color(0xFFDB2777))),
              _elevated(AdStatCard(icon: '🚩', label: 'Signalements', value: '${forum['reportedPosts'] ?? 0}', color: NexaColors.red)),
            ],
          ),
          const SizedBox(height: 28),

          _sectionHeader(
            emoji: '🔁',
            title: 'Rétention',
            subtitle: 'Fidélité et statut des étudiants',
            color: NexaColors.green,
          ),
          const SizedBox(height: 12),
          _elevated(
            AdCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Étudiants actifs (30 jours)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: NexaColors.blueLight, borderRadius: BorderRadius.circular(20)),
                        child: Text('${retention['monthlyActiveStudents'] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NexaColors.blue)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Répartition des séries (streak)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt3)),
                  const SizedBox(height: 10),
                  AdBarChart(
                    data: streakBuckets.map((b) => MapEntry('${b['bucket']}', (b['count'] ?? 0) as num)).toList(),
                    color: NexaColors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _elevated(
            AdCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardLabel('Statut des comptes'),
                  const SizedBox(height: 12),
                  if (usersByStatus.isEmpty)
                    _emptyHint()
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AdDonutChart(
                          segments: usersByStatus
                              .map((s) => MapEntry('${s['status'] ?? ''}', (s['count'] ?? 0) as num))
                              .toList(),
                          colors: usersByStatus.map((s) => _statusColor('${s['status'] ?? ''}')).toList(),
                          size: 96,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: usersByStatus
                                .map((s) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 9, height: 9,
                                            decoration: BoxDecoration(color: _statusColor('${s['status'] ?? ''}'), shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(child: AdTag.status('${s['status'] ?? ''}')),
                                          const SizedBox(width: 8),
                                          Text('${s['count'] ?? 0}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── En-tête de page : sous-titre + horodatage discret de la dernière
  // actualisation, pour donner confiance dans les chiffres affichés.
  Widget _topBar() {
    final updatedLabel = _lastUpdated == null ? '' : _timeAgo(_lastUpdated!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Text(
            "Vue d'ensemble de la plateforme",
            style: TextStyle(fontSize: 12, color: NexaColors.txt3),
          ),
        ),
        if (updatedLabel.isNotEmpty) ...[
          const Icon(Icons.schedule, size: 13, color: NexaColors.txt3),
          const SizedBox(width: 4),
          Text(updatedLabel, style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
          const SizedBox(width: 6),
        ],
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _loading ? null : _load,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _loading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: NexaColors.blue))
                : const Icon(Icons.refresh_rounded, size: 18, color: NexaColors.blue),
          ),
        ),
      ],
    );
  }

  // Icon badge + title/subtitle — donne à chaque section sa propre identité
  // visuelle plutôt qu'un simple texte gras, et aide à scanner la page.
  Widget _sectionHeader({required String emoji, required String title, required String subtitle, required Color color}) {
    return Row(
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text(emoji, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NexaColors.navy)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardLabel(String text) => Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13));

  // Enveloppe une carte d'une ombre légère pour lui donner du relief sans
  // toucher au composant AdCard partagé par le reste de l'admin.
  Widget _elevated(Widget child) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: NexaColors.navy.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyHint() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(Icons.inbox_outlined, size: 16, color: NexaColors.txt3),
          SizedBox(width: 8),
          Text('Pas encore de données.', style: TextStyle(color: NexaColors.txt3, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _rateRow({required String emoji, required String label, required num rate, required String subtitle, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              Text('$rate%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (rate.clamp(0, 100)) / 100,
              minHeight: 7,
              backgroundColor: NexaColors.bg,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
        ],
      ),
    );
  }

  // Badge de rang coloré (#1 le plus sévère → dégradé rouge vers gris) pour
  // le classement des exercices les plus difficiles.
  Widget _rankBadge(int rank) {
    final colors = [
      const Color(0xFFB91C1C),
      const Color(0xFFDC2626),
      const Color(0xFFEA580C),
      const Color(0xFFF59E0B),
      NexaColors.txt3,
    ];
    final color = colors[(rank - 1).clamp(0, colors.length - 1)];
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }

  Widget _filiereChip(String f) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: NexaColors.bg, borderRadius: BorderRadius.circular(6)),
      child: Text(f, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.navy)),
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

  String _matiereEmoji(String m) {
    switch (m) {
      case 'MATHEMATIQUES':
        return '🧮';
      case 'PHYSIQUE':
        return '⚛️';
      case 'SCIENCES_INGENIEUR':
        return '⚙️';
      default:
        return '📘';
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

  String _difficulteEmoji(String d) {
    switch (d) {
      case 'UN_ETOILE':
        return '🟢';
      case 'DEUX_ETOILES':
        return '🟠';
      case 'TROIS_ETOILES':
        return '🔴';
      default:
        return '⚪';
    }
  }

  Color _difficulteColor(String d) {
    switch (d) {
      case 'UN_ETOILE':
        return NexaColors.green;
      case 'DEUX_ETOILES':
        return NexaColors.gold;
      case 'TROIS_ETOILES':
        return NexaColors.red;
      default:
        return NexaColors.purple;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return NexaColors.green;
      case 'INACTIVE':
        return NexaColors.txt3;
      case 'SUSPENDED':
        return NexaColors.gold;
      case 'BANNED':
        return NexaColors.red;
      default:
        return NexaColors.blue;
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 10) return "à l'instant";
    if (diff.inMinutes < 1) return 'il y a ${diff.inSeconds}s';
    if (diff.inHours < 1) return 'il y a ${diff.inMinutes} min';
    return 'il y a ${diff.inHours} h';
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
