import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminForumScreen extends StatefulWidget {
  const AdminForumScreen({super.key});

  @override
  State<AdminForumScreen> createState() => _AdminForumScreenState();
}

class _AdminForumScreenState extends State<AdminForumScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _posts = [];
  bool _loading = true;
  String? _error;
  String _filter = 'Tout'; // Tout | REPORTED | PUBLISHED

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ApiClient.getModerationStats(),
        ApiClient.getAllModeratedPosts(),
      ]);
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _posts = results[1] as List<dynamic>;
      });
    } catch (_) {
      setState(() => _error = 'Impossible de charger la modération.');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    if (_filter == 'Tout') return _posts;
    return _posts.where((p) => p['status'] == _filter).toList();
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await ApiClient.updatePostStatus(id, status);
      if (mounted) { showAdSnack(context, status == 'PUBLISHED' ? 'Post validé' : 'Post supprimé'); _load(); }
    } catch (_) {
      if (mounted) showAdSnack(context, "Échec de l'action", error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: NexaColors.blue));
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, style: const TextStyle(color: NexaColors.txt2)),
          const SizedBox(height: 12),
          AdBtn(label: 'Réessayer', onPressed: _load),
        ]),
      );
    }

    final reportedCount = _posts.where((p) => p['status'] == 'REPORTED').length;

    return RefreshIndicator(
      onRefresh: _load,
      color: NexaColors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(reportedCount > 0 ? '$reportedCount post${reportedCount > 1 ? "s" : ""} signalé${reportedCount > 1 ? "s" : ""} en attente' : 'Aucun post signalé',
              style: const TextStyle(color: NexaColors.txt3, fontSize: 13)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _statTile('💬', '${_stats?['totalPosts'] ?? _posts.length}', 'Total posts', NexaColors.blue),
              _statTile('✅', '${_stats?['published'] ?? _posts.where((p) => p['status'] == 'PUBLISHED').length}', 'Publiés', NexaColors.green),
              _statTile('🚩', '${_stats?['reported'] ?? reportedCount}', 'Signalés', NexaColors.red),
              _statTile('❤️', '${_stats?['totalLikes'] ?? '—'}', 'Total likes', NexaColors.gold),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: ['Tout', 'REPORTED', 'PUBLISHED'].map((f) {
              final active = _filter == f;
              final label = f == 'Tout' ? 'Tout' : f == 'REPORTED' ? '🚩 Signalés' : '✅ Publiés';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? NexaColors.blueLight : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: active ? NexaColors.blue : NexaColors.border),
                    ),
                    child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? NexaColors.blue : NexaColors.txt3)),
                  ),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 14),
          if (_filtered.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun post', style: TextStyle(color: NexaColors.txt3))))
          else
            ..._filtered.map(_postCard),
        ],
      ),
    );
  }

  Widget _statTile(String icon, String value, String label, Color color) {
    return AdCard(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
      ]),
    );
  }

  Widget _postCard(dynamic p) {
    final reported = p['status'] == 'REPORTED';
    final author = p['author'] as Map<String, dynamic>?;
    final authorName = author != null ? '${author['prenom'] ?? ''} ${author['nom'] ?? ''}'.trim() : 'Inconnu';

    return AdCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('${reported ? "🚩 " : ""}${p['titre'] ?? ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            AdTag(
              label: reported ? 'Signalé' : 'Publié',
              color: reported ? const Color(0xFF991B1B) : const Color(0xFF166534),
              bg: reported ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            ),
          ]),
          const SizedBox(height: 4),
          Text('$authorName · ${p['matiere'] ?? ''}', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Row(children: [
                AdBtn(label: '', icon: Icons.check, small: true, variant: AdBtnVariant.green,
                    onPressed: reported ? () => _updateStatus(p['id'], 'PUBLISHED') : null),
                const SizedBox(width: 8),
                AdBtn(label: 'Supprimer', icon: Icons.delete_outline, small: true, variant: AdBtnVariant.red,
                    onPressed: () => _confirmRemove(p['id'])),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  void _confirmRemove(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce post ?'),
        content: const Text('Cette action est définitive.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () { Navigator.of(ctx).pop(); _updateStatus(id, 'REMOVED'); },
            child: const Text('Supprimer', style: TextStyle(color: NexaColors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
