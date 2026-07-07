import 'package:flutter/material.dart';
import '../../../core/theme/nexa_theme.dart';
import '../../../widgets/shared_widgets.dart';

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'id': 'f1',
      'author': 'Ayoub M.',
      'color': NexaColors.blue,
      'time': '2h',
      'matiere': 'Maths',
      'titre': 'Aide pour Cauchy-Condensation',
      'body': 'Bonjour, j\'ai du mal à comprendre l\'idée principale de la preuve du critère de Cauchy. Quelqu\'un peut expliquer ?',
      'likes': 7,
      'comments': [
        {'author': 'Salma B.', 'color': 0xFFDB2777, 'time': '1h', 'text': 'L\'idée : regrouper les termes par blocs de taille 2^k.'},
      ],
    },
    {
      'id': 'f2',
      'author': 'Leila C.',
      'color': NexaColors.gold,
      'time': '5h',
      'matiere': 'Physique',
      'titre': 'Régime sous-amorti vs critique ?',
      'body': 'Je comprends la théorie mais en pratique quelle est la différence entre ζ=0.5 et ζ=1 ?',
      'likes': 12,
      'comments': [],
    },
    {
      'id': 'f3',
      'author': 'Rania A.',
      'color': const Color(0xFF0891B2),
      'time': 'hier',
      'matiere': 'SI',
      'titre': 'Méthode lieu des racines en partiel ?',
      'body': 'Les règles de tracé me semblent complexes. Une méthode mnémotechnique ?',
      'likes': 8,
      'comments': [],
    },
  ];

  final Set<String> _liked = {};
  Map<String, dynamic>? _openPost;
  final _commentController = TextEditingController();
  bool _showNew = false;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _newMatiere = 'Maths';

  final Map<String, Color> _matiereColors = {
    'Maths': NexaColors.blue,
    'Physique': NexaColors.purple,
    'SI': NexaColors.green,
    'Autre': NexaColors.txt3,
  };

  void _toggleLike(String id) {
    setState(() {
      if (_liked.contains(id)) {
        _liked.remove(id);
        final post = _posts.firstWhere((p) => p['id'] == id);
        post['likes'] = (post['likes'] as int) - 1;
      } else {
        _liked.add(id);
        final post = _posts.firstWhere((p) => p['id'] == id);
        post['likes'] = (post['likes'] as int) + 1;
      }
    });
  }

  void _addComment() {
    if (_commentController.text.trim().isEmpty || _openPost == null) return;
    setState(() {
      (_openPost!['comments'] as List).add({
        'author': 'Moi',
        'color': NexaColors.gold.value,
        'time': 'Maintenant',
        'text': _commentController.text.trim(),
      });
      _commentController.clear();
    });
  }

  void _addPost() {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;
    setState(() {
      _posts.insert(0, {
        'id': 'f${DateTime.now().millisecondsSinceEpoch}',
        'author': 'Moi',
        'color': NexaColors.gold,
        'time': 'Maintenant',
        'matiere': _newMatiere,
        'titre': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'likes': 0,
        'comments': [],
      });
      _titleController.clear();
      _bodyController.clear();
      _showNew = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_openPost != null) return _postDetail();
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
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _posts.length,
            itemBuilder: (_, i) {
              final post = _posts[i];
              final matiereColor = _matiereColors[post['matiere']] ?? NexaColors.blue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: NexaCard(
                  onTap: () => setState(() => _openPost = post),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      NexaAvatar(
                        name: post['author'],
                        color: post['color'] is Color ? post['color'] : Color(post['color']),
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(post['author'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          const Spacer(),
                          Text(post['time'], style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        NexaTag(label: post['matiere'], color: matiereColor),
                      ])),
                    ]),
                    const SizedBox(height: 10),
                    Text(post['titre'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: NexaColors.txt)),
                    const SizedBox(height: 4),
                    Text(post['body'],
                      style: const TextStyle(color: NexaColors.txt3, fontSize: 12),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(children: [
                      GestureDetector(
                        onTap: () => _toggleLike(post['id']),
                        child: Row(children: [
                          Icon(
                            _liked.contains(post['id']) ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: _liked.contains(post['id']) ? NexaColors.red : NexaColors.txt3,
                          ),
                          const SizedBox(width: 4),
                          Text('${post['likes']}', style: const TextStyle(fontSize: 12, color: NexaColors.txt3)),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment_outlined, size: 16, color: NexaColors.txt3),
                      const SizedBox(width: 4),
                      Text('${(post['comments'] as List).length}',
                        style: const TextStyle(fontSize: 12, color: NexaColors.txt3)),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _postDetail() {
    final post = _openPost!;
    final comments = post['comments'] as List;
    final matiereColor = _matiereColors[post['matiere']] ?? NexaColors.blue;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GestureDetector(
                onTap: () => setState(() => _openPost = null),
                child: const Row(children: [
                  Icon(Icons.arrow_back_ios, size: 14, color: NexaColors.txt3),
                  Text('Forum', style: TextStyle(color: NexaColors.txt3, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: 14),
              NexaCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  NexaAvatar(
                    name: post['author'],
                    color: post['color'] is Color ? post['color'] : Color(post['color']),
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(post['author'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Row(children: [
                      NexaTag(label: post['matiere'], color: matiereColor),
                      const SizedBox(width: 8),
                      Text(post['time'], style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
                    ]),
                  ])),
                ]),
                const SizedBox(height: 12),
                Text(post['titre'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NexaColors.txt)),
                const SizedBox(height: 8),
                Text(post['body'], style: const TextStyle(color: NexaColors.txt2, fontSize: 13, height: 1.6)),
                const SizedBox(height: 12),
                Row(children: [
                  GestureDetector(
                    onTap: () => _toggleLike(post['id']),
                    child: Row(children: [
                      Icon(
                        _liked.contains(post['id']) ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: _liked.contains(post['id']) ? NexaColors.red : NexaColors.txt3,
                      ),
                      const SizedBox(width: 4),
                      Text('${post['likes']}', style: const TextStyle(fontSize: 13, color: NexaColors.txt3)),
                    ]),
                  ),
                ]),
              ])),
              const SizedBox(height: 14),
              if (comments.isNotEmpty) ...[
                Text('${comments.length} réponse(s)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: NexaColors.txt)),
                const SizedBox(height: 8),
                ...comments.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NexaCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NexaAvatar(name: c['author'], color: Color(c['color'] is int ? c['color'] : (c['color'] as Color).value), size: 28),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(c['author'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          const Spacer(),
                          Text(c['time'], style: const TextStyle(color: NexaColors.txt3, fontSize: 11)),
                        ]),
                        const SizedBox(height: 4),
                        Text(c['text'], style: const TextStyle(fontSize: 13, color: NexaColors.txt2, height: 1.5)),
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
              onPressed: _addComment,
              style: ElevatedButton.styleFrom(
                backgroundColor: NexaColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
              child: const Text('Envoyer'),
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
          items: ['Maths', 'Physique', 'SI', 'Autre']
            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
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
          onPressed: _addPost,
          style: ElevatedButton.styleFrom(
            backgroundColor: NexaColors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text('Publier', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ]),
    );
  }
}