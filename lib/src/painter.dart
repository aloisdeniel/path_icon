import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PathIconPainter extends CustomPainter {
  const PathIconPainter({
    @required this.path,
    this.color,
    this.semanticLabel,
  })  : assert(path != null),
        assert(color != null);

  final String semanticLabel;
  final Path path;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = path.getBounds();
    final sizes = applyBoxFit(BoxFit.contain, bounds.size, size);
    final outputSubrect =
        Alignment.center.inscribe(sizes.destination, Offset.zero & size);
    canvas.scale(sizes.destination.width / sizes.source.width);
    canvas.translate(outputSubrect.left, outputSubrect.top);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
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
      path != oldDelegate.path || color != oldDelegate.color;
  @override
  bool shouldRebuildSemantics(PathIconPainter oldDelegate) =>
      semanticLabel != oldDelegate.semanticLabel;
}
