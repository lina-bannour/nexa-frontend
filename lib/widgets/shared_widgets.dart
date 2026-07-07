import 'package:flutter/material.dart';
import '../core/theme/nexa_theme.dart';

class NexaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  const NexaCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderColor,
    this.onTap,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? NexaColors.card,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor ?? NexaColors.border),
          boxShadow: [
            BoxShadow(
              color: NexaColors.blue.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class NexaTag extends StatelessWidget {
  final String label;
  final Color color;

  const NexaTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class NexaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool outlined;
  final Color? color;

  const NexaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
    this.outlined = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? NexaColors.blue;
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: bg),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: bg, fontSize: 14)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                elevation: 0,
              ),
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
    );
  }
}

class NexaAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const NexaAvatar(
      {super.key,
      required this.name,
      required this.color,
      this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size * 0.38),
        ),
      ),
    );
  }
}

class NexaProgressBar extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Color color;
  final double height;

  const NexaProgressBar({
    super.key,
    required this.value,
    this.color = NexaColors.blue,
    this.height = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: NexaColors.border,
        borderRadius: BorderRadius.circular(height),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    );
  }
}

class DifficultyStars extends StatelessWidget {
  final String difficulte;

  const DifficultyStars({super.key, required this.difficulte});

  int get stars {
    switch (difficulte) {
      case 'UN_ETOILE':
        return 1;
      case 'DEUX_ETOILES':
        return 2;
      case 'TROIS_ETOILES':
        return 3;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          3,
          (i) => Icon(
                i < stars ? Icons.star : Icons.star_border,
                color: NexaColors.gold,
                size: 14,
              )),
    );
  }
}
