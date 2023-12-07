import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ScriptDropdownButton extends StatelessWidget {
  const ScriptDropdownButton({
    Key? key,
    this.onChanged,
    required this.script,
  }) : super(key: key);
  final void Function(TextRecognitionScript?)? onChanged;
  final TextRecognitionScript script;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 120.0,
        height: 40.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: DropdownButton<TextRecognitionScript>(
          value: script,
          icon: const Icon(Icons.arrow_downward),
          elevation: 16,
          style: const TextStyle(color: Colors.blue),
          underline: Container(
            height: 2,
            color: Colors.blue,
          ),
          onChanged: onChanged,
          items: TextRecognitionScript.values
              .map<DropdownMenuItem<TextRecognitionScript>>((script) {
            return DropdownMenuItem<TextRecognitionScript>(
              value: script,
              child: Text(script.name),
            );
          }).toList(),
        ),
      ),
    );
  }
}
