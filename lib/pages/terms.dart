import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mikack_mobile/helper/chrome.dart';
import 'package:mikack_mobile/pages/base_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const termVersion = '0.0.1';
const acceptPermVersionKey = 'accept_perm_version';

class _TermsPage extends StatefulWidget {
  _TermsPage({this.readOnly});

  final bool readOnly;

  @override
  State<StatefulWidget> createState() => _TermsPageState();
}

const xSpacing = 38.0;

class _TermsPageState extends State<_TermsPage> {
  var _termContent = '载入中……';

  @override
  void initState() {
    fetchTermText();
    super.initState();
  }

  void fetchTermText() async {
    var termContent = await rootBundle.loadString('texts/terms.md');
    setState(() => _termContent = termContent);
  }

  void _handleAccept() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setString(acceptPermVersionKey, termVersion);
    showSystemUI();
    Navigator.pop(context);
  }

  Widget _buildBody() {
    var topPadding = 10.0;
    var bottomPadding = 4.0;
    var titleView = <Widget>[];
    var choiceView = <Widget>[];
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
      topPadding = xSpacing;
      bottomPadding = xSpacing;
    }

    return Container(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Column(
        children: [
          ...titleView,
          Expanded(
            child: Markdown(
              data: _termContent,
              padding: EdgeInsets.only(left: xSpacing, right: xSpacing),
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

class TermsPage extends BasePage {
  TermsPage({this.readOnly = true});

  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    if (!readOnly) {
      // 非只读隐藏系统 UI
      hiddenSystemUI();
      return WillPopScope(
        onWillPop: () async => false,
        child: _TermsPage(readOnly: readOnly),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('使用条款')),
      body: _TermsPage(readOnly: readOnly),
    );
  }
}
