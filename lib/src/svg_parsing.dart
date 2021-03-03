import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

/// Parse all supported descendents from the given [element].
/// The strokes aren't supported and must converted as filled shapes.
///
/// Only `path`, `rect`, `circle`, `ellipse`, `g` are supported.
Path? parseSvgElements(XmlElement element) {
  if (element.name.local == 'path') {
    final childData = element.getAttribute('d');
    if (childData != null) {
      final childPath = parseSvgPathData(childData);
      final fillRule = element.getAttribute('fill-rule');
      childPath.fillType =
          fillRule == 'evenodd' ? PathFillType.evenOdd : PathFillType.nonZero;
      return childPath;
    }
    return null;
  }

  if (element.name.local == 'circle') {
    final cx = parseDouble(element.getAttribute('cx')) ?? 0;
    final cy = parseDouble(element.getAttribute('cy')) ?? cx;
    final r = parseDouble(element.getAttribute('r')) ?? 0;
    return Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: r * 2,
          height: r * 2,
        ),
      );
  }

  if (element.name.local == 'ellipse') {
    final cx = parseDouble(element.getAttribute('cx')) ?? 0;
    final cy = parseDouble(element.getAttribute('cy')) ?? cx;
    final rx = parseDouble(element.getAttribute('rx')) ?? 0;
    final ry = parseDouble(element.getAttribute('ry')) ?? rx;
    return Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: rx * 2,
          height: ry * 2,
        ),
      );
  }

  if (element.name.local == 'rect') {
    final x = parseDouble(element.getAttribute('x')) ?? 0;
    final y = parseDouble(element.getAttribute('y')) ?? 0;
    final width = parseDouble(element.getAttribute('width')) ?? 0;
    final height = parseDouble(element.getAttribute('height')) ?? 0;
    return Path()
      ..addRect(
        Rect.fromLTWH(x, y, width, height),
      );
  }

  if (element.name.local == 'g') {
    final groupPath = Path();
    for (var child in element.children.whereType<XmlElement>()) {
      final childPath = parseSvgElements(child);
      if (childPath != null) {
        groupPath.addPath(childPath, Offset.zero);
      }
    }

    final transform = element.getAttribute('transform');
    if (transform != null) {
      groupPath.transform(parseTransform(transform)!.storage);
    }

    return groupPath;
  }

  if (element.name.local == 'svg') {
    final groupPath = Path();
    for (var child in element.children.whereType<XmlElement>()) {
      final childPath = parseSvgElements(child);
      if (childPath != null) {
        groupPath.addPath(childPath, Offset.zero);
      }
    }
    return groupPath;
  }

  return null;
}

Rect? parseViewBox(String? data) {
  if (data != null && data.isNotEmpty) {
    final splits = data.split(' ').map((x) => parseDouble(x.trim())).toList();
    if (splits.length > 3) {
      final x = splits.first;
      final y = splits[1];
      final width = splits[2];
      final height = splits[3];
      return Rect.fromLTWH(x ?? 0.0, y ?? 0.0, width ?? 0.0, height ?? 0.0);
    }
  }
  return null;
}

/// The elements behind are imported from the `flutter_svg` package.

const String _transformCommandAtom = ' *,?([^(]+)\\(([^)]*)\\)';
final RegExp _transformValidator = RegExp('^($_transformCommandAtom)*\$');
final RegExp _transformCommand = RegExp(_transformCommandAtom);

typedef _MatrixParser = Matrix4 Function(String paramsStr, Matrix4 current);

const Map<String, _MatrixParser> _matrixParsers = <String, _MatrixParser>{
  'matrix': _parseSvgMatrix,
  'translate': _parseSvgTranslate,
  'scale': _parseSvgScale,
  'rotate': _parseSvgRotate,
  'skewX': _parseSvgSkewX,
  'skewY': _parseSvgSkewY,
};

/// Parses a SVG transform attribute into a [Matrix4].
///
/// Based on work in the "vi-tool" by @amirh, but extended to support additional
/// transforms and use a Matrix4 rather than Matrix3 for the affine matrices.
///
/// Also adds [x] and [y] to append as a final translation, e.g. for `<use>`.
Matrix4? parseTransform(String? transform) {
  if (transform == null || transform == '') {
    return null;
  }

  if (!_transformValidator.hasMatch(transform))
    throw StateError('illegal or unsupported transform: $transform');
  final Iterable<Match> matches =
      _transformCommand.allMatches(transform).toList().reversed;
  Matrix4 result = Matrix4.identity();
  for (Match m in matches) {
    final String command = m.group(1)?.trim() ?? '';
    final String params = m.group(2) ?? '';

    final _MatrixParser? transformer = _matrixParsers[command];
    if (transformer == null) {
      throw StateError('Unsupported transform: $command');
    }

    result = transformer(params, result);
  }
  return result;
}

