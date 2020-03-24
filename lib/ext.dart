import 'package:mikack/models.dart';
import 'package:mikack_mobile/widgets/comics_view.dart';
import 'store.dart';

extension PlatformExt on Platform {
  Future<Source> toSavedSource() async {
    var source = await getSource(domain: this.domain);
    if (source == null) {
      source = Source(domain: this.domain, name: this.name);
      await insertSource(source);
    }
    return source;
  }

  Map<String, String> buildBaseHeaders() {
    return {'Referer': '${this.isHttps ? 'https' : 'http'}://${this.domain}'};
  }
}

extension FavoritesExt on List<Favorite> {
  List<Comic> toComicList() {
    return this.map((f) => f.toComic()).toList();
  }
}

extension ComicsExt on List<Comic> {
  List<ComicViewItem> toViewItems() {
    return this.map((c) => c.toViewItem()).toList();
  }
}

extension ComicExt on Comic {
  ComicViewItem toViewItem({Platform platform, int badgeValue}) {
    return ComicViewItem(this, platfrom: platform, badgeValue: badgeValue);
  }
}
