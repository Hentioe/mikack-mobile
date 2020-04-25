import 'package:github_releases/github_models.dart';
import 'package:github_releases/github_releases.dart';
import 'package:package_info/package_info.dart';
import 'package:equatable/equatable.dart';

import '../values.dart';
import '../ext.dart';

bool isNewestVersion(PackageInfo packageInfo, String tagName) {
  return packageInfo.tagized() != tagName;
}

class _AppVersion extends Equatable {
  final int major;
  final int minor;
  final int revision;
  final int build;

  static RegExp regExp = new RegExp(r'v(\d+)\.(\d+)\.(\d+)-(\d+)');

  _AppVersion({this.major, this.minor, this.revision, this.build});

  factory _AppVersion.fromTagName(String tagName) {
    var match = regExp.firstMatch(tagName);
    var major = int.parse(match.group(1));
    var minor = int.parse(match.group(2));
    var revision = int.parse(match.group(3));
    var build = int.parse(match.group(4));

    return _AppVersion(
      major: major,
      minor: minor,
      revision: revision,
      build: build,
    );
  }

  @override
  String toString() {
    return '$major.$minor.$revision-$build';
  }

  String tagized() {
    return 'v${toString()}';
  }

  int toNumber() {
    return int.parse('$major$minor$revision$build');
  }

  @override
  List<Object> get props => [major, minor, revision, build];
}

Future<List<Release>> checkUpdates(PackageInfo packageInfo) async {
  var releases = await getReleases(vRepoOwner, vRepoName);
  if (releases == null || releases.isEmpty) return null;
  if (isNewestVersion(packageInfo, releases.first.tagName)) {
    // 发现新版
    var updates = [releases.first];
    var currentVersionNumber =
        _AppVersion.fromTagName(packageInfo.tagized()).toNumber();
    for (var release in releases.skip(1)) {
      var version = _AppVersion.fromTagName(release.tagName);
      if (currentVersionNumber >= version.toNumber()) break;
      updates.add(release);
    }
    return updates;
  }
  return null;
}
