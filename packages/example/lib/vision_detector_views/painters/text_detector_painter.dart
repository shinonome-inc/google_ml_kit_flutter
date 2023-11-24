import 'dart:ui';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'coordinates_translator.dart';

class TextRecognizerPainter extends CustomPainter {
  TextRecognizerPainter(
    this.recognizedText,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final RecognizedText recognizedText;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  /// [TextBlock]の四隅のポイントの座標が指定の範囲内にあるかどうか判定する。
  bool hasPointInRange(TextBlock textBlock) {
    print('textBlock.cornerPoints.length: ${textBlock.cornerPoints.length}');
    // 長方形の全て角の座標が正確に取得できていない場合は処理を中断する。
    if (textBlock.cornerPoints.length != 4) {
      return false;
    }
    for (final point in textBlock.cornerPoints) {
      print('point.x: ${point.x}, point.y: ${point.y}');
      // ポイントのX座標が指定範囲内に収まっているかどうか確認する。
      const double minX = 175;
      const double maxX = 575;
      if (point.x < minX || point.x > maxX) {
        return false;
      }
      // ポイントのY座標が指定範囲内に収まっているかどうか確認する。
      const double minY = 567;
      const double maxY = 767;
      if (point.y < minY || point.y > maxY) {
        return false;
      }
    }
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreenAccent;

    final Paint background = Paint()..color = Color(0x99000000);

    for (final textBlock in recognizedText.blocks) {
      print('hasPointInRange: ${hasPointInRange(textBlock)}');
      print('textBlock.text: ${textBlock.text}');
      if (!hasPointInRange(textBlock)) {
        continue;
      }

      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            textDirection: TextDirection.ltr),
      );
      builder.pushStyle(
          ui.TextStyle(color: Colors.lightGreenAccent, background: background));
      builder.addText(textBlock.text);
      builder.pop();

      final left = translateX(
        textBlock.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        textBlock.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        textBlock.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

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

      // Add the first point to close the polygon
      cornerPoints.add(cornerPoints.first);
      canvas.drawPoints(PointMode.polygon, cornerPoints, paint);

      canvas.drawParagraph(
        builder.build()
          ..layout(ParagraphConstraints(
            width: (right - left).abs(),
          )),
        Offset(left, top),
      );
    }
  }

  @override
  bool shouldRepaint(TextRecognizerPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText;
  }
}
