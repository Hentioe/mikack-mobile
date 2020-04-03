import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showSystemUI() => SystemChrome.setEnabledSystemUIOverlays(
      [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

void hiddenSystemUI() => SystemChrome.setEnabledSystemUIOverlays([]);

void restoreStatusBarColor() => scheduleMicrotask(() {
      SystemChannels.platform.invokeMethod<void>(
        'SystemChrome.setSystemUIOverlayStyle',
        {'statusBarColor': Colors.transparent.withAlpha(64).value},
      );
    });
