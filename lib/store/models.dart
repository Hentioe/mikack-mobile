import 'package:mikack/models.dart';

class Source {
  int id;
  String domain;
  String name;

  static final String tableName = "sources";

  Source({this.id, this.domain, this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'domain': domain,
      'name': name,
    };
  }

  factory Source.fromMap(Map<String, dynamic> map) {
    return Source(
      id: map['id'],
      domain: map['domain'],
      name: map['name'],
    );
  }

  String toString() {
    return 'Source(id: $id, domain: $domain, name: $name)';
  }
}

class Favorite {
  int id;
  final int sourceId;
  int lastReadHistoryId;
  String name;
  final String address;
  String cover;
  int insertedChaptersCount;
  int latestChaptersCount;
  DateTime lastReadTime;
  DateTime insertedAt;
  DateTime updatedAt;

  static final String tableName = "favorites";

  Favorite({
    this.id,
    this.sourceId,
    this.lastReadHistoryId,
    this.name,
    this.address,
    this.cover,
    this.insertedChaptersCount = 0,
    this.latestChaptersCount = 0,
    this.lastReadTime,
    this.insertedAt,
    this.updatedAt,
  }) {
    if (lastReadTime == null) lastReadTime = DateTime.now();
    if (insertedAt == null) insertedAt = DateTime.now();
    if (updatedAt == null) updatedAt = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_id': sourceId,
      'last_read_history_id': lastReadHistoryId,
      'name': name,
      'address': address,
      'cover': cover,
      'inserted_chapters_count': insertedChaptersCount,
      'latest_chapters_count': latestChaptersCount,
      'last_read_time': lastReadTime.toString(),
      'inserted_at': insertedAt.toString(),
      'updated_at': updatedAt.toString(),
    };
  }

  Source source;

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'],
      sourceId: map['source_id'],
      lastReadHistoryId: map['last_read_history_id'],
      name: map['name'],
      address: map['address'],
      cover: map['cover'],
      insertedChaptersCount: map['inserted_chapters_count'],
      latestChaptersCount: map['latest_chapters_count'],
      lastReadTime: DateTime.parse(map['last_read_time']),
      insertedAt: DateTime.parse(map['inserted_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Comic toComic() {
    return Comic(name, address, cover);
  }

  String toString() {
    return 'Favorite(id: $id, sourceId: $sourceId, name: $name)';
  }
}

class History {
  final int id;
  final int sourceId;
  String title;
  String homeUrl;
  final String address;
  String cover;
  DateTime insertedAt;
  DateTime updateAt;

  History({
    this.id,
    this.sourceId,
    this.title,
    this.homeUrl,
    this.address,
    this.cover,
    this.insertedAt,
    this.updateAt,
  }) {
    if (insertedAt == null) insertedAt = DateTime.now();
    if (updateAt == null) updateAt = DateTime.now();
  }

  Source source;
  Map<String, String> headers = {};
  static final String tableName = "histories";

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_id': sourceId,
      'title': title,
      'home_url': homeUrl,
      'address': address,
      'cover': cover,
      'inserted_at': insertedAt.toString(),
      'updated_at': updateAt.toString(),
    };
  }

  factory History.fromMap(Map<String, dynamic> map) {
    return History(
      id: map['id'],
      sourceId: map['source_id'],
      title: map['title'],
      homeUrl: map['home_url'],
      address: map['address'],
      cover: map['cover'],
      insertedAt: DateTime.parse(map['inserted_at']),
    );
  }

  String toString() {
    return 'History(id: $id, sourceId: $sourceId, title: $title)';
  }

  Chapter asChapter() {
    return Chapter(title: title, url: address, which: 0, pageHeaders: {});
  }

  Comic asComic() {
    return Comic("", homeUrl, cover);
  }
}
