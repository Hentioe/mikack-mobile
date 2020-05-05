import 'package:github_releases/github_models.dart';
import 'package:github_releases/github_releases.dart';
import 'package:package_info/package_info.dart';

import '../models.dart';
import '../values.dart';
import '../ext.dart';

bool isNewestVersion(PackageInfo packageInfo, String tagName) {
  return packageInfo.tagized() != tagName;
}

Future<List<Release>> checkUpdates(PackageInfo packageInfo) async {
  var releases = await getReleases(vRepoOwner, vRepoName);
  if (releases == null || releases.isEmpty) return null;
  if (isNewestVersion(packageInfo, releases.first.tagName)) {
    // 发现新版
    var updates = [releases.first];
    var currentVersionNumber =
        AppVersion.fromTagName(packageInfo.tagized()).toNumber();
    for (var release in releases.skip(1)) {
      var version = AppVersion.fromTagName(release.tagName);
      if (currentVersionNumber >= version.toNumber()) break;
      updates.add(release);
    }
    return updates;
  }
  return null;
}
