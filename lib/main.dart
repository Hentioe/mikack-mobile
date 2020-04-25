import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:github_releases/github_models.dart';
import 'package:package_info/package_info.dart';
import 'package:quiver/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/helper/update_checker.dart';
import 'src/logging.dart';
import 'pages/search.dart';
import 'src/page/terms_page.dart';
import 'src/widget/series_system_ui.dart';
import 'src/page/settings_page.dart';
import 'src/fragments.dart';
import 'src/blocs.dart';
import 'src/models.dart';
import 'src/values.dart';
import 'src/dialog/libraries_filters_dialog.dart';
import 'src/widget/updates_sheet.dart';

const bookshelfSortByKey = 'bookshelf_sort_by';

final drawerItems = LinkedHashMap.from({
  'default': '系统默认',
  'bookshelf': '我的书架',
  'books_update': '书架更新',
  'libraries': '图书仓库',
  'histories': '浏览历史',
});

const defaultDrawerIndex = 0;

Future<int> getDrawerIndex() async {
  int index = defaultDrawerIndex;
  var prefs = await SharedPreferences.getInstance();
  var lockedKey = prefs.getString(kStartPageKey);
  if (lockedKey != null && lockedKey != 'default') {
    var entries = drawerItems.entries.toList();
    for (var i = 1; i < entries.length; i++) {
      if (entries[i].key == lockedKey) {
        index = i - 1;
        break;
      }
    }
  }
  return index;
}

void main() async {
  initLogger();
  WidgetsFlutterBinding.ensureInitialized();
  sleep(Duration(milliseconds: 800));
  runApp(MyApp(await getDrawerIndex()));
}

class MyApp extends StatelessWidget {
  MyApp(this.drawerIndex);

  final int drawerIndex;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mikack mobile',
      theme: ThemeData(
        // This is the theme
        primarySwatch: vPrimarySwatch,
      ),
      home: MultiBlocProvider(
        providers: [
          BlocProvider<BookshelfBloc>(
            create: (_) => BookshelfBloc(),
          ),
          BlocProvider<UpdatesBloc>(
            create: (_) => UpdatesBloc(),
          ),
          BlocProvider<LibrariesBloc>(
            create: (_) => LibrariesBloc(),
          ),
          BlocProvider<HistoriesBloc>(
            create: (_) => HistoriesBloc(),
          ),
        ],
        child: MyHomePage(drawerIndex: drawerIndex),
      ),
    );
  }
}

final startPages = BiMap<String, String>();

class DrawerItem {
  final String title;
  final IconData iconData;
  final Widget fragment;
  final List<Widget> actions;

  DrawerItem(this.title, this.iconData, this.fragment,
      {this.actions = const []});
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.drawerIndex}) : super(key: key) {
    startPages.addEntries(drawerItems.entries.map(
      (entry) => MapEntry(entry.key, entry.value),
    ));
  }

  final int drawerIndex;

  @override
  _MyHomePageState createState() => _MyHomePageState(drawerIndex: drawerIndex);
}

const headerLogoSize = 65.0;

class _MyHomePageState extends State<MyHomePage> {
  _MyHomePageState({drawerIndex = 0}) {
    this._drawerIndex = drawerIndex;
  }

  int _drawerIndex;
  List<DrawerItem> _drawerItems = [];
  List<int> _includeTags = [];
  List<int> _excludesTags = [vNsfwTagIntValue];
  bool allowNsfw = false;
  List<Release> _updates;

  @override
  void initState() {
    initDrawerItems();
    fetchAllowNsfw();
    checkPermAccept();
    sendFragmentEvent();
    checkNewVersion();
    super.initState();
  }

  void checkNewVersion() async {
    var packageInfo = await PackageInfo.fromPlatform();
    var newestReleases = await checkUpdates(packageInfo);
    if (newestReleases != null && newestReleases.isNotEmpty) {
      setState(() {
        _updates = newestReleases;
      });
    }
  }

  /// 根据 fragment 类型发送事件（当内容页为 StatelessWidget 时需要）
  /// TODO: 在已存在数据的情况下避免重复刷新
  void sendFragmentEvent() {
    switch (_drawerItems[_drawerIndex].fragment.runtimeType) {
      case UpdatesFragment2:
        BlocProvider.of<UpdatesBloc>(context).add(UpdatesRequestEvent.local());
        break;
      case BookshelfFragment2:
        BlocProvider.of<BookshelfBloc>(context)
            .add(BookshelfRequestEvent.sortByDefault());
        break;
      case HistoriesFragment2:
        BlocProvider.of<HistoriesBloc>(context).add(HistoriesRequestEvent());
        break;
    }
  }

