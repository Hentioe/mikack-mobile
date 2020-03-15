import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

const defaultSelectedTagColor = Colors.blueAccent;
const defaultTagPadding =
    EdgeInsets.only(left: 10, right: 10, top: 0.5, bottom: 0.5);

class Tag extends StatelessWidget {
  Tag(this.value, this.text, {this.selected = false, this.onTap});

  final int value;
  final String text;
  final bool selected;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        // 圆角
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: defaultSelectedTagColor),
          color: selected ? defaultSelectedTagColor : Colors.transparent,
        ),
        padding: defaultTagPadding,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: selected ? Colors.white : defaultSelectedTagColor,
            fontFamily: 'Monospace',
            height: 1.5,
          ),
        ),
      ),
      onTap: onTap != null ? () => onTap(value) : null,
    );
  }
}
