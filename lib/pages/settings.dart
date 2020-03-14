import 'package:flutter/material.dart';
import '../pages/base_page.dart';

const _settingsItemSpacing = 14.0;
const _settingsPadding = 18.0;

class _SettingItem extends StatelessWidget {
  _SettingItem(this.title, {this.subtitle});

  final String title;
  final String subtitle;

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
    List<Widget> children = [Text(title, style: titleStyle)];
    if (subtitle != null) {
      children.add(SizedBox(height: 4));
      children.add(Text(subtitle, style: subtitleStyle));
    }

    return InkWell(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100])),
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
      onTap: () {},
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

class SettingsPage extends BasePage {
  final copyrightTextStyle = TextStyle(
    fontSize: 12,
    color: Colors.grey[400],
    fontFamily: 'Monospace',
  );

  Widget _buildContentView() {
    return Column(
      children: [
        SizedBox(height: _settingsItemSpacing),
        _SettingItemGroup(
          '基本设置',
          children: [
            _SettingItem('开始页面', subtitle: '我的书架'),
            _SettingItem('左手翻页模式', subtitle: '反转默认翻页的操作方向'),
            _SettingItem('允许 NSFW 内容', subtitle: '显示不宜工作场合公开的内容（可能包含成人内容）'),
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
        SizedBox(height: 40),
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
        SizedBox(height: 50),
      ],
    );
  }

  Widget _buildBodyView() {
    return ListView(
      children: [_buildContentView()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: _buildBodyView(),
    );
  }
}
