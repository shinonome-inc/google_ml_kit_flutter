import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'camera_util.dart';
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
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
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
  final VoidCallback? onCameraFeedReady;
  final VoidCallback? onDetectorViewModeChanged;
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;

  @override
  State<FocusedAreaOCRView> createState() => _FocusedAreaOCRViewState();
}

class _FocusedAreaOCRViewState extends State<FocusedAreaOCRView> {
  late TextRecognitionScript _script;
  late TextRecognizer _textRecognizer;
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  final CameraLensDirection _cameraLensDirection = CameraLensDirection.back;
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;

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

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does NOT work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }

  Future<void> _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = CameraUtil.inputImageFromCameraImage(
      image: image,
      controller: _controller,
      cameras: _cameras,
      cameraIndex: _cameraIndex,
    );
    if (inputImage == null) return;
    _processImage(inputImage);
  }

  Future<void> _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == _cameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void initState() {
    _script = widget.script;
    _textRecognizer = TextRecognizer(script: _script);
    _initialize();
    super.initState();
  }

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraPreview(
      _controller!,
      child: _customPaint,
    );
  }
}