final RegExp _valueSeparator = RegExp('( *, *| +)');

Matrix4 _parseSvgMatrix(String paramsStr, Matrix4 current) {
  final List<String> params = paramsStr.trim().split(_valueSeparator);
  assert(params.isNotEmpty);
  assert(params.length == 6);
  final double a = parseDouble(params[0]) ?? 0.0;
  final double b = parseDouble(params[1]) ?? 0.0;
  final double c = parseDouble(params[2]) ?? 0.0;
  final double d = parseDouble(params[3]) ?? 0.0;
  final double e = parseDouble(params[4]) ?? 0.0;
  final double f = parseDouble(params[5]) ?? 0.0;

  return affineMatrix(a, b, c, d, e, f).multiplied(current);
}

Matrix4 _parseSvgSkewX(String paramsStr, Matrix4 current) {
  final double x = parseDouble(paramsStr) ?? 0.0;
  return affineMatrix(1.0, 0.0, tan(x), 1.0, 0.0, 0.0).multiplied(current);
}

Matrix4 _parseSvgSkewY(String paramsStr, Matrix4 current) {
  final double y = parseDouble(paramsStr) ?? 0.0;
  return affineMatrix(1.0, tan(y), 0.0, 1.0, 0.0, 0.0).multiplied(current);
}

Matrix4 _parseSvgTranslate(String paramsStr, Matrix4 current) {
  final List<String> params = paramsStr.split(_valueSeparator);
  assert(params.isNotEmpty);
  assert(params.length <= 2);
  final double x = parseDouble(params[0]) ?? 0.0;
  final double y = params.length < 2 ? 0.0 : parseDouble(params[1]) ?? 0.0;
  return affineMatrix(1.0, 0.0, 0.0, 1.0, x, y).multiplied(current);
}

Matrix4 _parseSvgScale(String paramsStr, Matrix4 current) {
  final List<String> params = paramsStr.split(_valueSeparator);
  assert(params.isNotEmpty);
  assert(params.length <= 2);
  final double x = parseDouble(params[0]) ?? 0.0;
  final double y = params.length < 2 ? x : parseDouble(params[1]) ?? 0.0;
  return affineMatrix(x, 0.0, 0.0, y, 0.0, 0.0).multiplied(current);
}

Matrix4 _parseSvgRotate(String paramsStr, Matrix4 current) {
  final List<String> params = paramsStr.split(_valueSeparator);
  assert(params.length <= 3);
  final double a = radians(parseDouble(params[0]) ?? 0.0);

  final Matrix4 rotate =
      affineMatrix(cos(a), sin(a), -sin(a), cos(a), 0.0, 0.0);

  if (params.length > 1) {
    final double x = parseDouble(params[1]) ?? 0.0;
    final double y = params.length == 3 ? parseDouble(params[2]) ?? 0.0 : x;
    return affineMatrix(1.0, 0.0, 0.0, 1.0, x, y)
        .multiplied(current)
        .multiplied(rotate)
        .multiplied(affineMatrix(1.0, 0.0, 0.0, 1.0, -x, -y));
  } else {
    return rotate.multiplied(current);
  }
}

/// Creates a [Matrix4] affine matrix.
Matrix4 affineMatrix(
    double a, double b, double c, double d, double e, double f) {
  return Matrix4(
      a, b, 0.0, 0.0, c, d, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, e, f, 0.0, 1.0);
}

/// Parses strings in the form of '1.0' or '100%'.
double parseDecimalOrPercentage(String val, {double multiplier = 1.0}) {
  if (isPercentage(val)) {
    return parsePercentage(val, multiplier: multiplier);
  } else {
    return parseDouble(val) ?? 0.0;
  }
}

/// Parses values in the form of '100%'.
double parsePercentage(String val, {double multiplier = 1.0}) {
  return (parseDouble(val.substring(0, val.length - 1)) ?? 0.0) /
      100 *
      multiplier;
}

/// Whether a string should be treated as a percentage (i.e. if it ends with a `'%'`).
bool isPercentage(String val) => val.endsWith('%');

/// Parses a `String` to a `double`.
///
/// Passing `null` will return `null`.
///
/// Will strip off a `px` prefix.
double? parseDouble(String? maybeDouble, {bool tryParse = false}) {
  if (maybeDouble == null) {
    return null;
  }
  maybeDouble = maybeDouble.trim().replaceFirst('px', '').trim();
  if (tryParse) {
    return double.tryParse(maybeDouble);
  }
  return double.parse(maybeDouble);
}
