import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'data.dart';
import 'painter.dart';

/// Animated version of [PathIcon] that gradually changes its [color] and [size] over a period of time.
///
/// The [AnimatedPathIcon] will automatically animate between the old and
/// new values of properties when they change using the provided curve and
/// duration.
class AnimatedPathIcon extends ImplicitlyAnimatedWidget {
  /// Creates an icon that animates its parameters implicitly.
  ///
  /// The [curve] and [duration] arguments must not be null.
  const AnimatedPathIcon(
    this.data, {
    required super.duration,
    super.curve = Curves.easeInOut,
    super.key,
    this.size = 24,
    this.color = const Color(0xFF000000),
    this.semanticLabel,
  });

  /// The path data that is filled with the color and that may have
  /// a semantic label.
  ///
  /// This property **is not animated**.
  final PathIconData data;

  /// The size of the icon.
  ///
  /// This property is animated.
  final double size;

  /// The color of the icon.
  ///
  /// This property is animated.
  final Color color;

  /// Semantic label for the icon.
  ///
  /// Announced in accessibility modes (e.g TalkBack/VoiceOver).
  /// This label does not show in the UI.
  final String? semanticLabel;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PathIconData>('data', data));
    properties.add(DoubleProperty('size', size, defaultValue: null));
    properties.add(ColorProperty('color', color, defaultValue: null));
  }

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() {
    return _AnimatedPathIconState();
  }
}

class _AnimatedPathIconState extends AnimatedWidgetBaseState<AnimatedPathIcon> {
  ColorTween? _color;
  BoxConstraintsTween? _constraints;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color = visitor(_color, widget.color,
        (dynamic value) => ColorTween(begin: value as Color)) as ColorTween;
    _constraints = visitor(
            _constraints,
            BoxConstraints.tightFor(width: widget.size, height: widget.size),
            (dynamic value) =>
                BoxConstraintsTween(begin: value as BoxConstraints))
        as BoxConstraintsTween;
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = this.animation;
    final color = _color?.evaluate(animation);
    final constraints = _constraints?.evaluate(animation);
    return ConstrainedBox(
      constraints: constraints ?? BoxConstraints(),
      child: CustomPaint(
        painter: PathIconPainter(
          path: widget.data.path,
          viewBox: widget.data.viewBox,
          semanticLabel: widget.semanticLabel,
          color: color,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder description) {
    super.debugFillProperties(description);
    description.add(DiagnosticsProperty<ColorTween>(
      'color',
      _color,
      defaultValue: null,
    ));
    description.add(DiagnosticsProperty<BoxConstraintsTween>(
      'constraints',
      _constraints,
      defaultValue: null,
    ));
  }
}
