import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.getAdminDashboard();
      setState(() => _data = data);
    } catch (_) {
      setState(() => _error = 'Impossible de charger le tableau de bord.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: NexaColors.blue));
    if (_error != null) return _errorView();

    final kpis = _data?['kpis'] as Map<String, dynamic>? ?? {};
    final byFiliere = (_data?['studentsByFiliere'] as List<dynamic>? ?? []);
    final dailyActivity = (_data?['dailyActivity'] as List<dynamic>? ?? []);

    return RefreshIndicator(
      onRefresh: _load,
      color: NexaColors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // KPI grid — 2 columns on mobile (mockup uses 4 in a row on desktop)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              AdStatCard(icon: '👥', label: 'Étudiants inscrits', value: '${kpis['totalStudents'] ?? 0}', color: NexaColors.blue),
              AdStatCard(icon: '⚡', label: "XP distribués aujourd'hui", value: '${kpis['xpToday'] ?? 0}', color: NexaColors.gold),
              AdStatCard(icon: '📝', label: 'Exercices résolus (semaine)', value: '${kpis['exercisesThisWeek'] ?? 0}', color: NexaColors.green),
              AdStatCard(icon: '🏁', label: 'Sujets de concours', value: '${kpis['totalContests'] ?? 0}', color: NexaColors.purple),
            ],
          ),
          const SizedBox(height: 20),

          AdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Activité quotidienne', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('Exercices résolus (7 derniers jours)', style: TextStyle(fontSize: 11, color: NexaColors.txt3)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: NexaColors.blueLight, borderRadius: BorderRadius.circular(16)),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.circle, size: 7, color: NexaColors.green),
                        SizedBox(width: 5),
                        Text('Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.blue)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AdBarChart(
                  data: dailyActivity.map((d) {
                    final dateStr = d['date']?.toString() ?? '';
                    final label = dateStr.length >= 10 ? dateStr.substring(8, 10) : '?';
                    return MapEntry(label, (d['count'] ?? 0) as num);
                  }).toList(),
                  color: NexaColors.blue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          AdCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Répartition', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const Text('Étudiants par spécialité', style: TextStyle(fontSize: 11, color: NexaColors.txt3)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    AdDonutChart(
                      segments: byFiliere.map((f) => MapEntry(f['filiere']?.toString() ?? '—', (f['count'] ?? 0) as num)).toList(),
                      colors: const [NexaColors.blue, NexaColors.purple, NexaColors.green, Color(0xFFDB2777), NexaColors.gold],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: byFiliere.asMap().entries.map((e) {
                          final colors = [NexaColors.blue, NexaColors.purple, NexaColors.green, const Color(0xFFDB2777), NexaColors.gold];
                          final f = e.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: colors[e.key % colors.length], shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Text('${f['filiere'] ?? '—'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Text('${f['count'] ?? 0}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.txt2)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _TopStudentsCard(),
        ],
      ),
    );
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

class _TopStudentsCard extends StatefulWidget {
  @override
  State<_TopStudentsCard> createState() => _TopStudentsCardState();
}

class _TopStudentsCardState extends State<_TopStudentsCard> {
  List<dynamic>? _students;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await ApiClient.getAdminUsers();
      all.sort((a, b) => ((b['xpTotal'] ?? 0) as num).compareTo((a['xpTotal'] ?? 0) as num));
      if (mounted) setState(() => _students = all.take(6).toList());
    } catch (_) {
      if (mounted) setState(() => _students = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top Étudiants', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 10),
          if (_students == null)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_students!.isEmpty)
            const Padding(padding: EdgeInsets.all(12), child: Text('Aucun étudiant pour le moment.', style: TextStyle(color: NexaColors.txt3, fontSize: 12)))
          else
            ..._students!.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              final rankColor = i == 0 ? NexaColors.gold : i == 1 ? const Color(0xFF9CA3AF) : i == 2 ? const Color(0xFFB45309) : NexaColors.blueLight;
              final rankTxt = i < 3 ? Colors.white : NexaColors.blue;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(color: rankColor, borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text('${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: rankTxt)),
                    ),
                    const SizedBox(width: 10),
                    AdAvatar(name: '${s['prenom'] ?? '?'}', color: avatarColorFor(i), size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s['prenom'] ?? ''} ${s['nom'] ?? ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          Text('${s['ecole'] ?? '—'}', style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
                        ],
                      ),
                    ),
                    Text('${s['xpTotal'] ?? 0} XP', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: NexaColors.gold)),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
