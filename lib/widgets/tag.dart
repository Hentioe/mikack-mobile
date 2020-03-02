import 'package:flutter/material.dart';

class Tag extends StatelessWidget {
  Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blueAccent),
        color: Colors.blueAccent,
      ),
      padding: EdgeInsets.only(left: 10, right: 10, top: 0.5, bottom: 0.5),
      child: Container(
        height: 14,
        child: Center(
          child: Text(text,
              style: TextStyle(
                  fontSize: 10, color: Colors.white, fontFamily: 'Monospace')),
        ),
      ),
    );
  }
}
