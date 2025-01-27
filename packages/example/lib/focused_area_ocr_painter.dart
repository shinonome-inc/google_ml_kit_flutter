import 'dart:ui';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'coordinates_translator.dart';

class FocusedAreaOCRPainter extends CustomPainter {
  FocusedAreaOCRPainter({
    required this.recognizedText,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    required this.focusedAreaWidth,
    required this.focusedAreaHeight,
    required this.focusedAreaCenter,
    required this.focusedAreaRadius,
    this.focusedAreaPaint,
    this.unfocusedAreaPaint,
    this.textBackgroundPaint,
    this.uiTextStyle,
    this.onScanText,
  });

  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final double focusedAreaWidth;
  final double focusedAreaHeight;
  final Offset focusedAreaCenter;
  final Radius focusedAreaRadius;
  final Paint? focusedAreaPaint;
  final Paint? unfocusedAreaPaint;
  final Paint? textBackgroundPaint;
  final ui.TextStyle? uiTextStyle;
  final Function? onScanText;

  bool hasPointInRange(RRect focusedRRect, Rect textRect) {
    // ポイントのX座標が指定範囲内に収まっているかどうか確認する。
    final double minX = focusedRRect.left;
    final double maxX = focusedRRect.right;
    if (textRect.left < minX || textRect.right > maxX) {
      return false;
    }
    // ポイントのY座標が指定範囲内に収まっているかどうか確認する。
    final double minY = focusedRRect.top;
    final double maxY = focusedRRect.bottom;
    if (textRect.top < minY || textRect.bottom > maxY) {
      return false;
    }
    return true;
  }

  /// Draw focused area
  void _drawFocusedArea(Canvas canvas, RRect focusedRRect) {
    final Paint defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.blue;
    canvas.drawRRect(
      focusedRRect,
      focusedAreaPaint == null ? defaultPaint : focusedAreaPaint!,
    );
  }

  /// draw unfocused area
  void _drawUnfocusedArea(Canvas canvas, Size size, RRect focusedRRect) {
    final Offset deviceCenter = Offset(size.width / 2, size.height / 2);
    final Rect deviceRect = Rect.fromCenter(
      center: deviceCenter,
      width: size.width,
      height: size.height,
    );
    final Paint defaultPaint = Paint()..color = const Color(0x99000000);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(deviceRect),
        Path()..addRRect(focusedRRect),
      ),
      unfocusedAreaPaint == null ? defaultPaint : unfocusedAreaPaint!,
    );
  }

  void _drawText(Canvas canvas, TextBlock textBlock, Rect textRect) {
    final ui.TextStyle defaultStyle = ui.TextStyle(
      color: Colors.lightGreenAccent,
      background: Paint()..color = const Color(0x99000000),
    );
    final ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(),
    );
    builder.pushStyle(uiTextStyle == null ? defaultStyle : uiTextStyle!);
    builder.addText(textBlock.text);
    builder.pop();
    canvas.drawParagraph(
      builder.build()
        ..layout(
          ParagraphConstraints(width: (textRect.right - textRect.left).abs()),
        ),
      Offset(textRect.left, textRect.top),
    );
  }

  void _drawTextBackground(Canvas canvas, TextBlock textBlock, Size size) {
    final List<Offset> cornerPoints = <Offset>[];
    for (final point in textBlock.cornerPoints) {
      final double x = translateX(
        point.x.toDouble(),
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final double y = translateY(
        point.y.toDouble(),
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      cornerPoints.add(Offset(x, y));
    }
    cornerPoints.add(cornerPoints.first);
    final Paint defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.lightGreenAccent;
    canvas.drawPoints(
      PointMode.polygon,
      cornerPoints,
      textBackgroundPaint == null ? defaultPaint : textBackgroundPaint!,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final RRect focusedRRect = RRect.fromLTRBR(
      ((size.width - focusedAreaWidth) / 2) + focusedAreaCenter.dx,
      ((size.height - focusedAreaHeight) / 2) + focusedAreaCenter.dy,
      ((size.width - focusedAreaWidth) / 2 + focusedAreaWidth) +
          focusedAreaCenter.dx,
      ((size.height - focusedAreaHeight) / 2 + focusedAreaHeight) +
          focusedAreaCenter.dy,
      focusedAreaRadius,
    );

    _drawUnfocusedArea(canvas, size, focusedRRect);
    _drawFocusedArea(canvas, focusedRRect);

    for (final textBlock in recognizedText.blocks) {
      final double textLeft = translateX(
        textBlock.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final double textTop = translateY(
        textBlock.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final double textRight = translateX(
        textBlock.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final double textBottom = translateX(
        textBlock.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final Rect textRect =
          Rect.fromLTRB(textLeft, textTop, textRight, textBottom);

      if (hasPointInRange(focusedRRect, textRect)) {
        _drawTextBackground(canvas, textBlock, size);
        _drawText(canvas, textBlock, textRect);
        if (onScanText != null) {
          onScanText!(textBlock.text);
        }
      }
    }
  }

  @override
  bool shouldRepaint(FocusedAreaOCRPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText;
  }
}
