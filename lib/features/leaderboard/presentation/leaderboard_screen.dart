import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _selectedFiliere;

  final List<String> _filieres = ['MP', 'PC', 'TSI', 'BIO', 'TECHNO'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await ApiClient.getLeaderboard(filiere: _selectedFiliere);
      setState(() => _users = users);
    } catch (e) {
      setState(() => _users = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  final List<Color> _avatarColors = [
    NexaColors.blue, const Color(0xFFDB2777), const Color(0xFF059669),
    const Color(0xFFD97706), NexaColors.purple, const Color(0xFF0891B2),
  ];

  Color _avatarColor(int index) => _avatarColors[index % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          color: NexaColors.navy,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('🏆 Classement',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white)),
                Text('Prépas TN · Temps réel',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              ]),
              Row(children: [
                SizedBox(width: 7, height: 7, child: DecoratedBox(decoration: BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle))),
                SizedBox(width: 5),
                Text('Live', style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.w700, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 12),
            // Filiere filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _chip('Global', null),
                ..._filieres.map((f) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _chip(f, f),
                )),
              ]),
            ),
          ]),
        ),

        Expanded(
          child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _users.isEmpty
              ? const Center(child: Text('Aucun étudiant'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    children: [
                      // Podium
                      if (_users.length >= 3) _buildPodium(),
                      // Full list
                      ..._users.asMap().entries.map((e) => _buildRow(e.key, e.value)),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String label, String? value) {
    final active = _selectedFiliere == value;
    return GestureDetector(
      onTap: () { setState(() => _selectedFiliere = value); _load(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? NexaColors.blue : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? NexaColors.blue : Colors.white.withOpacity(0.2)),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: active ? Colors.white : Colors.white60,
          )),
      ),
    );
  }

  Widget _buildPodium() {
    final top = _users.take(3).toList();
    final order = [top[1], top[0], top[2]]; // silver, gold, bronze
    final heights = [76.0, 104.0, 58.0];
    final medals = ['🥈', '🥇', '🥉'];
    final colors = [Colors.grey.shade400, NexaColors.gold, const Color(0xFFB45309)];
    final indices = [1, 0, 2]; // original ranking

    return Container(
      color: NexaColors.navy,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (pi) {
          final user = order[pi];
          final rank = indices[pi] + 1;
          return Column(children: [
            NexaAvatar(
              name: '${user['prenom'] ?? ''} ${user['nom'] ?? ''}',
              color: _avatarColor(indices[pi]),
              size: pi == 1 ? 40 : 32,
            ),
            const SizedBox(height: 6),
            Text('${user['prenom'] ?? ''}',
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: pi == 1 ? 12 : 10,
              )),
            Text('${user['xpTotal']} XP',
              style: TextStyle(color: colors[pi], fontWeight: FontWeight.w700, fontSize: 11)),
            const SizedBox(height: 4),
            Container(
              width: pi == 1 ? 80 : 66,
              height: heights[pi],
              decoration: BoxDecoration(
                color: colors[pi].withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                border: Border.all(color: colors[pi].withOpacity(0.4)),
              ),
              child: Center(child: Text(medals[pi], style: const TextStyle(fontSize: 24))),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _buildRow(int index, dynamic user) {
    final rank = index + 1;
    final name = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: NexaColors.border.withOpacity(0.5))),
      ),
      child: Row(children: [
        // Rank badge
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: rank == 1 ? NexaColors.gold : rank == 2 ? Colors.grey.shade400 : rank == 3 ? const Color(0xFFB45309) : NexaColors.blueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text('$rank',
              style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 11,
                color: rank <= 3 ? Colors.white : NexaColors.blue,
              )),
          ),
        ),
        const SizedBox(width: 10),
        NexaAvatar(name: name, color: _avatarColor(index), size: 30),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: NexaColors.txt),
            overflow: TextOverflow.ellipsis),
          Text(user['filiere'] ?? '',
            style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: NexaColors.blueLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('${user['xpTotal']} XP',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: NexaColors.blue)),
        ),
      ]),
    );
  }
}
