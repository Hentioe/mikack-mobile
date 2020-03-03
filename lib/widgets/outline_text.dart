import 'package:flutter/material.dart';

const defaultTextColor = Color.fromARGB(255, 255, 255, 255);
const defaultOutlineColor = Color.fromARGB(255, 180, 180, 180);

class OutlineText extends StatelessWidget {
  OutlineText(this.text,
      {this.fontSize,
      this.textColor = defaultTextColor,
      this.outlineColor = defaultOutlineColor,
      this.outlineWidth = 1.5});

  final String text;
  final double fontSize;
  final Color textColor;
  final Color outlineColor;
  final double outlineWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Stroked text as border.
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = outlineWidth
              ..color = outlineColor,
          ),
        ),
        // Solid text as fill.
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
