import 'dart:ui';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'coordinates_translator.dart';

class TextRecognizerPainter extends CustomPainter {
  TextRecognizerPainter({
    required this.recognizedText,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    required this.focusAreaWidth,
    required this.focusAreaHeight,
  });

  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final double focusAreaWidth;
  final double focusAreaHeight;

  bool hasPointInRange(RRect focusRRect, Rect textRect) {
    // ポイントのX座標が指定範囲内に収まっているかどうか確認する。
    final double minX = focusRRect.left;
    final double maxX = focusRRect.right;
    if (textRect.left < minX || textRect.right > maxX) {
      return false;
    }
    // ポイントのY座標が指定範囲内に収まっているかどうか確認する。
    final double minY = focusRRect.top;
    final double maxY = focusRRect.bottom;
    if (textRect.top < minY || textRect.bottom > maxY) {
      return false;
    }
    return true;
  }

  /// Fill camera margin with transparent black
  void _fillCameraMargin(Canvas canvas, Size size, RRect focusRRect) {
    // if (cameraMarginColor == null) {
    //   return;
    // }
    final Size deviceSize = Size(size.width, size.height * 3);
    final Rect deviceRect = Rect.fromCenter(
      center: Offset(deviceSize.width / 2, deviceSize.height / 2),
      width: deviceSize.width,
      height: deviceSize.height,
    );
    final paint = Paint()..color = Color(0x99000000);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(deviceRect),
        Path()..addRRect(focusRRect),
      ),
      paint,
    );
  }

  /// Draw Focus area
  void _drawFocusArea(Canvas canvas, RRect focusRRect) {
    final Paint paintbox = (Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = const Color.fromARGB(153, 102, 160, 241));
    canvas.drawRRect(
      focusRRect,
      paintbox,
    );
  }

  void _drawText(
    Canvas canvas,
    TextBlock textBlock,
    double left,
    double right,
    double top,
  ) {
    final Paint background = Paint()..color = Color(0x99000000);
    final ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: 16,
        textDirection: TextDirection.ltr,
      ),
    );
    builder.pushStyle(
      ui.TextStyle(color: Colors.lightGreenAccent, background: background),
    );
    builder.addText(textBlock.text);
    builder.pop();
    canvas.drawParagraph(
      builder.build()
        ..layout(
          ParagraphConstraints(width: (right - left).abs()),
        ),
      Offset(left, top),
    );
  }

  void _drawCorner(Canvas canvas, TextBlock textBlock, Size size, Paint paint) {
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
    canvas.drawPoints(PointMode.polygon, cornerPoints, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final RRect focusRRect = RRect.fromLTRBR(
      (size.width - focusAreaWidth) / 2,
      (size.height - focusAreaHeight) / 2,
      (size.width - focusAreaWidth) / 2 + focusAreaWidth,
      (size.height - focusAreaHeight) / 2 + focusAreaHeight,
      Radius.circular(8.0),
    );

    _fillCameraMargin(canvas, size, focusRRect);
    _drawFocusArea(canvas, focusRRect);

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
      print(
          'textLeft: $textLeft, textTop: $textTop, textRight: $textRight, textBottom: $textBottom');
      print('textBlock.text: ${textBlock.text}');

      if (hasPointInRange(focusRRect, textRect)) {
        _drawText(canvas, textBlock, textLeft, textRight, textTop);
        _drawCorner(canvas, textBlock, size, paint);
      }
    }
  }

  @override
  bool shouldRepaint(TextRecognizerPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText;
  }
}
