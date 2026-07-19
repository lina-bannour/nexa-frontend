import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import '../widgets/admin_widgets.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _filiereFilter = 'Tout';
  String _statusFilter = 'Tout';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.getAdminUsers();
      setState(() => _students = data);
    } catch (_) {
      setState(() => _error = 'Impossible de charger les étudiants.');
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered {
    return _students.where((s) {
      if (_filiereFilter != 'Tout' && s['filiere'] != _filiereFilter) return false;
      if (_statusFilter != 'Tout' && s['status'] != _statusFilter) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final name = '${s['prenom'] ?? ''} ${s['nom'] ?? ''}'.toLowerCase();
        final email = '${s['email'] ?? ''}'.toLowerCase();
        if (!name.contains(q) && !email.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _updateStatus(Map<String, dynamic> student, String status) async {
    try {
      await ApiClient.updateUserStatus(student['id'], status);
      if (mounted) {
        showAdSnack(context, 'Statut mis à jour');
        Navigator.of(context).pop();
        _load();
      }
    } catch (e) {
      if (mounted) showAdSnack(context, "Échec de la mise à jour du statut", error: true);
    }
  }

  Future<void> _promote(Map<String, dynamic> student) async {
    try {
      await ApiClient.updateUserRole(student['id'], 'ADMIN');
      if (mounted) {
        showAdSnack(context, '${student['prenom']} est maintenant administrateur');
        Navigator.of(context).pop();
        _load();
      }
    } catch (e) {
      if (mounted) showAdSnack(context, "Échec de la promotion", error: true);
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

    final actifs = _students.where((s) => s['status'] == 'ACTIVE').length;
    final suspendus = _students.where((s) => s['status'] == 'SUSPENDED').length;
    final bannis = _students.where((s) => s['status'] == 'BANNED').length;

    return RefreshIndicator(
      onRefresh: _load,
      color: NexaColors.blue,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${_students.length} étudiants inscrits', style: const TextStyle(color: NexaColors.txt3, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _miniStat('✅', '$actifs', 'Actifs', NexaColors.green)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('⏸', '${_students.length - actifs - suspendus - bannis}', 'Autres', NexaColors.txt3)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('🚫', '$suspendus', 'Suspendus', NexaColors.red)),
          ]),
          const SizedBox(height: 14),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un étudiant...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: NexaColors.border)),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('Filière', _filiereFilter, ['Tout', 'MP', 'PC', 'TSI', 'BIO', 'TECHNO'], (v) => setState(() => _filiereFilter = v)),
              const SizedBox(width: 8),
              _filterChip('Statut', _statusFilter, ['Tout', 'ACTIVE', 'INACTIVE', 'SUSPENDED', 'BANNED'], (v) => setState(() => _statusFilter = v)),
            ]),
          ),
          const SizedBox(height: 14),
          if (_filtered.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun étudiant trouvé', style: TextStyle(color: NexaColors.txt3))))
          else
            ..._filtered.asMap().entries.map((e) => _studentRow(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _miniStat(String icon, String value, String label, Color color) {
    return AdCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: NexaColors.txt3)),
      ]),
    );
  }

  Widget _filterChip(String label, String value, List<String> options, ValueChanged<String> onSelect) {
    return PopupMenuButton<String>(
      onSelected: onSelect,
      itemBuilder: (_) => options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value == 'Tout' ? Colors.white : NexaColors.blueLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value == 'Tout' ? NexaColors.border : NexaColors.blue.withOpacity(0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(value == 'Tout' ? label : '$label: $value', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: value == 'Tout' ? NexaColors.txt2 : NexaColors.blue)),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 16, color: value == 'Tout' ? NexaColors.txt3 : NexaColors.blue),
        ]),
      ),
    );
  }

  Widget _studentRow(Map<String, dynamic> s, int i) {
    final name = '${s['prenom'] ?? ''} ${s['nom'] ?? ''}'.trim();
    return AdCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _openDetail(s),
      child: Row(children: [
        AdAvatar(name: name.isEmpty ? '?' : name, color: avatarColorFor(i), size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('${s['ecole'] ?? '—'} · ${s['filiere'] ?? '—'}', style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${s['xpTotal'] ?? 0} XP', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: NexaColors.gold)),
            const SizedBox(height: 4),
            AdTag.status('${s['status'] ?? 'ACTIVE'}'),
          ],
        ),
      ]),
    );
  }

  void _openDetail(Map<String, dynamic> student) {
    showAdModal(context, title: 'Détail étudiant', child: _StudentDetailContent(
      student: student,
      onSuspend: () => _updateStatus(student, 'SUSPENDED'),
      onReactivate: () => _updateStatus(student, 'ACTIVE'),
      onBan: () => _updateStatus(student, 'BANNED'),
      onPromote: () => _promote(student),
    ));
  }
}

