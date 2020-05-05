import 'package:bloc/bloc.dart';
import 'package:github_releases/github_releases.dart';
import 'package:package_info/package_info.dart';

import 'changelog_event.dart';
import 'changelog_state.dart';
import '../models.dart';
import '../values.dart';
import '../ext.dart';

class ChangelogBloc extends Bloc<ChangelogEvent, ChangelogState> {
  @override
  ChangelogState get initialState => ChangelogLoadedState(
        changelog: const [],
      );

  @override
  Stream<ChangelogState> mapEventToState(ChangelogEvent event) async* {
    switch (event.runtimeType) {
      case ChangelogRequestEvent: // 请求更新日志
        var packageInfo = await PackageInfo.fromPlatform();
        var currentVersion = AppVersion.fromTagName(packageInfo.tagized());
        var currentVersionNumber = currentVersion.toNumber();
        yield (state as ChangelogLoadedState).copyWith(
          error: noneError,
          loading: true,
          currentVersion: currentVersion.tagized(),
        );

        getReleases(vRepoOwner, vRepoName).then((releases) {
          var changelog = releases.map((r) {
            var version = AppVersion.fromTagName(r.tagName);
            return Change(
              release: r,
              isNewVersion: version.toNumber() > currentVersionNumber,
            );
          }).toList();
          add(ChangelogLoadedEvent(changelog: changelog));
        }).catchError((e) {
          add(ChangelogErrorOccurred(message: e.toString()));
        });
        break;
      case ChangelogLoadedEvent: // 装载更新内容
        var castedEvent = event as ChangelogLoadedEvent;
        yield (state as ChangelogLoadedState)
            .copyWith(loading: false, changelog: castedEvent.changelog);
        break;

      case ChangelogErrorOccurred: // 发生错误
        var castedEvent = event as ChangelogErrorOccurred;
        yield (state as ChangelogLoadedState)
            .copyWith(error: ErrorWrapper.message(castedEvent.message));
        break;
    }
  }

  @override
  void onError(Object error, StackTrace stacktrace) {
    print(error);
    print(stacktrace);
    super.onError(error, stacktrace);
  }
}
