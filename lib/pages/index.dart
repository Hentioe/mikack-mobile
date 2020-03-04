import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:mikack/models.dart' as models;
import '../widgets/comics_view.dart';
import 'comic.dart';
import 'package:tuple/tuple.dart';
import '../fragments/libraries.dart' show buildHeaders;
import '../store.dart';
import '../ext.dart';

const viewListCoverHeight = double.infinity;
const viewListCoverWidth = 50.0;
const listCoverRadius = 4.0;

class IndexesView extends StatefulWidget {
  IndexesView(
    this.platform,
    this.isViewList,
    this.comics,
    this.scrollController,
    this.httpHeaders, {
    this.isFetchingNext = false,
  });

  final models.Platform platform;
  final bool isViewList;
  final List<models.Comic> comics;
  final ScrollController scrollController;
  final Map<String, String> httpHeaders;
  final bool isFetchingNext;

  @override
  State<StatefulWidget> createState() => _IndexViewState();
}

class _IndexViewState extends State<IndexesView> {
  var _favoriteAddresses = <String>[];

  @override
  void initState() {
    super.initState();
    // 加载收藏列表
    fetchFavoriteAddresses();
  }

  // 处理收藏按钮点击
  void _handleFavorite(models.Comic comic, bool isCancel) async {
    var source = await widget.platform.toSavedSource();
    if (!isCancel) {
      // 收藏
      await insertFavorite(Favorite(
        sourceId: source.id,
        name: comic.title,
        address: comic.url,
        cover: comic.cover,
      ));
      setState(() => _favoriteAddresses.add(comic.url));
    } else {
      // 取消收藏
      await deleteFavorite(address: comic.url);
      setState(() => _favoriteAddresses.remove(comic.url));
    }
  }

  void fetchFavoriteAddresses() async {
    (await findFavorites()).forEach(
      (f) => setState(() => _favoriteAddresses.add(f.address)),
    );
  }

  // 打开阅读页面
  void _openComicPage(BuildContext context, models.Comic comic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComicPage(widget.platform, comic),
      ),
    );
  }

  // 列表显示的边框形状
  final viewListShape = const RoundedRectangleBorder(
      borderRadius: BorderRadiusDirectional.all(Radius.circular(1)));

  // 列表显示
  Widget _buildViewList(BuildContext context) {
    var children = widget.comics
        .map((c) => Card(
              shape: viewListShape,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Image.network(c.cover,
                    headers: widget.httpHeaders,
                    fit: BoxFit.cover,
                    height: viewListCoverHeight,
                    width: viewListCoverWidth),
                title: Text(c.title,
                    style: TextStyle(color: Colors.black),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                    icon: Icon(Icons.favorite_border), onPressed: () => {}),
                onTap: () => _openComicPage(context, c),
              ),
            ))
        .toList();
    return ListView(
      children: children,
      controller: widget.scrollController,
    );
  }

  // 网格显示
  Widget _buildViewMode() => ComicsView(
        widget.comics,
        enableFavorite: true,
        handleFavorite: _handleFavorite,
        onTap: (comic) => _openComicPage(context, comic),
        scrollController: widget.scrollController,
        favoriteAddresses: _favoriteAddresses,
      );

  // 加载视图
  final loadingView = const Center(
    child: CircularProgressIndicator(),
  );

  // 加载视图（下一页）
  final loadingNextView = const Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: LinearProgressIndicator(),
  );

  @override
  Widget build(BuildContext context) {
    if (widget.comics.length == 0)
      return loadingView;
    else {
      var itemsView =
          widget.isViewList ? _buildViewList(context) : _buildViewMode();
      var stackChildren = [itemsView];
      if (widget.isFetchingNext) stackChildren.add(loadingNextView);
      return Scrollbar(
        child: Stack(
          children: stackChildren,
        ),
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
  var _isFetchingNext = false;
  var searched = false;

  Map<String, String> headers;

  final TextEditingController editingController = TextEditingController();

  void fetchComics({init: false}) async {
    isLoading = true;
    if (init) {
      // 清理结果，并重置到第一页
      currentPage = 1;
      setState(() {
        _comics.clear();
      });
    }
    if (currentPage > 1)
      setState(() {
        _isFetchingNext = true;
      });
    var comics =
        await compute(_getComicsTask, Tuple2(widget.platform, currentPage));
    comics.forEach((c) => c.headers = headers);
    setState(() {
      _comics.addAll(comics);
    });
    isLoading = false;
    if (currentPage > 1)
      setState(() {
        _isFetchingNext = false;
      });
  }

  void searchComics(String keywords) async {
    isLoading = true;
    setState(() {
      _comics.clear();
    });
    var comics =
        await compute(_searchComicsTask, Tuple2(widget.platform, keywords));
    comics.forEach((c) => c.headers = headers);
    setState(() {
      _comics.addAll(comics);
    });
    isLoading = false;
  }

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 共享同一个资源 headers
    headers = widget.platform.buildBaseHeaders();
    // 加载第一页
    fetchComics();
    // 输入事件（搜索）
    editingController.addListener(() {});
    // 滚动事件（翻页）
    scrollController.addListener(() {
      if (!isLoading &&
          (scrollController.position.maxScrollExtent - 800) <=
              scrollController.offset &&
          !_isSearching) {
        currentPage++;
        fetchComics();
      }
    });
  }

  // 搜索
  void submitSearch(String keywords) {
    searched = true;
    searchComics(keywords);
  }

  // 点击搜索事件
  void handleSearchBtnClick() {
    // 关闭搜索框
    if (_isSearching) {
      editingController.clear();
      // 如果搜索过，重置搜索结果
      if (searched) {
        searched = false;
        fetchComics(init: true); // 重置结果
      }
    } else {
      // 打开搜索框
    }
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // 搜索点击事件
            onPressed: isSearchable ? handleSearchBtnClick : null,
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
      body: IndexesView(
        widget.platform,
        _isViewList,
        _comics,
        scrollController,
        widget.platform.buildBaseHeaders(),
        isFetchingNext: _isFetchingNext,
      ),
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

List<models.Comic> _getComicsTask(Tuple2<models.Platform, int> args) {
  var platform = args.item1;
  var page = args.item2;
  return platform.index(page);
}

List<models.Comic> _searchComicsTask(Tuple2<models.Platform, String> args) {
  var platform = args.item1;
  var keywords = args.item2;
  return platform.search(keywords);
}
