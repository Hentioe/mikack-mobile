import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

const defaultSelectedTagColor = Colors.blueAccent;
const defaultTagPadding =
    EdgeInsets.only(left: 10, right: 10, top: 0.5, bottom: 0.5);

class _Tag extends StatefulWidget {
  _Tag(
    this.value,
    this.text, {
    this.selected,
    this.stateful,
    this.onTap,
  });

  final int value;
  final String text;
  final bool selected;
  final bool stateful;
  final void Function(int, bool) onTap;

  @override
  State<StatefulWidget> createState() => _TagState();
}

class _TagState extends State<_Tag> {
  var _selected;

  @override
  void initState() {
    super.initState();
  }

  void handleTap(int value) {
    if (widget.stateful)
      setState(() {
        if (_selected == null)
          _selected = !widget.selected;
        else
          _selected = !_selected;
      });
    if (widget.onTap != null) widget.onTap(value, _selected || false);
  }

  @override
  Widget build(BuildContext context) {
    var selected = widget.selected;
    // 有状态的
    if (widget.stateful && _selected != null) {
      selected = _selected;
    }
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
            widget.text,
            style: TextStyle(
              fontSize: 10,
              color: selected ? Colors.white : defaultSelectedTagColor,
              fontFamily: 'Monospace',
              height: 1.5,
            ),
          ),
        ),
        onTap: () => handleTap(widget.value));
  }
}

class Tag extends StatelessWidget {
  Tag(
    this.value,
    this.text, {
    this.selected = false,
    this.stateful = false,
    this.onTap,
  });

  final int value;
  final String text;
  final bool selected;
  final bool stateful;
  final void Function(int, bool) onTap;

  @override
  Widget build(BuildContext context) => _Tag(
        value,
        text,
        selected: selected,
        stateful: stateful,
        onTap: onTap,
      );
}
