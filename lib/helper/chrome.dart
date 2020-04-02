import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:mikack_mobile/pages/base_page.dart' show primarySwatch;

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

void setSystemUI({
  MaterialColor primarySwatch = primarySwatch,
  brightness: Brightness.light,
}) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: primarySwatch,
      systemNavigationBarIconBrightness: brightness,
    ),
  );
  showSystemUI();
}
