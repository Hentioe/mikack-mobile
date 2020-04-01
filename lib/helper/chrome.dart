import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

void showSystemUI() => SystemChrome.setEnabledSystemUIOverlays(
      [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

void hiddenSystemUI() => SystemChrome.setEnabledSystemUIOverlays([]);

void setNavigationBarColor(Color color) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: color,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

void setSystemUI({MaterialColor primarySwatch}) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: primarySwatch[900],
      systemNavigationBarColor: primarySwatch,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  showSystemUI();
}
