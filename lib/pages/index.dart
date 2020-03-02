import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:mikack/models.dart' as models;
import '../widgets/comics_view.dart';
import 'comic.dart';
import 'package:tuple/tuple.dart';

const listCoverSize = 50.0;
const listCoverRadius = 4.0;

class IndexesView extends StatelessWidget {
  IndexesView(this.platform, this.isViewList, this.comics,
      this.scrollController, this.httpHeaders);

  final models.Platform platform;
  final bool isViewList;
  final List<models.Comic> comics;
  final ScrollController scrollController;
  final Map<String, String> httpHeaders;

  // 处理收藏按钮点击
  static void _handleFavorite(models.Comic comic) {}

  // 打开阅读页面
  void _openComicPage(BuildContext context, models.Comic comic) {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => ComicPage(platform, comic)));
  }

  Widget _buildViewList(BuildContext context) {
    var children = comics
        .map((c) => ListTile(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(listCoverRadius),
                child: Image.network(c.cover,
                    headers: httpHeaders,
                    fit: BoxFit.cover,
                    height: listCoverSize,
                    width: listCoverSize),
              ),
              title: Text(c.title),
              trailing: IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () => _handleFavorite(c)),
              onTap: () => _openComicPage(context, c),
            ))
        .toList();
    return ListView(
      children: children,
      controller: scrollController,
    );
  }

  Widget _buildViewMode(BuildContext context) => ComicsView(
        comics,
        inStackItemBuilders: gridViewInStackItemBuilders,
        onTap: (comic) => _openComicPage(context, comic),
        scrollController: scrollController,
        httpHeaders: httpHeaders,
      );

  final gridViewInStackItemBuilders = [
    (comic) => Positioned(
          right: 0,
          top: 0,
          child: Material(
            color: Colors.transparent,
            child: IconButton(
                icon: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                ),
                onPressed: () => _handleFavorite(comic)),
          ),
        ),
  ];

  Widget _buildLoading() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (comics.length == 0) {
      return _buildLoading();
    } else if (isViewList) {
      return Scrollbar(
        child: _buildViewList(context),
      );
    } else {
      return Scrollbar(
        child: _buildViewMode(context),
      );
    }
  }
}

class MainView extends StatefulWidget {
  MainView(this.platform);

  final models.Platform platform;

  @override
  State<StatefulWidget> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  List<models.Comic> _comics = [];
  var _isViewList = false;
  var isLoading = false;
  var currentPage = 1;
  var _isSearching = false;

  final TextEditingController editingController = TextEditingController();

  void fetchComics() async {
    isLoading = true;
    var comics = await compute(
        _getComicsTask, {'platform': widget.platform, 'page': currentPage});
    setState(() {
      _comics.addAll(comics);
    });
    isLoading = false;
  }

  void searchComics(String keywords) async {
    isLoading = true;
    setState(() {
      _comics.clear();
    });
    var comics =
        await compute(_searchComicsTask, Tuple2(widget.platform, keywords));
    setState(() {
      _comics.addAll(comics);
    });
    isLoading = false;
  }

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 输入事件（搜索）
    editingController.addListener(() {});
    // 滚动事件（翻页）
    scrollController.addListener(() {
      if (!isLoading &&
          (scrollController.position.maxScrollExtent - 200) <=
              scrollController.offset) {
        currentPage++;
        fetchComics();
      }
    });
  }

  // 搜索
  void submitSearch(String keywords) {
    searchComics(keywords);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_comics.length == 0) fetchComics();
    var isSearchable = widget.platform.isSearchable;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_backspace),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            // 搜索框
            ? TextField(
                style: TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                autofocus: true,
                onSubmitted: submitSearch,
                decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2))),
              )
            // 标题
            : Text(widget.platform.name),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search,
                color: Color.fromARGB(isSearchable ? 255 : 155, 255, 255, 255)),
            onPressed: isSearchable
                ? () {
                    // 关闭搜索框
                    if (_isSearching) {
                      editingController.clear();
                    } else {
                      // 打开搜索框
                    }
                    setState(() {
                      _isSearching = !_isSearching;
                    });
                  }
                : null,
          ),
          IconButton(
            icon: Icon(_isViewList ? Icons.view_module : Icons.view_list),
            onPressed: () {
              setState(() {
                _isViewList = !_isViewList;
              });
            },
          ),
        ],
      ),
      body:
          IndexesView(widget.platform, _isViewList, _comics, scrollController, {
        'Referer':
            '${widget.platform.isHttps ? 'https' : 'http'}://${widget.platform.domain}'
      }),
    );
  }
}

class IndexPage extends StatelessWidget {
  IndexPage(this.platform);

  final models.Platform platform;

  @override
  Widget build(BuildContext context) {
    return MainView(platform);
  }
}

List<models.Comic> _getComicsTask(args) {
  models.Platform platform = args['platform'];
  int page = args['page'];
  return platform.index(page);
}

List<models.Comic> _searchComicsTask(Tuple2<models.Platform, String> args) {
  var platform = args.item1;
  var keywords = args.item2;
  return platform.search(keywords);
}
