import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/nexa_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_students_screen.dart';
import 'admin_content_screen.dart';
import 'admin_forum_screen.dart';
import 'admin_settings_screen.dart';

class AdminShell extends StatefulWidget {
  final VoidCallback onLogout;
  const AdminShell({super.key, required this.onLogout});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminTab {
  final String id;
  final IconData icon;
  final String label;
  const _AdminTab(this.id, this.icon, this.label);
}

const _tabs = [
  _AdminTab('dashboard', Icons.grid_view_rounded, 'Dashboard'),
  _AdminTab('students', Icons.groups_rounded, 'Étudiants'),
  _AdminTab('content', Icons.menu_book_rounded, 'Contenu'),
  _AdminTab('forum', Icons.forum_rounded, 'Modération'),
  _AdminTab('settings', Icons.settings_rounded, 'Paramètres'),
];

class _AdminShellState extends State<AdminShell> {
  String _tab = 'dashboard';

  Widget _screen() {
    switch (_tab) {
      case 'students':
        return const AdminStudentsScreen();
      case 'content':
        return const AdminContentScreen();
      case 'forum':
        return const AdminForumScreen();
      case 'settings':
        return const AdminSettingsScreen();
      default:
        return const AdminDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _tabs.firstWhere((t) => t.id == _tab);
    final profile = ApiClient.cachedProfile;
    final adminName = profile != null ? '${profile['prenom'] ?? ''} ${profile['nom'] ?? ''}'.trim() : 'Admin';

    return Scaffold(
      backgroundColor: NexaColors.bg,
      drawer: _buildDrawer(adminName),
      appBar: AppBar(
        backgroundColor: NexaColors.navy,
        elevation: 0,
        title: Row(
          children: [
            Icon(current.icon, size: 18, color: Colors.white70),
            const SizedBox(width: 8),
            Text(current.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            width: 32, height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [NexaColors.gold, Color(0xFFFF8F00)]),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('A', style: TextStyle(color: NexaColors.navy, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
      body: SafeArea(top: false, child: _screen()),
    );
  }

  Widget _buildDrawer(String adminName) {
    return Drawer(
      backgroundColor: NexaColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  _NexaMark(),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NEXA', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                      Text('Administration', style: TextStyle(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("PANEL D'ADMINISTRATION",
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white30, letterSpacing: 1.2)),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                children: _tabs.map((t) {
                  final active = _tab == t.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Material(
                      color: active ? NexaColors.blue.withOpacity(0.22) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        leading: Icon(t.icon, size: 20, color: active ? Colors.white : Colors.white54),
                        title: Text(t.label, style: TextStyle(color: active ? Colors.white : Colors.white60, fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
                        onTap: () {
                          setState(() => _tab = t.id);
                          Navigator.of(context).pop();
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [NexaColors.gold, Color(0xFFFF8F00)]),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('A', style: TextStyle(color: NexaColors.navy, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(adminName.isEmpty ? 'Admin NEXA' : adminName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70), overflow: TextOverflow.ellipsis),
                        const Text('Super Administrateur', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: NexaColors.gold)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
                    onPressed: widget.onLogout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NexaMark extends StatelessWidget {
  const _NexaMark();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30, height: 30,
      child: CustomPaint(painter: _NexaMarkPainter()),
    );
  }
}

class _NexaMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 40;
    final paint1 = Paint()
      ..color = NexaColors.blue2
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path1 = Path()
      ..moveTo(6 * scale, 34 * scale)
      ..lineTo(6 * scale, 6 * scale)
      ..lineTo(26 * scale, 26 * scale)
      ..lineTo(26 * scale, 6 * scale);
    canvas.drawPath(path1, paint1);

    final gold = Paint()..color = NexaColors.gold;
    final trianglePath = Path()
      ..moveTo(22 * scale, 18 * scale)
      ..lineTo(28 * scale, 10 * scale)
      ..lineTo(33 * scale, 17 * scale)
      ..close();
    canvas.drawPath(trianglePath, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
