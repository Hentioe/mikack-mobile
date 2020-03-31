import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mikack_mobile/main.dart' show platformList;
import 'package:mikack_mobile/pages/base_page.dart';

class _ThanksPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ThanksState();
}

class _ThanksState extends State<_ThanksPage> {
  var _content = '载入中……';

  void fetchContent() async {
    var content = await rootBundle.loadString('texts/thanks.md');
    var sourcesContent = platformList
        .map((p) => '- [${p.domain}](${p.domain})')
        .toList()
        .join('\n');

    setState(
        () => _content = content.replaceAll('{{sources}}', sourcesContent));
  }

  @override
  void initState() {
    fetchContent();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('特别鸣谢'),
      ),
      body: Markdown(
        data: _content,
        padding: EdgeInsets.all(20),
        styleSheet: MarkdownStyleSheet(
            blockSpacing: 6,
            a: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              decoration: TextDecoration.underline,
            ),
            p: TextStyle(fontSize: 13, color: Colors.grey[900]),
            strong: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            )),
      ),
    );
  }
}

class ThanksPage extends BasePage {
  @override
  Widget build(BuildContext context) => _ThanksPage();
}
