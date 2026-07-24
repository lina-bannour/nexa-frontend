import 'dart:async';
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
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<dynamic> _students = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  int _total = 0;
  String? _error;

  String _filiereFilter = 'Tout';
  String _statusFilter = 'Tout';

  // Global counts per status for the mini stat cards — fetched separately
  // (pageSize: 1, we only read pagination.total) so they stay accurate
  // regardless of how many pages have been scrolled into view.
  int? _actifsTotal;
  int? _suspendusTotal;
  int? _bannisTotal;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  String? get _search => _searchController.text.trim().isEmpty ? null : _searchController.text.trim();
  String? get _filiereParam => _filiereFilter == 'Tout' ? null : _filiereFilter;
  String? get _statusParam => _statusFilter == 'Tout' ? null : _statusFilter;

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; _page = 1; _hasMore = true; });
    try {
      final result = await ApiClient.getAdminUsersPage(
        search: _search, status: _statusParam, filiere: _filiereParam, page: 1,
      );
      final pagination = result['pagination'] as Map<String, dynamic>;
      setState(() {
        _students = result['data'] as List<dynamic>;
        _total = pagination['total'] ?? _students.length;
        _hasMore = (pagination['page'] ?? 1) < (pagination['totalPages'] ?? 1);
      });
      _loadStatusCounts();
    } catch (_) {
      setState(() => _error = 'Impossible de charger les étudiants.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await ApiClient.getAdminUsersPage(
        search: _search, status: _statusParam, filiere: _filiereParam, page: nextPage,
      );
      final pagination = result['pagination'] as Map<String, dynamic>;
      setState(() {
        _students = [..._students, ...result['data'] as List<dynamic>];
        _page = nextPage;
        _hasMore = (pagination['page'] ?? nextPage) < (pagination['totalPages'] ?? nextPage);
      });
    } catch (_) {
      // Silent — a failed "load more" shouldn't disrupt the list already on screen.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // Scoped to the current search/filière filter (not the status filter,
  // since these three tiles ARE the status breakdown).
  Future<void> _loadStatusCounts() async {
    try {
      final results = await Future.wait([
        ApiClient.getAdminUsersPage(search: _search, filiere: _filiereParam, status: 'ACTIVE', pageSize: 1),
        ApiClient.getAdminUsersPage(search: _search, filiere: _filiereParam, status: 'SUSPENDED', pageSize: 1),
        ApiClient.getAdminUsersPage(search: _search, filiere: _filiereParam, status: 'BANNED', pageSize: 1),
      ]);
      if (!mounted) return;
      setState(() {
        _actifsTotal = (results[0]['pagination']?['total'] ?? 0) as int;
        _suspendusTotal = (results[1]['pagination']?['total'] ?? 0) as int;
        _bannisTotal = (results[2]['pagination']?['total'] ?? 0) as int;
      });
    } catch (_) {
      // Stat tiles are supplementary — a failure here shouldn't block the list.
    }
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

    final autres = _actifsTotal != null && _suspendusTotal != null && _bannisTotal != null
        ? (_total - _actifsTotal! - _suspendusTotal! - _bannisTotal!).clamp(0, _total)
        : null;

    return RefreshIndicator(
      onRefresh: _load,
      color: NexaColors.blue,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          Text('$_total étudiants inscrits', style: const TextStyle(color: NexaColors.txt3, fontSize: 13)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _miniStat('✅', _actifsTotal != null ? '$_actifsTotal' : '—', 'Actifs', NexaColors.green)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('⏸', autres != null ? '$autres' : '—', 'Autres', NexaColors.txt3)),
            const SizedBox(width: 8),
            Expanded(child: _miniStat('🚫', _suspendusTotal != null ? '$_suspendusTotal' : '—', 'Suspendus', NexaColors.red)),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un étudiant...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: NexaColors.border)),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('Filière', _filiereFilter, ['Tout', 'MP', 'PC', 'TSI', 'BIO', 'TECHNO'], (v) { setState(() => _filiereFilter = v); _load(); }),
              const SizedBox(width: 8),
              _filterChip('Statut', _statusFilter, ['Tout', 'ACTIVE', 'INACTIVE', 'SUSPENDED', 'BANNED'], (v) { setState(() => _statusFilter = v); _load(); }),
            ]),
          ),
          const SizedBox(height: 14),
          if (_students.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Aucun étudiant trouvé', style: TextStyle(color: NexaColors.txt3))))
          else ...[
            ..._students.asMap().entries.map((e) => _studentRow(e.value, e.key)),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
          ],
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
