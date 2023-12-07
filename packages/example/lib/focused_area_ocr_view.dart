import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'camera_view.dart';
import 'script_dropdown_button.dart';
import 'text_detector_painter.dart';

class FocusedAreaOCRView extends StatefulWidget {
  const FocusedAreaOCRView({
    Key? key,
    this.focusedAreaWidth = 200.0,
    this.focusedAreaHeight = 40.0,
    this.focusedAreaRadius = const Radius.circular(8.0),
    this.focusedAreaPaint,
    this.unfocusedAreaPaint,
    this.textBackgroundPaint,
    this.paintTextStyle,
    required this.onScanText,
    this.script = TextRecognitionScript.latin,
    this.showDropdown = true,
  }) : super(key: key);

  final double? focusedAreaWidth;
  final double? focusedAreaHeight;
  final Radius? focusedAreaRadius;
  final Paint? focusedAreaPaint;
  final Paint? unfocusedAreaPaint;
  final Paint? textBackgroundPaint;
  final ui.TextStyle? paintTextStyle;
  final Function? onScanText;
  final TextRecognitionScript script;
  final bool showDropdown;

  @override
  State<FocusedAreaOCRView> createState() => _FocusedAreaOCRViewState();
}

class _FocusedAreaOCRViewState extends State<FocusedAreaOCRView> {
  late TextRecognitionScript _script;
  late TextRecognizer _textRecognizer;
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.back;

  void _onChangedScript(TextRecognitionScript script) {
    setState(() {
      _script = script;
      _textRecognizer.close();
      _textRecognizer = TextRecognizer(script: _script);
    });
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    final recognizedText = await _textRecognizer.processImage(inputImage);
    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = TextRecognizerPainter(
        recognizedText: recognizedText,
        imageSize: inputImage.metadata!.size,
        rotation: inputImage.metadata!.rotation,
        cameraLensDirection: _cameraLensDirection,
        focusedAreaWidth: widget.focusedAreaWidth!,
        focusedAreaHeight: widget.focusedAreaHeight!,
        focusedAreaRadius: widget.focusedAreaRadius!,
        focusedAreaPaint: widget.focusedAreaPaint,
        unfocusedAreaPaint: widget.unfocusedAreaPaint,
        textBackgroundPaint: widget.textBackgroundPaint,
        paintTextStyle: widget.paintTextStyle,
        onScanText: widget.onScanText,
      );
      _customPaint = CustomPaint(painter: painter);
    } else {
      // TODO: set _customPaint to draw boundingRect on top of image
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    _script = widget.script;
    _textRecognizer = TextRecognizer(script: _script);
    super.initState();
  }

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CameraView(
          customPaint: _customPaint,
          onImage: _processImage,
          initialCameraLensDirection: _cameraLensDirection,
          onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
        ),
        if (widget.showDropdown)
          ScriptDropdownButton(
            onChanged: (script) => _onChangedScript,
            script: _script,
          ),
      ],
    );
  }
}
