import 'store.dart';

void testStore() async {
  if (const bool.fromEnvironment("dart.vm.product")) return;
  await dangerouslyDestroy();
  await insertSource(Source(domain: 'www.google.com', name: '谷歌'));
  var sources = await findSources();
  print(sources);
  var source = sources[0];
  source.name = 'Google';
  updateSource(source);
  var sources2 = await findSources();
  print(sources2);
  await insertFavorite(Favorite(
    sourceId: source.id,
    name: '风云',
    address: '风云漫画地址',
    cover: '风云漫画封面',
    lastReadTime: DateTime.parse("2012-02-27 13:27:00"),
  ));
  await insertHistory(History(
    sourceId: source.id,
    title: '风云第一话',
    address: '风云第一话地址',
    cover: '风云漫画封面',
  ));
  var histories = await findHistories();
  print(histories);
  await insertFavorite(Favorite(
    sourceId: source.id,
    name: '大头儿子',
    address: '大头儿子漫画地址',
    cover: '大头儿子漫画封面',
  ));
  var favorites = await findFavorites();
  var favorite = favorites[0];
  print(favorite);

  print(await getSource(domain: 'www.google.com'));
}
