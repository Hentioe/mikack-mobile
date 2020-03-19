import 'package:flutter/material.dart';
import 'package:mikack_mobile/widgets/text_hint.dart';
import '../widgets/comics_view.dart';

class BooksView extends StatelessWidget {
  BooksView(this.comicViewItems);

  final List<ComicViewItem> comicViewItems;

  @override
  Widget build(BuildContext context) {
    if (comicViewItems.length == 0)
      return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        return ListView(
          children: <Widget>[
            Container(
              child: Center(
                child: TextHint('下拉检查更新'),
              ),
              height: constraints.maxHeight,
            ),
          ],
        );
      });
    return Scrollbar(
      child: ComicsView(comicViewItems),
    );
  }
}

class _BooksUpdateFragment extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BooksUpdateFragmentState();
}

class _BooksUpdateFragmentState extends State<_BooksUpdateFragment> {
  List<ComicViewItem> _comicViewItems = [];

  @override
  void initState() {
    // TODO: 读取书架并获取更新
    super.initState();
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(Duration(seconds: 2), () {});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      child: Stack(
        children: [Positioned.fill(child: BooksView(_comicViewItems))],
      ),
      onRefresh: _handleRefresh,
    );
  }
}

class BooksUpdateFragment extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _BooksUpdateFragment();
  }
}
