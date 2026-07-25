import 'package:flutter/material.dart';
import '../../../core/theme/nexa_theme.dart';

/// NEXA brand mark — blue gradient with gold accent.
class NexaLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool showTagline;

  const NexaLogo({
    super.key,
    this.size = 72,
    this.showWordmark = true,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final markSize = size;
    final radius = markSize * 0.26;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: markSize,
          height: markSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main blue tile
              Container(
                width: markSize,
                height: markSize,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3D87FF), NexaColors.blue, Color(0xFF0047B3)],
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  boxShadow: [
                    BoxShadow(
                      color: NexaColors.blue.withOpacity(0.45),
                      blurRadius: markSize * 0.35,
                      offset: Offset(0, markSize * 0.12),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: markSize * 0.52,
                      height: 1,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),

              // Gold accent stripe (bottom-right corner)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: markSize * 0.38,
                  height: markSize * 0.14,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD54F), NexaColors.gold, Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius * 0.6),
                      bottomRight: Radius.circular(radius),
                    ),
                  ),
                ),
              ),

              // Gold spark dot (top-right)
              Positioned(
                top: -markSize * 0.06,
                right: -markSize * 0.04,
                child: Container(
                  width: markSize * 0.18,
                  height: markSize * 0.18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE082), NexaColors.gold],
                    ),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: NexaColors.gold.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(Icons.bolt_rounded, size: markSize * 0.11, color: NexaColors.navy),
                ),
              ),
            ],
          ),
        ),

        if (showWordmark) ...[
          SizedBox(height: markSize * 0.22),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFE8F1FF)],
            ).createShader(bounds),
            child: Text(
              'NEXA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: markSize * 0.42,
                letterSpacing: markSize * 0.08,
                height: 1,
              ),
            ),
          ),
        ],

        if (showTagline) ...[
          SizedBox(height: markSize * 0.08),
          Text(
            'Votre plateforme de révision',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: markSize * 0.18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shared gradient background for all auth screens.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071428), NexaColors.navy, Color(0xFF0D2348)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _orb(180, NexaColors.blue.withOpacity(0.18))),
          Positioned(bottom: 100, left: -70, child: _orb(160, NexaColors.purple.withOpacity(0.12))),
          Positioned(top: 180, left: 30, child: _orb(70, NexaColors.gold.withOpacity(0.1))),
          child,
        ],
      ),
    );
  }

  static Widget _orb(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

/// White card container used on auth screens.
class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AuthCard({super.key, required this.child, this.padding = const EdgeInsets.all(24)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 40, offset: const Offset(0, 16)),
          BoxShadow(color: NexaColors.blue.withOpacity(0.08), blurRadius: 60, offset: const Offset(0, 24)),
        ],
      ),
      child: child,
    );
  }
}

class AuthField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final VoidCallback? onSubmitted;

  const AuthField({
    super.key,
    this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      maxLength: maxLength,
      textAlign: textAlign,
      validator: validator,
      onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
      style: style ?? const TextStyle(fontSize: 14, color: NexaColors.txt, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: NexaColors.txt3, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: NexaColors.txt3),
        suffixIcon: suffix,
        filled: true,
        fillColor: NexaColors.bg,
        counterText: maxLength != null ? '' : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: NexaColors.red, width: 1.5),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [NexaColors.blue, Color(0xFF0052CC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: NexaColors.blue.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: loading ? null : onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, color: Colors.white, size: 18),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13))),
        ],
      ),
    );
  }
}

class AuthInfoBanner extends StatelessWidget {
  final String message;
  const AuthInfoBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: NexaColors.blueLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NexaColors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: NexaColors.blue, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: NexaColors.blue, fontSize: 13))),
        ],
      ),
    );
  }
}

class AuthStepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const AuthStepIndicator({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i <= current;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: active
                ? const LinearGradient(colors: [NexaColors.blue, NexaColors.gold])
                : null,
            color: active ? null : NexaColors.border,
          ),
        );
      }),
    );
  }
}

class AuthBackLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const AuthBackLink({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
