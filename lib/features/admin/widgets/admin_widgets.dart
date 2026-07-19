import 'package:flutter/material.dart';
import '../../../core/theme/nexa_theme.dart';

/// A rounded card matching the mockup's Card component.
class AdCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AdCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: NexaColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NexaColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: card);
  }
}

enum AdBtnVariant { primary, secondary, ghost, red, green, gold }

/// A button matching the mockup's Btn component variants.
class AdBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AdBtnVariant variant;
  final bool small;
  final bool full;
  final IconData? icon;
  final bool loading;

  const AdBtn({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AdBtnVariant.primary,
    this.small = false,
    this.full = false,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
    Border? border;
    switch (variant) {
      case AdBtnVariant.primary:
        bg = NexaColors.blue; fg = Colors.white; border = null;
        break;
      case AdBtnVariant.secondary:
        bg = Colors.white; fg = NexaColors.txt; border = Border.all(color: NexaColors.border);
        break;
      case AdBtnVariant.ghost:
        bg = Colors.transparent; fg = NexaColors.txt2; border = null;
        break;
      case AdBtnVariant.red:
        bg = const Color(0xFFFEF2F2); fg = const Color(0xFF991B1B); border = Border.all(color: const Color(0xFFFECACA));
        break;
      case AdBtnVariant.green:
        bg = const Color(0xFFF0FDF4); fg = const Color(0xFF166534); border = Border.all(color: const Color(0xFF86EFAC));
        break;
      case AdBtnVariant.gold:
        bg = NexaColors.gold; fg = NexaColors.navy; border = null;
        break;
    }

    final child = loading
        ? SizedBox(
            width: small ? 14 : 18, height: small ? 14 : 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: small ? 14 : 16, color: fg), const SizedBox(width: 6)],
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: small ? 12 : 13)),
            ],
          );

    return SizedBox(
      width: full ? double.infinity : null,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: (loading || onPressed == null) ? null : onPressed,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: small ? 12 : 16, vertical: small ? 8 : 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: border,
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A pill-shaped status/category tag matching the mockup's Tag component.
class AdTag extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const AdTag({super.key, required this.label, required this.color, required this.bg});

  factory AdTag.status(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const AdTag(label: 'actif', color: Color(0xFF166534), bg: Color(0xFFF0FDF4));
      case 'INACTIVE':
        return const AdTag(label: 'inactif', color: NexaColors.txt3, bg: Color(0xFFF1F5F9));
      case 'SUSPENDED':
        return const AdTag(label: 'suspendu', color: Color(0xFF991B1B), bg: Color(0xFFFEF2F2));
      case 'BANNED':
        return const AdTag(label: 'banni', color: Colors.white, bg: NexaColors.red);
      default:
        return AdTag(label: status, color: NexaColors.txt3, bg: const Color(0xFFF1F5F9));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

/// A KPI stat card matching the mockup's StatCard.
class AdStatCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const AdStatCard({super.key, required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return AdCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: NexaColors.navy)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: NexaColors.txt3)),
        ],
      ),
    );
  }
}

/// A circular initial-letter avatar matching the mockup's Av component.
class AdAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;
  const AdAvatar({super.key, required this.name, this.color = NexaColors.blue, this.size = 34});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.4)),
    );
  }
}

const List<Color> avatarPalette = [
  NexaColors.blue, Color(0xFFDB2777), Color(0xFF059669), Color(0xFFD97706),
  NexaColors.gold, Color(0xFF0891B2), NexaColors.purple, Color(0xFFC2410C),
];

Color avatarColorFor(int index) => avatarPalette[index % avatarPalette.length];

/// Bottom-sheet style modal matching the mockup's Modal component (mobile
/// equivalent of a centered dialog).
Future<T?> showAdModal<T>(BuildContext context, {required String title, required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.88),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: NexaColors.border, borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: NexaColors.navy)),
                  IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.of(ctx).pop()),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A labeled text field matching the mockup's INP inputs.
class AdField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscure;
  final int maxLines;
  const AdField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscure = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          keyboardType: keyboardType,
          obscureText: obscure,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: NexaColors.bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: NexaColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: NexaColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: const BorderSide(color: NexaColors.blue)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// A labeled dropdown matching the mockup's select inputs.
class AdDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  const AdDropdown({super.key, required this.label, required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: NexaColors.txt3, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: NexaColors.bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: NexaColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Simple vertical bar chart matching the mockup's MiniBarChart/daily activity chart.
class AdBarChart extends StatelessWidget {
  final List<MapEntry<String, num>> data;
  final Color color;
  final double height;
  const AdBarChart({super.key, required this.data, this.color = NexaColors.blue, this.height = 100});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height, child: const Center(child: Text('Aucune donnée', style: TextStyle(color: NexaColors.txt3, fontSize: 12))));
    final maxV = data.map((e) => e.value).fold<num>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final pct = maxV == 0 ? 0.0 : d.value / maxV;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${d.value}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                  const SizedBox(height: 4),
                  Container(
                    height: (height - 34) * pct,
                    decoration: BoxDecoration(color: color.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  ),
                  const SizedBox(height: 4),
                  Text(d.key, style: const TextStyle(fontSize: 9, color: NexaColors.txt3)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Simple donut chart matching the mockup's DonutChart (filiere distribution).
class AdDonutChart extends StatelessWidget {
  final List<MapEntry<String, num>> segments;
  final List<Color> colors;
  final double size;
  const AdDonutChart({super.key, required this.segments, required this.colors, this.size = 100});

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<num>(0, (a, b) => a + b.value);
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(
        painter: _DonutPainter(segments: segments, colors: colors, total: total),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$total', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: NexaColors.navy)),
              const Text('étudiants', style: TextStyle(fontSize: 8, color: NexaColors.txt3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, num>> segments;
  final List<Color> colors;
  final num total;
  _DonutPainter({required this.segments, required this.colors, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final strokeWidth = size.width * 0.12;
    final bgPaint = Paint()..color = const Color(0xFFEEF3FF)..style = PaintingStyle.stroke..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 6.28319, false, bgPaint);

    if (total == 0) return;
    double startAngle = -1.5708; // -90deg
    for (var i = 0; i < segments.length; i++) {
      final sweep = (segments[i].value / total) * 6.28319;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep * 0.96, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => true;
}

void showAdSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? NexaColors.red : NexaColors.navy,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
