import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;

class ChaptersTab extends StatelessWidget {
  ChaptersTab(
    this.comic, {
    this.openReadPage,
    this.handleChapterReadMark,
    this.handleChapterUnReadMark,
    this.handleChaptersReadMark,
    this.readHistoryLinks = const [],
  });

  final models.Comic comic;
  final void Function(models.Chapter) openReadPage;
  final void Function(models.Chapter) handleChapterReadMark;
  final void Function(models.Chapter) handleChapterUnReadMark;
  final void Function(List<models.Chapter>) handleChaptersReadMark;
  final List<String> readHistoryLinks;

  void _handleMorePopupMenuSelect(int value, models.Chapter chapter) async {
    switch (value) {
      case 0:
        handleChapterReadMark(chapter);
        break;
      case 1:
        handleChapterUnReadMark(chapter);
        break;
      case 2:
        var beforeHistories =
            comic.chapters.where((c) => c.which < chapter.which).toList();
        handleChaptersReadMark(beforeHistories);
        break;
    }
  }

  Widget _buildMorePopupMenu(models.Chapter chapter) {
    return PopupMenuButton<int>(
      icon: Icon(Icons.more_vert),
      onSelected: (value) => _handleMorePopupMenuSelect(value, chapter),
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          enabled: !readHistoryLinks.contains(chapter.url),
          value: 0,
          child: Text('标记已读'),
        ),
        PopupMenuItem(
          enabled: readHistoryLinks.contains(chapter.url),
          value: 1,
          child: Text('标记未读'),
        ),
        PopupMenuItem(
          value: 2,
          child: Text('标记之前章节已读'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (comic.chapters == null)
      return const Center(
        child: CircularProgressIndicator(),
      );
    return Scrollbar(
      child: ListView(
        children: comic.chapters
            .map((c) => ListTile(
                  title: Text(
                    c.title,
                    style: TextStyle(
                      color: readHistoryLinks.contains(c.url)
                          ? Colors.grey[500]
                          : Colors.black,
                    ),
                  ),
                  trailing: _buildMorePopupMenu(c),
                  onTap: () => openReadPage(c),
                ))
            .toList(),
      ),
    );
  }
}
