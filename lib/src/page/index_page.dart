import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikack/models.dart' as models;

import '../blocs.dart';
import '../widget/comics_view.dart';
import '../page/comic_page.dart';

class IndexPage2 extends StatefulWidget {
  final models.Platform platform;

  IndexPage2(this.platform);

  @override
  State<StatefulWidget> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage2> {
  IndexBloc bloc;
  bool _inSearching = false;
  String _searchKeywords;

  final ScrollController scrollController = ScrollController();
  final TextEditingController editingController = TextEditingController();

  // 提交搜索
  void _handleSearchKeywordsSubmit(String keywords) {
    _inSearching = true;
    _searchKeywords = keywords;
    bloc.add(IndexSearchEvent(page: 1, keywords: _searchKeywords));
  }

  // 搜索输入框显示状态
  void _handleSearchPress() {
    if (_inSearching) {
      // 关闭搜索框并重新请求第一页
      editingController.clear();
      bloc.add(IndexRequestEvent(page: 1));
    }

    setState(() {
      _inSearching = !_inSearching;
    });
  }

  void _handleRetry() {
    var stateSnapshot = bloc.state as IndexLoadedState;

    if (stateSnapshot.currentKeywords.isEmpty) // 重试索引请求
      bloc.add(IndexRequestEvent(page: stateSnapshot.currentPage));
    else // 重试搜索请求
      bloc.add(IndexSearchEvent(
          keywords: stateSnapshot.currentKeywords,
          page: stateSnapshot.currentPage));
  }

  // 打开阅读页面
  void _openComicPage(models.Comic comic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ComicPage(platform: widget.platform, comic: comic),
      ),
    );
  }

  @override
  void initState() {
    bloc = IndexBloc(widget.platform);
    bloc.add(IndexRequestEvent(page: 1));
    // 滚动事件
    scrollController.addListener(() {
      // 判断是否触发下一页
      final stateSnapshot = bloc.state;
      if (stateSnapshot is IndexLoadedState) {
        // 是否在触发位置范围
        final inNextPagePosition =
            (scrollController.position.maxScrollExtent - 800) <=
                scrollController.offset;
        if (!stateSnapshot.isFetching && inNextPagePosition) {
          // 发送翻页请求
          if (stateSnapshot.currentKeywords.isEmpty) {
            if (widget.platform.isPageable) // 请求索引数据
              bloc.add(IndexRequestEvent(page: stateSnapshot.currentPage + 1));
          } else {
            // 请求搜索数据
            if (widget.platform.isSearchPageable)
              bloc.add(IndexSearchEvent(
                keywords: stateSnapshot.currentKeywords,
                page: stateSnapshot.currentPage + 1,
              ));
          }
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  final emptyView = Center(
    child: Text(
      '空结果',
      style: const TextStyle(fontSize: 18, color: Colors.grey),
    ),
  );

  // 加载视图
  final loadingProgress = const Center(
    child: CircularProgressIndicator(),
  );

  final fetchingProgress = const Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: LinearProgressIndicator(),
  );

  Widget __buildIndexesView({
    @required List<ComicViewItem> comicViewItems,
    @required bool isViewList,
    @required bool isFetching,
  }) {
    if (comicViewItems.isEmpty) {
      if (isFetching) return loadingProgress;
      return emptyView;
    } else {
      Widget comicsView = ComicsView(
        comicViewItems,
        isViewList: isViewList,
        onTap: _openComicPage,
        scrollController: scrollController,
      );
      var stackChildren = [comicsView];
      if (isFetching) stackChildren.add(fetchingProgress);
      return Scrollbar(
        child: Stack(
          children: stackChildren,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener(
      bloc: bloc,
      // 发生错误时弹出错误消息
      condition: (prevState, state) {
        if (prevState is IndexLoadedState && state is IndexLoadedState) {
          return state.error;
        }
        return false;
      },
      listener: (context, state) {
        if (state is IndexLoadedState) {
          Fluttertoast.showToast(msg: state.errorMessage);
        }
      },
      child: BlocBuilder<IndexBloc, IndexState>(
        bloc: bloc,
        builder: (context, state) {
          var castedState = state as IndexLoadedState;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.keyboard_backspace),
                onPressed: () => Navigator.pop(context),
              ),
              title: _inSearching
                  // 搜索框
                  ? TextField(
                      style: TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.search,
                      autofocus: true,
                      controller: editingController,
                      onSubmitted: _handleSearchKeywordsSubmit,
                      decoration: InputDecoration(
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    )
                  // 标题
                  : Text(widget.platform.name),
              actions: [
                IconButton(
                  icon: Icon(
                    _inSearching ? Icons.close : Icons.search,
                    color: Color.fromARGB(
                        widget.platform.isSearchable ? 255 : 155,
                        255,
                        255,
                        255),
                  ),
                  // 搜索点击事件
                  onPressed:
                      widget.platform.isSearchable ? _handleSearchPress : null,
                ),
                IconButton(
                  icon: Icon(castedState.isViewList
                      ? Icons.view_module
                      : Icons.view_list),
                  onPressed: () => bloc.add(IndexViewModeChangedEvent(
                      isViewList: !castedState.isViewList)),
                ),
              ],
            ),
            body: castedState.error
                ? Center(
                    child: RaisedButton(
                        child: Text('重试'), onPressed: _handleRetry),
                  )
                : __buildIndexesView(
                    comicViewItems: castedState.comicViewItems,
                    isFetching: castedState.isFetching,
                    isViewList: castedState.isViewList,
                  ),
          );
        },
      ),
    );
  }
}
