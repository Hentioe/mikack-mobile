import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:package_info/package_info.dart';

import '../models.dart';

abstract class SettingsState extends Equatable {}

class SettingsLoadedSate extends SettingsState {
  final PackageInfo packageInfo;
  final StartPageItem startPage;
  final bool allowNsfw;
  final bool chaptersReversed;
  final ReadingModeItem readingMode;
  final bool leftHand;
  final double cachedImageSize;
  final int historiesTotal;
  final int favoritesTotal;

  @override
  List<Object> get props => [
        packageInfo,
        startPage,
        allowNsfw,
        chaptersReversed,
        readingMode,
        leftHand,
        cachedImageSize,
        historiesTotal,
        favoritesTotal,
      ];

  SettingsLoadedSate({
    this.packageInfo,
    @required this.startPage,
    @required this.allowNsfw,
    @required this.chaptersReversed,
    @required this.readingMode,
    @required this.leftHand,
    this.cachedImageSize = 0,
    this.historiesTotal = 0,
    this.favoritesTotal = 0,
  });

  SettingsLoadedSate copyWith({
    PackageInfo packageInfo,
    StartPageItem startPage,
    bool allowNsfw,
    bool chaptersReversed,
    ReadingModeItem readingMode,
    bool leftHand,
    double cachedImageSize,
    int historiesTotal,
    int favoritesTotal,
  }) {
    return SettingsLoadedSate(
      packageInfo: packageInfo ?? this.packageInfo,
      startPage: startPage ?? this.startPage,
      allowNsfw: allowNsfw ?? this.allowNsfw,
      chaptersReversed: chaptersReversed ?? this.chaptersReversed,
      readingMode: readingMode ?? this.readingMode,
      leftHand: leftHand ?? this.leftHand,
      cachedImageSize: cachedImageSize ?? this.cachedImageSize,
      historiesTotal: historiesTotal ?? this.historiesTotal,
      favoritesTotal: favoritesTotal ?? this.favoritesTotal,
    );
  }
}
