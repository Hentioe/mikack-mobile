import 'package:flutter/material.dart';

import '../helper/chrome.dart';

// 注意：修改此变量请同步修改 styles.xml
const primaryColor = Colors.deepOrange; // 0xFFFF5722

abstract class BasePage extends StatelessWidget {
  void initSystemUI() => chromeInit(primaryColor);
}
