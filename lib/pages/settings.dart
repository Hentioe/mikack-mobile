import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:easy_dialogs/easy_dialogs.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mikack_mobile/pages/term.dart';
import 'package:mikack_mobile/store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../pages/base_page.dart';
import '../main.dart' show startPages;

const _settingsItemSpacing = 16.0;
const _settingsPadding = 18.0;
const _settingsItemTrailingSize = 20.0;

const settingsRepoUrl = 'https://github.com/Hentioe/mikack-mobile';
const settingsGroupUrl = 'https://t.me/mikack';

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
            color: primaryColor, size: _settingsItemTrailingSize)
        : Icon(Icons.check_box_outline_blank, size: _settingsItemTrailingSize);
  }
}

const startPageKey = 'start_page';
const leftHandModeKey = 'left_mode';
const allowNsfwKey = 'allow_nsfw';
const chaptersReversedKey = 'chapters_reversed';

class _SettingsView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<_SettingsView> {
  final copyrightTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey[400],
    fontFamily: 'Monospace',
  );

  @override
  void initState() {
    fetchSelectedPage();
    fetchLeftHandMode();
    fetchAllowNsfw();
    fetchHistoriesTotal();
    fetchFavoritesTotal();
    fetchChaptersRerversed();
    super.initState();
  }

  var _selectedPage = 'default';
  var _leftHandMode = false;
  var _allowNsfw = false;
  var _chaptersReversed = false;
  var _historitesTotal = 0;
  var _favoritesTotal = 0;

  void fetchSelectedPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      var selected = prefs.getString(startPageKey);
      if (selected != null) _selectedPage = selected;
    });
  }

  void fetchChaptersRerversed() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      var enabled = prefs.getBool(chaptersReversedKey);
      if (enabled != null) _chaptersReversed = enabled;
    });
  }

  void fetchLeftHandMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      var enabled = prefs.getBool(leftHandModeKey);
      if (enabled != null) _leftHandMode = enabled;
    });
  }

  void fetchAllowNsfw() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      var enabled = prefs.getBool(allowNsfwKey);
      if (enabled != null) _allowNsfw = enabled;
    });
  }

  void updateSelectedPage(key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(startPageKey, key);
    setState(() => _selectedPage = key);
  }

  Widget _buildStartPageDialog() {
    return SingleChoiceDialog<String>(
      title: Text('选择开始页面'),
      items: startPages.values.toList(),
      isDividerEnabled: true,
      onSelected: (text) {
        updateSelectedPage(startPages.inverse[text]);
      },
    );
  }

  void _handleReversedChapters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chaptersReversedKey, !_chaptersReversed);
    setState(() => _chaptersReversed = !_chaptersReversed);
  }

  void _handleLeftHandMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(leftHandModeKey, !_leftHandMode);
    setState(() => _leftHandMode = !_leftHandMode);
  }

  void _handAllowNsfw() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(allowNsfwKey, !_allowNsfw);
    setState(() => _allowNsfw = !_allowNsfw);
  }

  void launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Fluttertoast.showToast(
        msg: '无法自动打开链接，手动试试看？',
      );
    }
  }

  void fetchHistoriesTotal() async {
    var total = await getHistoriesTotal();
    setState(() => _historitesTotal = total);
  }

  void _handleHistoriesClean() async {
    await deleteAllHistories();
    fetchHistoriesTotal();
    Fluttertoast.showToast(msg: '历史记录已清空');
  }

  void fetchFavoritesTotal() async {
    var total = await getFavoritesTotal();
    setState(() => _favoritesTotal = total);
  }

  void cleanFavorites() async {
    await deleteAllFavorites();
    fetchFavoritesTotal();
    Fluttertoast.showToast(msg: '书架已清空');
  }

  void _handleFavoritesClean() {
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
              cleanFavorites();
              Navigator.of(context).pop(true); //关闭对话框
            },
          ),
        ],
      ),
    );
  }

  void _handleCachedImageClean() async {
    await clearDiskCachedImages();
    Fluttertoast.showToast(
      msg: '图片缓存已清理',
    );
  }

  Widget _buildContentView() {
    return Column(
      children: [
        SizedBox(height: _settingsItemSpacing),
        _SettingItemGroup(
          '基本设置',
          children: [
            _SettingItem(
              '开始页面',
              subtitle: startPages[_selectedPage],
              onTap: () => showDialog(
                context: context,
                builder: (_) => _buildStartPageDialog(),
              ),
            ),
            _SettingItem(
              '左手翻页',
              subtitle: '反转默认的翻页操作方向',
              trailing: _SettingsCheckBoxIcon(value: _leftHandMode),
              onTap: _handleLeftHandMode,
            ),
            _SettingItem(
              '允许 NSFW 内容',
              subtitle: '将显示不宜于工作场合公开的资源（可能包含成人内容）',
              trailing: _SettingsCheckBoxIcon(value: _allowNsfw),
              onTap: _handAllowNsfw,
            ),
            _SettingItem(
              '倒序排列章节',
              subtitle: '章节列表从高到低排序',
              trailing: _SettingsCheckBoxIcon(value: _chaptersReversed),
              onTap: _handleReversedChapters,
            ),
          ],
        ),
        SizedBox(height: _settingsItemSpacing),
        _SettingItemGroup(
          '数据清理',
          children: [
            _SettingItem(
              '清空图片缓存',
              onTap: _handleCachedImageClean,
            ),
            _SettingItem('清空历史记录',
                subtitle: _historitesTotal > 0
                    ? '存在 $_historitesTotal 条可见历史'
                    : '没有阅读记录',
                onTap: () => _handleHistoriesClean()),
            _SettingItem('清空书架收藏',
                subtitle:
                    _favoritesTotal > 0 ? '上架 $_favoritesTotal 本图书' : '书架是空的',
                onTap: () => _handleFavoritesClean()),
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
            _SettingItem('检查更新'),
            _SettingItem(
              '使用条款',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => TermPage(readOnly: true))),
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
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [_buildContentView()],
    );
  }
}

class SettingsPage extends BasePage {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: _SettingsView(),
    );
  }
}
