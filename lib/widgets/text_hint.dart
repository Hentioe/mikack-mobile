import 'package:flutter/material.dart';

class TextHint extends StatelessWidget {
  const TextHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: Center(
        child:
            Text(text, style: TextStyle(fontSize: 18, color: Colors.grey[400])),
      ),
    );
  }
}
