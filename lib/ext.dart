import 'package:mikack/models.dart';
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

extension FavoritesToComics on List<Favorite> {
  List<Comic> toComicList() {
    return this.map((f) => f.toComic()).toList();
  }
}