  void checkPermAccept() async {
    var prefs = await SharedPreferences.getInstance();
    var versionStr = prefs.getString(acceptPermVersionKey);
    if (versionStr == null)
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => TermsPage(readOnly: false)));
  }

  void fetchAllowNsfw() async {
    var prefs = await SharedPreferences.getInstance();
    var isAllow = prefs.getBool(kAllowNsfw);
    if (isAllow == null) isAllow = false;
    allowNsfw = isAllow;
    if (isAllow) {
      // 如果启用，则排除并重写载入
      if (_excludesTags.contains(vNsfwTagIntValue)) {
        _excludesTags.remove(vNsfwTagIntValue);
      }
    } else {
      // 没启用，添加排除标签并删除包含标签
      if (!_excludesTags.contains(vNsfwTagIntValue)) {
        _excludesTags.add(vNsfwTagIntValue);
        if (_includeTags.contains(vNsfwTagIntValue))
          _includeTags.remove(vNsfwTagIntValue);
      }
    }
    BlocProvider.of<LibrariesBloc>(context).add(LibrariesFiltersUpdatedEvent(
        includes: _includeTags, excludes: _excludesTags));
  }

  final _header = DrawerHeader(
    decoration: BoxDecoration(color: vPrimarySwatch),
    child: Row(
      children: [
        Image.asset(
          'assets/logo.png',
          width: headerLogoSize,
          height: headerLogoSize,
        )
      ],
    ),
  );

  _onSelectItem(int index) {
    setState(() => _drawerIndex = index);
    Navigator.of(context).pop(); // 关闭抽屉
    // 发送事件
    sendFragmentEvent();
  }

  void _handleLibrariesFilter() {
    openLibrariesFiltersDialog(context,
            includes: _includeTags,
            excludes: _excludesTags,
            allowNsfw: allowNsfw)
        .then((filters) {
      var includes = filters.item1;
      var excludes = filters.item2;

      setState(() {
        _includeTags = includes;
        _excludesTags = excludes;
      });
      BlocProvider.of<LibrariesBloc>(context).add(
          LibrariesFiltersUpdatedEvent(includes: includes, excludes: excludes));
    });
  }

  Widget _buildBookshelfSortMenuView() {
    return BlocBuilder<BookshelfBloc, BookshelfState>(
      builder: (context, state) {
        var castedState = state as BookshelfLoadedState;
        return PopupMenuButton<BookshelfSort>(
          tooltip: '修改排序方式',
          icon: Icon(Icons.sort),
          onSelected: (sortBy) => BlocProvider.of<BookshelfBloc>(context)
              .add(BookshelfRequestEvent(sortBy: sortBy)),
          itemBuilder: (BuildContext context) => [
            CheckedPopupMenuItem(
              checked: castedState.sortBy == BookshelfSort.readAt,
              enabled: castedState.sortBy != BookshelfSort.readAt,
              value: BookshelfSort.readAt,
              child: Text('上次阅读时间'),
            ),
            CheckedPopupMenuItem(
              checked: castedState.sortBy == BookshelfSort.insertedAt,
              enabled: castedState.sortBy != BookshelfSort.insertedAt,
              value: BookshelfSort.insertedAt,
              child: Text('最近添加时间'),
            ),
          ],
        );
      },
    );
  }

  void openGlobalSearchPage() =>
      Navigator.of(context).push(_createGlobalSearchRoute());

  void initDrawerItems() {
    _drawerItems = [
      DrawerItem(
        '我的书架',
        Icons.class_,
        BookshelfFragment2(
            openLibrariesPage: () => setState(() => _drawerIndex = 2),
            openGlobalSearchPage: openGlobalSearchPage),
        actions: [_buildBookshelfSortMenuView()],
      ),
      DrawerItem('书架更新', Icons.fiber_new, UpdatesFragment2()),
      DrawerItem(
        '图书仓库',
        Icons.store,
        LibrariesFragment2(),
        actions: [
          IconButton(
              tooltip: '打开过滤菜单',
              icon: Icon(Icons.filter_list),
              onPressed: _handleLibrariesFilter)
        ],
      ),
      DrawerItem('浏览历史', Icons.history, HistoriesFragment2()),
    ];
  }

  // 由于导航栏颜色问题暂时无法解决，放弃自定义页面路由动画
  Route _createGlobalSearchRoute() {
    return PageRouteBuilder(
      barrierColor: Colors.white,
      pageBuilder: (_, animation, secondaryAnimation) =>
          SearchPage(appContext: context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(0.0, 1.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var drawerListView = <Widget>[];
    for (var i = 0; i < _drawerItems.length; i++) {
      var d = _drawerItems[i];
      drawerListView.add(new ListTile(
        leading: new Icon(d.iconData),
        title: new Text(d.title),
        selected: i == _drawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }

    List<Widget> _buildNewVersionFound() {
      var children = <Widget>[];
      if (_updates != null && _updates.isNotEmpty) {
        children.add(ListTile(
          leading: Icon(Icons.new_releases),
          title: Text('发现新版！'),
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (context) => UpdatesSheet(releases: _updates),
          ), // 设置页面返回后刷新可能变更的数据
        ));
      }

      return children;
    }

    return SeriesSystemUI(
      child: Scaffold(
        appBar: AppBar(
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                tooltip: '打开导航菜单',
              );
            },
          ),
          title: Text(_drawerItems[_drawerIndex].title),
          actions: [
            IconButton(
              tooltip: '打开全局搜索',
              icon: Icon(Icons.search),
              onPressed: openGlobalSearchPage,
            ),
            ..._drawerItems[_drawerIndex].actions
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header,
              Column(
                children: drawerListView,
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('设置'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SettingsPage2(appContext: context)),
                ).then((_) => fetchAllowNsfw()), // 设置页面返回后刷新可能变更的数据
              ),
              ..._buildNewVersionFound(),
            ],
          ),
        ),
        body: _drawerItems[_drawerIndex].fragment,
      ),
    );
  }
}
