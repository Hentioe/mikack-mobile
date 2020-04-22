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
  final bool leftHandMode;
  final int preLoading;
  final bool preCaching;
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
        leftHandMode,
        preLoading,
        preCaching,
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
    @required this.leftHandMode,
    @required this.preLoading,
    @required this.preCaching,
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
    bool leftHandMode,
    int preLoading,
    bool preCaching,
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
      leftHandMode: leftHandMode ?? this.leftHandMode,
      preLoading: preLoading ?? this.preLoading,
      preCaching: preCaching ?? this.preCaching,
      cachedImageSize: cachedImageSize ?? this.cachedImageSize,
      historiesTotal: historiesTotal ?? this.historiesTotal,
      favoritesTotal: favoritesTotal ?? this.favoritesTotal,
    );
  }
}
