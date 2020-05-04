import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:fluttertoast/fluttertoast.dart';

const defaultSelectedTagColor = Colors.blueAccent;
const defaultTagPadding =
    EdgeInsets.only(left: 10, right: 10, top: 0.5, bottom: 0.5);
const defaultFixedStateTagReason = '标签状态被锁定，不可更改';

class Tag extends StatefulWidget {
  final double fontSize;
  final int value;
  final String text;
  final Color color;
  final bool selected;
  final bool stateful;
  final bool stateFixed;
  final String stateFixedReason;
  final void Function(int, bool) onTap;

  Tag(
    this.value,
    this.text, {
    this.fontSize = 10.0,
    this.color = defaultSelectedTagColor,
    this.selected = false,
    this.stateful = false,
    this.stateFixed = false,
    this.stateFixedReason,
    this.onTap,
  });

  @override
  State<StatefulWidget> createState() => _TagState();
}

class _TagState extends State<Tag> with TickerProviderStateMixin {
  var _selected;

  @override
  void initState() {
    super.initState();
  }

  void handleTap(int value) {
    if (widget.stateful) {
      if (widget.stateFixed) {
        if (_selected == null) _selected = widget.selected;
      } else {
        setState(() {
          if (_selected == null)
            _selected = !widget.selected;
          else
            _selected = !_selected;
        });
      }
    }
    if (widget.stateFixed)
      Fluttertoast.showToast(
        msg: widget.stateFixedReason != null
            ? widget.stateFixedReason
            : defaultFixedStateTagReason,
      );
    else if (widget.onTap != null && !widget.stateFixed)
      widget.onTap(value, _selected ?? !widget.selected);
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
            border: Border.all(color: widget.color),
            color: selected ? widget.color : Colors.transparent,
          ),
          padding: defaultTagPadding,
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: widget.fontSize,
              color: selected ? Colors.white : widget.color,
              fontFamily: 'Monospace',
              height: 1.5,
            ),
          ),
        ),
        onTap: () => handleTap(widget.value));
  }
}
