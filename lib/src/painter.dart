import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PathIconPainter extends CustomPainter {
  const PathIconPainter({
    required this.path,
    required this.viewBox,
    this.color,
    this.semanticLabel,
  }) : assert(color != null);

  final Rect viewBox;
  final Path path;
  final String? semanticLabel;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    final sizes = applyBoxFit(BoxFit.contain, viewBox.size, size);
    final outputSubrect =
        Alignment.center.inscribe(sizes.destination, Offset.zero & size);
    final scale = sizes.destination.width / sizes.source.width;
    canvas.translate(
      outputSubrect.left,
      outputSubrect.top,
    );
    canvas.scale(scale);
    canvas.translate(
      -viewBox.left,
      -viewBox.top,
    );
    canvas.drawPath(path, Paint()..color = color ?? Colors.black);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      final semanticLabel = this.semanticLabel;
      return [
        if (semanticLabel != null && semanticLabel.isNotEmpty)
          CustomPainterSemantics(
            rect: Offset.zero & size,
            properties: SemanticsProperties(
              label: semanticLabel,
              textDirection: TextDirection.ltr,
            ),
          ),
      ];
    };
  }

  @override
  bool shouldRepaint(PathIconPainter oldDelegate) =>
      path != oldDelegate.path ||
      color != oldDelegate.color ||
      viewBox != oldDelegate.viewBox;
  @override
  bool shouldRebuildSemantics(PathIconPainter oldDelegate) =>
      semanticLabel != oldDelegate.semanticLabel;
}
