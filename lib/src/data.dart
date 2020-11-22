import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

import 'svg_parsing.dart';

/// Path icon data represents the icon as a [Path] and a [viewBox] which
/// specify a rectangle in user space which is mapped to the bounds of the viewport.
class PathIconData {
  /// Create data from the given [path] and its [viewBox] describing the effective area.
  const PathIconData({
    @required this.path,
    @required this.viewBox,
  })  : assert(path != null),
        assert(viewBox != null);

  /// Create data from the given [path].
  ///
  /// If no [viewBox] is provided, then the bounds of the path are used and
  /// the path is translated at origin.
  ///
  /// A [fillType] can override the given [path]'s one.
  factory PathIconData.sanitized({
    @required Path path,
    Rect viewBox,
    PathFillType fillType,
  }) {
    assert(path != null);
    final bounds = path.getBounds();

    if (viewBox == null) {
      path = Path()..addPath(path, -bounds.topLeft);
      if (fillType != null) {
        path.fillType = fillType;
      }
    } else if (fillType != null) {
      path = Path()..addPath(path, Offset.zero);
      path.fillType = fillType;
    }

    return PathIconData(
      viewBox: viewBox ?? (Offset.zero & bounds.size),
      path: path,
    );
  }

  /// Parse the [data] (as SVG path's `d` data) and create a path.
  ///
  /// If no [viewBox] is provided, then the bounds of the path are used and
  /// the path is translated at origin.
  ///
  /// A [fillType] can be given, else `PathFillType.evenOdd`.
  factory PathIconData.fromData(
    String data, {
    Rect viewBox,
    PathFillType fillType,
  }) {
    assert(data != null);
    final path = parseSvgPathData(data);
    return PathIconData.sanitized(
      path: path,
      viewBox: viewBox,
      fillType: fillType ?? PathFillType.evenOdd,
    );
  }

  /// Parse the [data] SVG document and merges all the shapes found in the document as a single
  /// path.
  ///
  /// A [fillType] can be given, else `PathFillType.evenOdd`.
  ///
  /// A [semanticLabel] is `null` and the document has an `id` attribute, then its value is used instead.
  factory PathIconData.fromSvg(
    String data, {
    PathFillType fillType = PathFillType.evenOdd,
  }) {
    assert(data != null);
    final document = XmlDocument.parse(data);

    if (document.rootElement.name.local != 'svg') {
      throw Exception('The provided is not an SVG content');
    }

    final viewBoxData = document.rootElement.getAttribute('viewBox');
    final viewBox = parseViewBox(viewBoxData);
    final path = parseSvgElements(document.rootElement);

    return PathIconData.sanitized(
      path: path,
      fillType: fillType,
      viewBox: viewBox,
    );
  }

  /// The fill path data that represents the icon shape.
  final Path path;

  /// The area of the path that is effective.
  final Rect viewBox;

  @override
  String toString() {
    return 'PathIconData(viewBox: $viewBox, path: $path)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other is PathIconData &&
            viewBox == other.viewBox &&
            path == other.path);
  }

  @override
  int get hashCode => runtimeType.hashCode ^ viewBox.hashCode ^ path.hashCode;
}
