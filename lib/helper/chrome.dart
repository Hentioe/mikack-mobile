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

void setSystemUI({Color primaryColor}) {
  setNavigationBarColor(primaryColor);
  showSystemUI();
}
