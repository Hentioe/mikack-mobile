import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mikack/src/models.dart' as models;
import 'comic.dart';

const listCoverSize = 50.0;
const listCoverRadius = listCoverSize / 2;

class ComicsView extends StatelessWidget {
  ComicsView(
      this.platform, this.isViewList, this.comics, this.scrollController);

  final models.Platform platform;
  final bool isViewList;
  final List<models.Comic> comics;
  final ScrollController scrollController;

  // 处理收藏按钮点击
  void _handleFavorite(models.Comic comic) {}

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

  Widget _buildViewMode(BuildContext context) {
    return GridView.count(
        crossAxisCount: 2,
        controller: scrollController,
        children: List.generate(comics.length, (index) {
          return Card(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  comics[index].cover,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding:
                        EdgeInsets.only(left: 5, top: 20, right: 5, bottom: 5),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                          Color.fromARGB(180, 0, 0, 0),
                          Colors.transparent,
                        ])),
                    child: Center(
                      child: Text(comics[index].title,
                          style: TextStyle(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                Positioned.fill(
                    child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: () => _openComicPage(context, comics[index])),
                ))
              ],
            ),
          );
        }));
  }

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

  void fetchComics() async {
    isLoading = true;
    var comics = await compute(
        _getComicsTask, {'platform': widget.platform, 'page': currentPage});
    setState(() {
      _comics.addAll(comics);
    });
    isLoading = false;
  }

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (!isLoading &&
          (scrollController.position.maxScrollExtent - 200) <=
              scrollController.offset) {
        // 翻页
        currentPage++;
        fetchComics();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_comics.length == 0) fetchComics();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_backspace),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.platform.name),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
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
      body: ComicsView(widget.platform, _isViewList, _comics, scrollController),
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