class _StudentDetailContent extends StatefulWidget {
  final Map<String, dynamic> student;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback onBan;
  final VoidCallback onPromote;
  const _StudentDetailContent({
    required this.student,
    required this.onSuspend,
    required this.onReactivate,
    required this.onBan,
    required this.onPromote,
  });

  @override
  State<_StudentDetailContent> createState() => _StudentDetailContentState();
}

class _StudentDetailContentState extends State<_StudentDetailContent> {
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ApiClient.getAdminUserDetail(widget.student['id']);
      if (mounted) setState(() => _detail = d);
    } catch (_) {
      if (mounted) setState(() => _detail = widget.student);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _detail ?? widget.student;
    final name = '${s['prenom'] ?? ''} ${s['nom'] ?? ''}'.trim();
    final status = '${s['status'] ?? 'ACTIVE'}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          AdAvatar(name: name.isEmpty ? '?' : name, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                Text('${s['email'] ?? ''}', style: const TextStyle(fontSize: 12, color: NexaColors.txt3)),
                const SizedBox(height: 6),
                Row(children: [
                  if (s['filiere'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: NexaColors.blueLight, borderRadius: BorderRadius.circular(20)),
                      child: Text('${s['filiere']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: NexaColors.blue)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AdTag.status(status),
                ]),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 18),
        if (_detail == null)
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
        else ...[
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8,
            childAspectRatio: 0.85,
            children: [
              _statTile('⚡', '${s['xpTotal'] ?? 0}', 'XP', NexaColors.gold),
              _statTile('🔥', '${s['streak'] ?? 0}j', 'Streak', NexaColors.red),
              _statTile('📝', '${s['exercisesSolved'] ?? '—'}', 'Résolus', NexaColors.blue),
              _statTile('🎯', '${s['exercisesAttempted'] ?? '—'}', 'Tentés', NexaColors.txt2),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: AdBtn(label: status == 'SUSPENDED' || status == 'BANNED' ? '✅ Réactiver' : '🚫 Suspendre',
                variant: status == 'SUSPENDED' || status == 'BANNED' ? AdBtnVariant.green : AdBtnVariant.red,
                onPressed: status == 'SUSPENDED' || status == 'BANNED' ? widget.onReactivate : widget.onSuspend)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: AdBtn(label: 'Bannir définitivement', variant: AdBtnVariant.red, onPressed: status == 'BANNED' ? null : widget.onBan)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: AdBtn(label: '👑 Promouvoir admin', variant: AdBtnVariant.secondary, onPressed: widget.onPromote)),
          ]),
        ],
      ],
    );
  }

  Widget _statTile(String icon, String value, String label, Color color) {
    return Container(
      decoration: BoxDecoration(color: NexaColors.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: NexaColors.border)),
      alignment: Alignment.center,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
        Text(label, style: const TextStyle(fontSize: 9, color: NexaColors.txt3)),
      ]),
    );
  }
}
