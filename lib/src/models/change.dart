import 'package:github_releases/github_models.dart';
import 'package:meta/meta.dart';

class Change {
  final Release release;
  final bool isNewVersion;

  Change({@required this.release, @required this.isNewVersion});
}
