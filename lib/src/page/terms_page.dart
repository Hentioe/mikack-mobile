import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/chrome.dart';

const termVersion = '0.0.1';
const acceptPermVersionKey = 'accept_perm_version';

class _TermsView extends StatefulWidget {
  _TermsView({this.readOnly});

  final bool readOnly;

  @override
  State<StatefulWidget> createState() => _TermsViewState();
}

const xSpacing = 38.0;

class _TermsViewState extends State<_TermsView> {
  var _termContent = '载入中……';

  @override
  void initState() {
    fetchTermText();
    super.initState();
  }

  void fetchTermText() async {
    var termContent = await rootBundle.loadString('assets/text/terms.md');
    setState(() => _termContent = termContent);
  }

  void _handleAccept() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(acceptPermVersionKey, termVersion);
    showSystemUI();
    Navigator.pop(context);
  }

  Widget _buildBody() {
    var containerTopPadding = 10.0;
    var containerBottomPadding = 4.0;
    var markdownTopPadding = 0.0;
    var markdownBottomPadding = 0.0;
    var titleView = <Widget>[];
    var choiceView = <Widget>[];
    var backgroundColor = Colors.white;
    // 如果非只读（同意条款）
    if (!widget.readOnly) {
      // 显示标题（使用条款）
      titleView.addAll([Text('使用条款'), SizedBox(height: 30)]);
      // 显示选择按钮（拒绝、同意）
      choiceView.add(Row(
        children: [
          Expanded(
            child: MaterialButton(
              child: Text(
                '拒绝',
                style: TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold),
              ),
              onPressed: () =>
                  SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
            ),
          ),
          Expanded(
            child: MaterialButton(
              child: Text(
                '接受',
                style:
                    TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _handleAccept(),
            ),
          ),
        ],
      ));
    } else {
      containerTopPadding = 0;
      containerBottomPadding = 0;
      markdownTopPadding = xSpacing;
      markdownBottomPadding = xSpacing;
      // 去掉背景色
      backgroundColor = null;
    }

    return Container(
      color: backgroundColor,
      padding: EdgeInsets.only(
          top: containerTopPadding, bottom: containerBottomPadding),
      child: Column(
        children: [
          ...titleView,
          Expanded(
            child: Markdown(
              data: _termContent,
              padding: EdgeInsets.only(
                left: xSpacing,
                top: markdownTopPadding,
                right: xSpacing,
                bottom: markdownBottomPadding,
              ),
              styleSheet: MarkdownStyleSheet(
                blockSpacing: 10,
                a: TextStyle(
                  fontSize: 13,
                  color: Colors.blueAccent[700],
                ),
                p: TextStyle(fontSize: 13, color: Colors.grey[900]),
                h1: TextStyle(fontSize: 16, color: Colors.black),
                h2: TextStyle(fontSize: 15, color: Colors.black),
                h3: TextStyle(fontSize: 14, color: Colors.black),
                h4: TextStyle(fontSize: 13, color: Colors.black),
                h5: TextStyle(fontSize: 12, color: Colors.black),
                h6: TextStyle(fontSize: 11, color: Colors.black),
              ),
            ),
          ),
          ...choiceView
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }
}

class TermsPage extends StatelessWidget {
  TermsPage({this.readOnly = true});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (!readOnly) {
      // 非只读隐藏系统 UI
      hiddenSystemUI();
      return WillPopScope(
        onWillPop: () async => false,
        child: _TermsView(readOnly: readOnly),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('使用条款')),
      body: _TermsView(readOnly: readOnly),
    );
  }
}
