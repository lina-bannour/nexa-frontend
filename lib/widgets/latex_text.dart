import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders plain text mixed with inline `$...$` and block `$$...$$` LaTeX.
/// Falls back to plain [Text] for segments that fail to parse.
class LatexText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const LatexText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
  });

  static final _block = RegExp(r'\$\$(.+?)\$\$', dotAll: true);
  static final _inline = RegExp(r'(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)', dotAll: true);

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    if (!_block.hasMatch(text) && !_inline.hasMatch(text)) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final blocks = <Widget>[];
    var remaining = text;

    while (remaining.isNotEmpty) {
      final blockMatch = _block.firstMatch(remaining);
      final inlineMatch = _inline.firstMatch(remaining);

      Match? next;
      var isBlock = false;
      if (blockMatch != null && inlineMatch != null) {
        if (blockMatch.start <= inlineMatch.start) {
          next = blockMatch;
          isBlock = true;
        } else {
          next = inlineMatch;
        }
      } else if (blockMatch != null) {
        next = blockMatch;
        isBlock = true;
      } else if (inlineMatch != null) {
        next = inlineMatch;
      }

      if (next == null) {
        blocks.add(Text(remaining, style: baseStyle));
        break;
      }

      if (next.start > 0) {
        blocks.add(Text(remaining.substring(0, next.start), style: baseStyle));
      }

      final tex = next.group(1)!.trim();
      blocks.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: isBlock ? 8 : 0),
          child: Math.tex(
            tex,
            textStyle: baseStyle,
            mathStyle: isBlock ? MathStyle.display : MathStyle.text,
            onErrorFallback: (_) => Text(
              isBlock ? '\$\$$tex\$\$' : '\$$tex\$',
              style: baseStyle.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ),
      );

      remaining = remaining.substring(next.end);
    }

    return Column(
      crossAxisAlignment: textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
