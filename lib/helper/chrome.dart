import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

void showChromeAll() => SystemChrome.setEnabledSystemUIOverlays(
      [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );

void hiddenChromeAll() => SystemChrome.setEnabledSystemUIOverlays([]);

void setNavigationBarColor(Color color) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      systemNavigationBarColor: color,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
}

void chromeInit(Color primaryColor) {
  setNavigationBarColor(primaryColor);
  showChromeAll();
}
