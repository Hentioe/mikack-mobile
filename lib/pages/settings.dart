import 'package:flutter/material.dart';
import 'package:easy_dialogs/easy_dialogs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/base_page.dart';
import '../main.dart' show startPages;

const _settingsItemSpacing = 16.0;
const _settingsPadding = 18.0;
const _settingsItemTrailingSize = 20.0;

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
    fontSize: 12.0,
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
    super.initState();
  }

  var _selectedPage = 'default';
  var _leftHandMode = false;
  var _allowNsfw = false;

  void fetchSelectedPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      var selected = prefs.getString(startPageKey);
      if (selected != null) _selectedPage = selected;
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
    return SingleChoiceConfirmationDialog<String>(
      title: Text('选择开始页面'),
      initialValue: startPages[_selectedPage],
      items: startPages.values.toList(),
      onSubmitted: (text) {
        updateSelectedPage(startPages.inverse[text]);
      },
    );
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
              '左手翻页模式',
              subtitle: '反转默认翻页的操作方向',
              trailing: _SettingsCheckBoxIcon(value: _leftHandMode),
              onTap: _handleLeftHandMode,
            ),
            _SettingItem(
              '允许 NSFW 内容',
              subtitle: '将显示不宜于工作场合公开的资源（可能包含成人内容）',
              trailing: _SettingsCheckBoxIcon(value: _allowNsfw),
              onTap: _handAllowNsfw,
            ),
          ],
        ),
        SizedBox(height: _settingsItemSpacing),
        _SettingItemGroup(
          '数据清理',
          children: [
            _SettingItem('清空图片缓存'),
            _SettingItem('清空阅读历史'),
            _SettingItem('清空书架图书'),
          ],
        ),
        SizedBox(height: _settingsItemSpacing),
        _SettingItemGroup(
          '掌握动态',
          children: [
            _SettingItem('关注作者', subtitle: 'Hentioe (绅士喵)'),
            _SettingItem(
              '项目仓库',
              subtitle: 'https://github.com/Hentioe/mikack-mobile',
            ),
            _SettingItem('加入群组', subtitle: 'https://t.me/mikack'),
          ],
        ),
        SizedBox(height: _settingsItemSpacing),
        _SettingItemGroup(
          '关于',
          children: [
            _SettingItem('检查更新'),
            _SettingItem('使用条款'),
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
