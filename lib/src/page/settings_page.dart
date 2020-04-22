import 'package:easy_dialogs/easy_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:github_releases/github_releases.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import 'terms_page.dart';
import 'thanks_page.dart';
import '../blocs.dart';
import '../values.dart';
import '../ext.dart';
import '../widget/updates_sheet.dart';
import '../models.dart';

const _settingsItemSpacing = 16.0;
const _settingsPadding = 18.0;
const _settingsItemTrailingSize = 20.0;

final _readingModeItems = [
  ReadingModeItem(vLeftToRight),
  ReadingModeItem(vTopToBottom),
  ReadingModeItem(vPaperRoll),
];

final _startPageItems = [
  StartPageItem(vDefaultPage),
  StartPageItem(vBookshelfPage),
  StartPageItem(vBooksUpdatePage),
  StartPageItem(vLibrariesPage),
  StartPageItem(vHistoriesPage),
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

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: '无法启动浏览器，手动访问看看吧',
      );
    }
  }

  bool isNewestVersion(PackageInfo packageInfo, String tagName) {
    return 'v${packageInfo.tagging()}' != tagName;
  }

  Function() _handleCheckUpdate(
          BuildContext context, PackageInfo packageInfo) =>
      () async {
        Fluttertoast.showToast(msg: '检查更新中，请稍等…');
        var releases = await getReleases(repoOwner, repoName);
        if (releases.length == 0 ||
            !isNewestVersion(packageInfo, releases.first.tagName)) {
          Fluttertoast.showToast(msg: '暂未发现更新');
        } else {
          var lastRelease = releases.first;
          showModalBottomSheet(
            context: widget.appContext,
            builder: (context) => UpdatesSheet(release: lastRelease),
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

  final copyrightTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey[400],
    fontFamily: 'Monospace',
  );

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
                    ?.bloc<BookshelfBloc>()
                    ?.add(BookshelfRequestEvent.sortByDefault());
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
                        '允许 NSFW 内容',
                        subtitle: '将显示不宜于工作场合公开的资源（可能包含成人内容）',
                        trailing:
                            _SettingsCheckBoxIcon(value: castedState.allowNsfw),
                        onTap: _handleSwitchTap(
                            context,
                            SettingsSwitchType.allowNsfw,
                            !castedState.allowNsfw),
                      ),
                      _SettingItem(
                        '倒序排列章节',
                        subtitle: '章节列表从高到低排序',
                        trailing: _SettingsCheckBoxIcon(
                            value: castedState.chaptersReversed),
                        onTap: _handleSwitchTap(
                            context,
                            SettingsSwitchType.reverseChapters,
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
                        subtitle: '反转默认的翻页操作方向',
                        trailing:
                            _SettingsCheckBoxIcon(value: castedState.leftHand),
                        onTap: _handleSwitchTap(context,
                            SettingsSwitchType.leftHand, !castedState.leftHand),
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
                        subtitle: settingsRepoUrl.replaceFirst('https://', ''),
                        onTap: () => launchUrl(settingsRepoUrl),
                      ),
                      _SettingItem(
                        '加入群组',
                        subtitle: settingsGroupUrl.replaceFirst('https://', ''),
                        onTap: () => launchUrl(settingsGroupUrl),
                      ),
                    ],
                  ),
                  SizedBox(height: _settingsItemSpacing),
                  _SettingItemGroup(
                    '关于',
                    children: [
                      _SettingItem('检查更新',
                          subtitle: castedState.packageInfo.tagging(),
                          onTap: _handleCheckUpdate(
                              context, castedState.packageInfo)),
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
                      style: copyrightTextStyle,
                    ),
                  ),
                  Center(
                    child: Text(
                      'All rights reserved.',
                      style: copyrightTextStyle,
                    ),
                  ),
                  SizedBox(height: 40),
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
            color: primarySwatch, size: _settingsItemTrailingSize)
        : Icon(Icons.check_box_outline_blank, size: _settingsItemTrailingSize);
  }
}
