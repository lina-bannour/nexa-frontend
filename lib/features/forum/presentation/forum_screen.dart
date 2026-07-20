import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  List<dynamic> _posts = [];
  bool _loading = true;
  String? _error;
  String? _selectedMatiere; // API enum value, null = Tous

  Map<String, dynamic>? _postDetail;
  bool _loadingDetail = false;
  String? _openPostId;

  final _commentController = TextEditingController();
  bool _postingComment = false;

  bool _showNew = false;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _newMatiere = 'MATHEMATIQUES';
  bool _publishing = false;

  // Display label ↔ backend enum value
  static const _matiereLabels = {
    'MATHEMATIQUES': 'Maths',
    'PHYSIQUE': 'Physique',
    'SCIENCES_INGENIEUR': 'SI',
    'AUTRE': 'Autre',
  };

  final Map<String, Color> _matiereColors = {
    'Maths': NexaColors.blue,
    'Physique': NexaColors.purple,
    'SI': NexaColors.green,
    'Autre': NexaColors.txt3,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final posts = await ApiClient.getForumPosts(matiere: _selectedMatiere);
      setState(() => _posts = posts);
    } catch (e) {
      setState(() => _error = "Impossible de charger le forum.");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openPost(String id) async {
    setState(() { _openPostId = id; _loadingDetail = true; });
    try {
      final post = await ApiClient.getForumPost(id);
      setState(() => _postDetail = post);
    } catch (e) {
      setState(() => _postDetail = null);
    } finally {
      setState(() => _loadingDetail = false);
    }
  }

  void _closePost() {
    setState(() { _openPostId = null; _postDetail = null; });
  }

  Future<void> _toggleLike(String postId) async {
    // Optimistic update, both in the list and in the open detail if it matches.
    void applyLocally(bool liked, int delta) {
      final idx = _posts.indexWhere((p) => p['id'] == postId);
      if (idx != -1) {
        final p = _posts[idx];
        p['likedByMe'] = liked;
        p['_count'] = {...p['_count'], 'likes': (p['_count']['likes'] as int) + delta};
      }
      if (_postDetail != null && _postDetail!['id'] == postId) {
        _postDetail!['likedByMe'] = liked;
        _postDetail!['_count'] = {..._postDetail!['_count'], 'likes': (_postDetail!['_count']['likes'] as int) + delta};
      }
    }

    final currentlyLiked = _postDetail != null && _postDetail!['id'] == postId
        ? _postDetail!['likedByMe'] == true
        : (_posts.firstWhere((p) => p['id'] == postId, orElse: () => null)?['likedByMe'] == true);

    setState(() => applyLocally(!currentlyLiked, currentlyLiked ? -1 : 1));

    try {
      final liked = await ApiClient.toggleForumLike(postId);
      if (liked != !currentlyLiked) {
        // Server disagreed with our optimistic guess — reconcile.
        setState(() => applyLocally(liked, liked ? 1 : -1));
      }
    } catch (e) {
      // Revert on failure.
      setState(() => applyLocally(currentlyLiked, currentlyLiked ? 1 : -1));
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _openPostId == null) return;
    setState(() => _postingComment = true);
    try {
      await ApiClient.createForumReply(_openPostId!, text);
      _commentController.clear();
      await _openPost(_openPostId!); // refresh with the new reply
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Échec de l'envoi de la réponse"), backgroundColor: NexaColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _postingComment = false);
    }
  }

  Future<void> _addPost() async {
    final titre = _titleController.text.trim();
    final contenu = _bodyController.text.trim();
    if (titre.isEmpty || contenu.isEmpty) return;
    setState(() => _publishing = true);
    try {
      await ApiClient.createForumPost(titre: titre, contenu: contenu, matiere: _newMatiere);
      _titleController.clear();
      _bodyController.clear();
      setState(() => _showNew = false);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec de la publication'), backgroundColor: NexaColors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  String _authorName(dynamic author) {
    if (author == null) return 'Anonyme';
    return '${author['prenom'] ?? ''} ${author['nom'] ?? ''}'.trim();
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 2) return 'hier';
    return '${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    if (_openPostId != null) return _postDetailView();
    if (_showNew) return _newPostForm();
    return _postList();
  }

  Widget _postList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('💬 Forum',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.txt)),
                Text('Communauté des prépas',
                  style: TextStyle(color: NexaColors.txt3, fontSize: 12)),
              ]),
              ElevatedButton(
                onPressed: () => setState(() => _showNew = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: NexaColors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: const Text('+ Post', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
        ),
        // Matière filter — 7.1 : "consulter les publications filtrées par matière"
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _matiereChip('Tous', null),
              const SizedBox(width: 6),
              ..._matiereLabels.entries.map((e) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _matiereChip(e.value, e.key),
              )),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: NexaColors.txt3)))
                  : _posts.isEmpty
                      ? const Center(child: Text('Aucune publication pour le moment', style: TextStyle(color: NexaColors.txt3)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _posts.length,
                            itemBuilder: (_, i) => _postCard(_posts[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _matiereChip(String label, String? apiValue) {
    final active = _selectedMatiere == apiValue;
    final color = apiValue == null ? NexaColors.navy : (_matiereColors[_matiereLabels[apiValue]] ?? NexaColors.blue);
    return GestureDetector(
      onTap: () { setState(() => _selectedMatiere = apiValue); _load(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : NexaColors.border),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          color: active ? Colors.white : NexaColors.txt2,
        )),
      ),
    );
  }

  Widget _postCard(dynamic post) {
    final author = post['author'];
    final name = _authorName(author);
    final matiereLabel = _matiereLabels[post['matiere']] ?? post['matiere'] ?? '';
    final matiereColor = _matiereColors[matiereLabel] ?? NexaColors.blue;
    final likedByMe = post['likedByMe'] == true;
    final likesCount = post['_count']?['likes'] ?? 0;
    final repliesCount = post['_count']?['replies'] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NexaCard(
        onTap: () => _openPost(post['id']),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            NexaAvatar(name: name, color: NexaColors.blue, size: 36),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
                Text(_relativeTime(post['createdAt']), style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
              ]),
              const SizedBox(height: 4),
              NexaTag(label: matiereLabel, color: matiereColor),
            ])),
          ]),
          const SizedBox(height: 10),
          Text(post['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
          const SizedBox(height: 4),
          Text(post['contenu'] ?? '',
            style: const TextStyle(color: NexaColors.txt3, fontSize: 12),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: () => _toggleLike(post['id']),
              child: Row(children: [
                Icon(
                  likedByMe ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: likedByMe ? NexaColors.red : NexaColors.txt3,
                ),
                const SizedBox(width: 4),
                Text('$likesCount', style: const TextStyle(fontSize: 12, color: NexaColors.txt3)),
              ]),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.comment_outlined, size: 16, color: NexaColors.txt3),
            const SizedBox(width: 4),
            Text('$repliesCount', style: const TextStyle(fontSize: 12, color: NexaColors.txt3)),
          ]),
        ]),
      ),
    );
  }

  Widget _postDetailView() {
    if (_loadingDetail) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_postDetail == null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Impossible de charger ce post.', style: TextStyle(color: NexaColors.txt3)),
          const SizedBox(height: 10),
          TextButton(onPressed: _closePost, child: const Text('Retour au forum')),
        ]),
      );
    }

    final post = _postDetail!;
    final author = post['author'];
    final name = _authorName(author);
    final matiereLabel = _matiereLabels[post['matiere']] ?? post['matiere'] ?? '';
    final matiereColor = _matiereColors[matiereLabel] ?? NexaColors.blue;
    final likedByMe = post['likedByMe'] == true;
    final likesCount = post['_count']?['likes'] ?? 0;
    final replies = (post['replies'] as List<dynamic>? ?? []);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: _closePost,
                child: const Row(children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: NexaColors.txt3),
                  Text('Forum', style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 14),
              NexaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  NexaAvatar(name: name, color: NexaColors.blue, size: 36),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Row(children: [
                      NexaTag(label: matiereLabel, color: matiereColor),
                      const SizedBox(width: 8),
                      Text(_relativeTime(post['createdAt']), style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 12),
                Text(post['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NexaColors.txt)),
                const SizedBox(height: 8),
                Text(post['contenu'] ?? '', style: const TextStyle(color: NexaColors.txt2, fontSize: 13, height: 1.6)),
                const SizedBox(height: 12),
                Row(children: [
                  GestureDetector(
                    onTap: () => _toggleLike(post['id']),
                    child: Row(children: [
                      Icon(
                        likedByMe ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: likedByMe ? NexaColors.red : NexaColors.txt3,
                      ),
                      const SizedBox(width: 4),
                      Text('$likesCount', style: const TextStyle(fontSize: 13, color: NexaColors.txt3)),
                    ]),
                  ),
                ]),
              ])),
              const SizedBox(height: 14),
              if (replies.isNotEmpty) ...[
                Text('${replies.length} réponse(s)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NexaColors.txt)),
                const SizedBox(height: 8),
                ...replies.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NexaCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NexaAvatar(name: _authorName(r['author']), color: NexaColors.gold, size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(_authorName(r['author']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          Text(_relativeTime(r['createdAt']), style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        Text(r['contenu'] ?? '', style: const TextStyle(fontSize: 13, color: NexaColors.txt2, height: 1.5)),
                      ])),
                    ]),
                  ),
                )),
                const SizedBox(height: 8),
              ],
            ]),
          ),
        ),
        // Comment input
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: NexaColors.border)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Votre réponse...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _postingComment ? null : _addComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexaColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
              child: _postingComment
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Envoyer'),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _newPostForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GestureDetector(
          onTap: () => setState(() => _showNew = false),
          child: const Row(children: [
            Icon(Icons.arrow_back_ios, size: 14, color: NexaColors.txt3),
            Text('Forum', style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
          ]),
        ),
        const SizedBox(height: 16),
        const Text('Nouvelle publication',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: NexaColors.txt)),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          value: _newMatiere,
          decoration: InputDecoration(
            labelText: 'Matière',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _matiereLabels.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
          onChanged: (v) => setState(() => _newMatiere = v!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            labelText: 'Titre',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bodyController,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Contenu',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _publishing ? null : _addPost,
          style: ElevatedButton.styleFrom(
            backgroundColor: NexaColors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _publishing
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Publier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
    );
  }
}
