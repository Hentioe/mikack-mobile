import 'package:equatable/equatable.dart';

class AppVersion extends Equatable {
  final int major;
  final int minor;
  final int revision;
  final int build;

  static RegExp regExp = new RegExp(r'v(\d+)\.(\d+)\.(\d+)-(\d+)');

  AppVersion({this.major, this.minor, this.revision, this.build});

  factory AppVersion.fromTagName(String tagName) {
    var match = regExp.firstMatch(tagName);
    var major = int.parse(match.group(1));
    var minor = int.parse(match.group(2));
    var revision = int.parse(match.group(3));
    var build = int.parse(match.group(4));

    return AppVersion(
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
