import 'package:flutter/material.dart';

final _defaultFontColor = Colors.grey[400];

class TextHint extends StatelessWidget {
  const TextHint(this.text, {this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text,
          style: TextStyle(fontSize: 18, color: color ?? _defaultFontColor)),
    );
  }
}
