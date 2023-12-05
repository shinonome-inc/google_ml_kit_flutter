import 'dart:async';

import 'package:flutter/material.dart';

import 'vision_detector_views/text_detector_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final StreamController<String> controller = StreamController<String>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          TextRecognizerView(
            onScanText: (text) {
              print(text);
              controller.add(text);
            },
          ),
          SafeArea(
            child: StreamBuilder<String>(
              stream: controller.stream,
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                return Text(
                  snapshot.data != null ? snapshot.data! : '',
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
