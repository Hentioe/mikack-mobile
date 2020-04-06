import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meta/meta.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;

import '../../pages/detail.dart';
import '../../pages/index.dart';
import '../../src/blocs.dart';
import '../../widgets/favicon.dart';
import '../../widgets/text_hint.dart';
import '../platform_list.dart';

const _rootSpacing = 15.0;

class LibrariesFragment2 extends StatelessWidget {
  LibrariesFragment2();

  void Function(models.Platform) _handleItemTap(BuildContext context) =>
      (models.Platform platform) => Navigator.push(context,
          MaterialPageRoute(builder: (context) => IndexPage(platform)));

  void Function(models.Platform) _handleItemDetail(BuildContext context) =>
      (models.Platform platform) => Navigator.push(context,
          MaterialPageRoute(builder: (context) => DetailPage(platform)));

  void Function(models.Platform, List<models.Platform>, bool)
      _handleItemLongTap(BuildContext context) => (models.Platform platform,
              List<models.Platform> filteredList, bool fromFixed) =>
          BlocProvider.of<LibrariesBloc>(context)
              .add(LibrariesFixedUpdatedEvent(
            platform: platform,
            filteredList: filteredList,
            fromFixed: fromFixed,
          ));

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibrariesBloc, LibrariesState>(
      condition: (prevState, state) => state is LibrariesGroupedListState,
      builder: (context, state) {
        return ListView(
          padding: EdgeInsets.all(_rootSpacing),
          children: [
            if (state is LibrariesGroupedListState) ...[
              _Group(
                title: '已固定',
                platforms: state.fixedList,
                emptyHint: '长按固定于此',
                handleItemTap: _handleItemTap(context),
                handleItemDetail: _handleItemDetail(context),
                handleItemLongPress: _handleItemLongTap(context),
              ),
              SizedBox(height: 20),
              _Group(
                title: state.filteredList.length == platformList.length
                    ? '全部'
                    : '已过滤',
                platforms: state.fixedHiddenFilteredList,
                showDomain: true,
                handleItemTap: _handleItemTap(context),
                handleItemDetail: _handleItemDetail(context),
                handleItemLongPress: _handleItemLongTap(context),
              ),
            ]
          ],
        );
      },
    );
  }
}

class _Group extends StatelessWidget {
  _Group({
    @required this.title,
    this.platforms = const [],
    this.showDomain = false,
    this.emptyHint = '空列表',
    this.handleItemTap,
    this.handleItemDetail,
    this.handleItemLongPress,
  });

  final String title;
  final List<models.Platform> platforms;
  final bool showDomain;
  final String emptyHint;
  final void Function(models.Platform) handleItemTap;
  final void Function(models.Platform) handleItemDetail;
  final void Function(
          models.Platform, List<models.Platform> filteredList, bool fromFixed)
      handleItemLongPress;

  Widget _buildPlatformItemView(models.Platform platform) {
    return Container(
      decoration: BoxDecoration(
        border: platforms.last.domain != platform.domain
            ? Border(bottom: BorderSide(color: Colors.grey[300]))
            : null,
      ),
      child: ListTile(
        leading: Hero(
          tag: 'favicon-${platform.domain}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Favicon(platform, size: 30),
          ),
        ),
        title: Text(platform.name),
        subtitle: showDomain
            ? Text(platform.domain, style: TextStyle(color: Colors.grey[600]))
            : null,
        trailing: OutlineButton(
          textColor: Colors.blueAccent,
          borderSide: BorderSide(color: Colors.blueAccent),
          highlightedBorderColor: Colors.blueAccent,
          child: Text('详细'),
          onPressed: () => handleItemDetail(platform),
        ),
        onTap: () => handleItemTap(platform),
        onLongPress: () =>
            handleItemLongPress(platform, platforms, title == '已固定'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        SizedBox(height: 10),
        platforms.length == 0
            ? TextHint(emptyHint, color: Colors.grey[350]) // 空列表提示
            : Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children:
                      platforms.map((p) => _buildPlatformItemView(p)).toList(),
                ),
              )
      ],
    );
  }
}
