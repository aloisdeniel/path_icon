import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'data.dart';
import 'painter.dart';

/// A graphical icon widget drawn from a path described in
/// a [PathIconData].
///
/// Icons are not animated. For an animated icon, consider [AnimatedPathIcon].
///
/// This widget assumes that the rendered icon is squared. Non-squared icons may
/// render incorrectly.
class PathIcon extends StatelessWidget {
  /// Create an icon from the given [data].
  const PathIcon(
    this.data, {
    Key? key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : super(key: key);

  /// The icon data.
  final PathIconData data;

  /// The width and height of the icon.
  final double? size;

  /// The color that fills the data's path.
  final Color? color;

  /// Semantic label for the icon.
  ///
  /// Announced in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final iconSize = size ?? iconTheme.size;
    final iconOpacity = iconTheme.opacity ?? 1.0;
    var iconColor = color ?? iconTheme.color ?? Colors.black;
    if (iconOpacity != 1.0) {
      iconColor = iconColor.withOpacity(iconColor.opacity * iconOpacity);
    }

    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: CustomPaint(
        painter: PathIconPainter(
          path: data.path,
          viewBox: data.viewBox,
          semanticLabel: semanticLabel,
          color: iconColor,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PathIconData>('data', data));
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
  }
}
