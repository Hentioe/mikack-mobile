import 'package:easy_dialogs/easy_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info/package_info.dart';
import 'package:quiver/iterables.dart';
import 'package:url_launcher/url_launcher.dart';

import 'terms_page.dart';
import 'thanks_page.dart';
import '../blocs.dart';
import '../values.dart';
import '../widget/updates_sheet.dart';
import '../models.dart';
import '../helper/update_checker.dart';
import '../page/chaneglog_page.dart';

const _settingsItemSpacing = 16.0;
const _settingsPadding = 18.0;
const _settingsItemTrailingSize = 20.0;

final _readingModeItems = [
  ReadingModeItem(kLeftToRight),
  ReadingModeItem(kTopToBottom),
  ReadingModeItem(kPaperRoll),
];

final _startPageItems = [
  StartPageItem(kDefaultPage),
  StartPageItem(kBookshelvesPage),
  StartPageItem(kBooksUpdatePage),
  StartPageItem(kLibrariesPage),
  StartPageItem(kHistoriesPage),
];

class SettingsPage2 extends StatefulWidget {
  final BuildContext appContext;

  SettingsPage2({this.appContext});

  @override
  State<StatefulWidget> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage2> {
  SettingsBloc bloc;

  @override
  void initState() {
    bloc = SettingsBloc();
    bloc.add(SettingsRequestEvent());
    super.initState();
  }

  @override
  void dispose() {
    bloc.close();
    super.dispose();
  }

  Function() _handleSwitchTap(BuildContext context,
          SettingsSwitchType switchType, bool changedValue) =>
      () => bloc.add(SettingsSwitchedEvent(
          switchType: switchType, changedValue: changedValue));

  Function() _handleCleanupTap(
          BuildContext context, SettingsCleanupType cleanType) =>
      () => bloc.add(SettingsCleanupRequestEvent(cleanupType: cleanType));

  Widget _buildStartPageDialog() {
    return SingleChoiceConfirmationDialog<StartPageItem>(
      title: Text('选择开始页面'),
      initialValue: (bloc.state as SettingsLoadedSate).startPage,
      items: _startPageItems,
      cancelActionButtonLabel: '取消',
      submitActionButtonLabel: '确定',
      onSelected: (page) =>
          bloc.add(SettingsStartPageChangedEvent(startPage: page)),
    );
  }

  Widget _buildReadingModeDialog() {
    return SingleChoiceConfirmationDialog<ReadingModeItem>(
      title: Text('选择阅读模式'),
      initialValue: (bloc.state as SettingsLoadedSate).readingMode,
      items: _readingModeItems,
      cancelActionButtonLabel: '取消',
      submitActionButtonLabel: '确定',
      onSubmitted: (mode) {
        bloc.add(ReadingModeChangedEvent(readingMode: mode));
      },
    );
  }

  Widget _buildPreLoadingDialog() {
    return SingleChoiceConfirmationDialog<num>(
      title: Text('预加载页面数量'),
      initialValue: (bloc.state as SettingsLoadedSate).preLoading,
      items: range(9).toList(),
      cancelActionButtonLabel: '取消',
      submitActionButtonLabel: '确定',
      onSubmitted: (value) {
        bloc.add(SettingsPreLoadingChangedEvent(preLoading: value.toInt()));
      },
    );
  }

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: '无法启动浏览器，手动访问看看吧',
      );
    }
  }

  Function() _handleCheckUpdate(
          BuildContext context, PackageInfo packageInfo) =>
      () async {
        Fluttertoast.showToast(msg: '检查更新中，请稍等…');
        var updates = await checkUpdates(packageInfo);
        if (updates == null)
          Fluttertoast.showToast(msg: '暂未发现更新');
        else {
          showModalBottomSheet(
            context: widget.appContext,
            builder: (context) => UpdatesSheet(releases: updates),
          );
        }
      };

  void _openFavoritesCleanDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('清空书架'),
        content: Text('书架收藏可能是比较重要的资源，您确定要清空吗？'),
        actions: [
          FlatButton(
            child: Text("取消"),
            onPressed: () => Navigator.of(context).pop(), //关闭对话框
          ),
          FlatButton(
            child: Text("确认"),
            onPressed: () {
              _handleCleanupTap(context, SettingsCleanupType.favorites)();
              Navigator.of(context).pop(true); //关闭对话框
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: SingleChildScrollView(
        child: MultiBlocListener(
          listeners: [
            BlocListener<SettingsBloc, SettingsState>(
              bloc: bloc,
              condition: (prevState, state) {
                if (prevState != bloc.initialState &&
                    prevState is SettingsLoadedSate &&
                    state is SettingsLoadedSate) {
                  return prevState.cachedImageSize != state.cachedImageSize;
                }
                return false;
              },
              listener: (context, state) => Fluttertoast.showToast(
                msg: '图片缓存已清理',
              ),
            ),
            BlocListener<SettingsBloc, SettingsState>(
              bloc: bloc,
              condition: (prevState, state) {
                if (prevState != bloc.initialState &&
                    prevState is SettingsLoadedSate &&
                    state is SettingsLoadedSate) {
                  return prevState.historiesTotal != state.historiesTotal;
                }
                return false;
              },
              listener: (context, state) {
                Fluttertoast.showToast(
                  msg: '历史记录已清空',
                );
                widget.appContext
                    ?.bloc<HistoriesBloc>()
                    ?.add(HistoriesRequestEvent());
              },
            ),
            BlocListener<SettingsBloc, SettingsState>(
              bloc: bloc,
              condition: (prevState, state) {
                if (prevState != bloc.initialState &&
                    prevState is SettingsLoadedSate &&
                    state is SettingsLoadedSate) {
                  return prevState.favoritesTotal != state.favoritesTotal;
                }
                return false;
              },
              listener: (context, state) {
                Fluttertoast.showToast(
                  msg: '书架已清空',
                );
                widget.appContext
                    ?.bloc<BookshelvesBloc>()
                    ?.add(BookshelvesRequestEvent.sortByDefault());
              },
            ),
          ],
          child: BlocBuilder<SettingsBloc, SettingsState>(
            bloc: bloc,
            builder: (context, state) {
              var castedState = state as SettingsLoadedSate;
              return Column(
                children: [
                  SizedBox(height: _settingsItemSpacing),
                  _SettingItemGroup(
                    '基本设置',
                    children: [
                      _SettingItem(
                        '开始页面',
                        subtitle: castedState.startPage.toString(),
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => _buildStartPageDialog(),
                        ),
                      ),
                      _SettingItem(
                        '解锁 NSFW 来源',
                        subtitle: '可能包含令人不适的成人内容',
                        trailing:
                            _SettingsCheckBoxIcon(value: castedState.allowNsfw),
                        onTap: () {
                          // 切换开关状态
                          _handleSwitchTap(
                              context,
                              SettingsSwitchType.allowNsfw,
                              !castedState.allowNsfw)();
                          // 更新过滤条件
                          widget.appContext
                              .bloc<FiltersBloc>()
                              .add(FiltersAllowNsfwUpdatedEvent(
                                isAllow: !castedState.allowNsfw,
                                historiesBloc:
                                    widget.appContext?.bloc<LibrariesBloc>(),
                              ));
                        },
                      ),
                      _SettingItem(
                        '倒序排列章节',
                        subtitle: '章节列表从高到低排序',
                        trailing: _SettingsCheckBoxIcon(
                            value: castedState.chaptersReversed),
                        onTap: _handleSwitchTap(
                            context,
                            SettingsSwitchType.chaptersReversed,
                            !castedState.chaptersReversed),
                      ),
                    ],
                  ),
                  SizedBox(height: _settingsItemSpacing),
                  _SettingItemGroup(
                    '阅读设置',
                    children: [
                      _SettingItem(
                        '阅读模式',
                        subtitle: castedState.readingMode.toString(),
                        onTap: () => showDialog(
                            context: context, child: _buildReadingModeDialog()),
                      ),
                      _SettingItem(
                        '左手翻页',
                        subtitle: '反转默认的触摸翻页方向（不影响滑动手势）',
                        trailing: _SettingsCheckBoxIcon(
                            value: castedState.leftHandMode),
                        onTap: _handleSwitchTap(
                            context,
                            SettingsSwitchType.leftHandMode,
                            !castedState.leftHandMode),
                      ),
                      _SettingItem(
                        '预加载页面',
                        subtitle: castedState.preLoading.toString(),
                        onTap: () => showDialog(
                            context: context, child: _buildPreLoadingDialog()),
                      ),
                      _SettingItem(
                        '预缓存图片',
                        subtitle: '提前下载预加载页面中的图片',
                        trailing: _SettingsCheckBoxIcon(
                            value: castedState.preCaching),
                        onTap: _handleSwitchTap(
                            context,
                            SettingsSwitchType.preCaching,
                            !castedState.preCaching),
                      ),
                    ],
                  ),
                  SizedBox(height: _settingsItemSpacing),
                  _SettingItemGroup(
                    '数据清理',
                    children: [
                      _SettingItem(
                        '清空图片缓存',
                        subtitle: castedState.cachedImageSize > 0.0
                            ? '占用 ${castedState.cachedImageSize.toStringAsFixed(2)} MB'
                            : '缓存是空的',
                        onTap: _handleCleanupTap(
                            context, SettingsCleanupType.cachedImages),
                      ),
                      _SettingItem('清空历史记录',
                          subtitle: castedState.historiesTotal > 0
                              ? '存在 ${castedState.historiesTotal} 条可见历史'
                              : '阅读历史是空的',
                          onTap: _handleCleanupTap(
                              context, SettingsCleanupType.histories)),
                      _SettingItem('清空书架收藏',
                          subtitle: castedState.favoritesTotal > 0
                              ? '上架 ${castedState.favoritesTotal} 本图书'
                              : '书架是空的',
                          onTap: () => _openFavoritesCleanDialog(context)),
                    ],
                  ),
                  SizedBox(height: _settingsItemSpacing),
                  _SettingItemGroup(
                    '掌握动态',
                    children: [
                      _SettingItem(
                        '项目仓库',
                        subtitle: vRepoUrl.replaceFirst('https://', ''),
                        onTap: () => launchUrl(vRepoUrl),
                      ),
                      _SettingItem(
                        '加入群组',
                        subtitle: vGroupUrl.replaceFirst('https://', ''),
                        onTap: () => launchUrl(vGroupUrl),
                      ),
                    ],
                  ),
                  SizedBox(height: _settingsItemSpacing),
                  _SettingItemGroup(
                    '关于',
                    children: [
                      _SettingItem('检查更新',
                          subtitle: castedState.packageInfo != null
                              ? '${castedState.packageInfo.version}-${castedState.packageInfo.buildNumber}'
                              : '获取中…',
                          onTap: _handleCheckUpdate(
                              context, castedState.packageInfo)),
                      _SettingItem('更新日志',
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => ChangelogPage()))),
                      _SettingItem(
                        '使用条款',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => TermsPage(readOnly: true))),
                      ),
                      _SettingItem(
                        '特别鸣谢',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ThanksPage())),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Text(
                      '@ 2020 mikack.me',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                          fontFamily: 'Monospace'),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  _SettingItem(this.title, {this.subtitle, this.onTap, this.trailing});

  final String title;
  final String subtitle;
  final void Function() onTap;
  final Widget trailing;

  static final titleStyle = TextStyle(
    fontSize: 15.0,
    color: Colors.grey[900],
  );

  static final subtitleStyle = TextStyle(
    fontSize: 13.0,
    color: Colors.grey[700],
  );

  @override
  Widget build(BuildContext context) {
    List<Widget> mainRowChildren = [
      Expanded(
        child: Text(title, style: titleStyle),
      )
    ];
    if (trailing != null) mainRowChildren.add(trailing);
    List<Widget> children = [Row(children: mainRowChildren)];
    if (subtitle != null) {
      children.add(SizedBox(height: 4));
      children.add(Text(subtitle, style: subtitleStyle));
    }

    return InkWell(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300])),
        ),
        padding: EdgeInsets.only(
          top: _settingsItemSpacing,
          bottom: _settingsItemSpacing,
          left: _settingsPadding,
          right: _settingsPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
      onTap: () {
        if (onTap != null) onTap();
      },
    );
  }
}

class _SettingItemGroup extends StatelessWidget {
  static final titleStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent,
  );

  static Widget _buildTitle(String text) {
    return Container(
      padding: EdgeInsets.only(left: _settingsPadding),
      child: Text(text, style: titleStyle),
    );
  }

  _SettingItemGroup(this.title, {this.children = const <Widget>[]});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitle(title),
        SizedBox(height: _settingsItemSpacing),
        ...items
      ],
    );
  }
}

class _SettingsCheckBoxIcon extends StatelessWidget {
  _SettingsCheckBoxIcon({this.value = false});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return value
        ? Icon(Icons.check_box,
            color: vPrimarySwatch, size: _settingsItemTrailingSize)
        : Icon(Icons.check_box_outline_blank, size: _settingsItemTrailingSize);
  }
}
