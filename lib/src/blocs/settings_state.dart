import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:package_info/package_info.dart';

abstract class SettingsState extends Equatable {}

class SettingsLoadedSate extends SettingsState {
  final PackageInfo packageInfo;
  final String startPage;
  final bool leftHand;
  final bool allowNsfw;
  final bool chaptersReversed;
  final double cachedImageSize;
  final int historiesTotal;
  final int favoritesTotal;

  @override
  List<Object> get props => [
        packageInfo,
        startPage,
        leftHand,
        allowNsfw,
        chaptersReversed,
        cachedImageSize,
        historiesTotal,
        favoritesTotal,
      ];

  SettingsLoadedSate({
    this.packageInfo,
    @required this.startPage,
    @required this.leftHand,
    @required this.allowNsfw,
    @required this.chaptersReversed,
    this.cachedImageSize = 0,
    this.historiesTotal = 0,
    this.favoritesTotal = 0,
  });

  SettingsLoadedSate copyWith({
    PackageInfo packageInfo,
    String startPage,
    bool leftHand,
    bool allowNsfw,
    bool chaptersReversed,
    double cachedImageSize,
    int historiesTotal,
    int favoritesTotal,
  }) {
    return SettingsLoadedSate(
      packageInfo: packageInfo ?? this.packageInfo,
      startPage: startPage ?? this.startPage,
      leftHand: leftHand ?? this.leftHand,
      allowNsfw: allowNsfw ?? this.allowNsfw,
      chaptersReversed: chaptersReversed ?? this.chaptersReversed,
      cachedImageSize: cachedImageSize ?? this.cachedImageSize,
      historiesTotal: historiesTotal ?? this.historiesTotal,
      favoritesTotal: favoritesTotal ?? this.favoritesTotal,
    );
  }
}
