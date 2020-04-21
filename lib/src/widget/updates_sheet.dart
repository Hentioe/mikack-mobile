import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:github_releases/github_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:dio/dio.dart';
import 'package:flutter_install_apk/flutter_install_apk.dart';

import '../values.dart';

const _sizeUnit = 1024 * 1024;

class UpdatesSheet extends StatefulWidget {
  final Release release;

  UpdatesSheet({@required this.release});

  @override
  State<StatefulWidget> createState() => _UpdatesSheetState();
}

class _UpdatesSheetState extends State<UpdatesSheet> {
  ProgressDialog _pd;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  int _byteTotal;
  int _byteSize;
  double _progressValue;

  void _initProgressDialogWithShow() {
    _byteTotal = null;
    _byteSize = null;
    _progressValue = null;
    _pd = ProgressDialog(
      context,
      customBodyBuilder: () => Container(
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('更新中', style: TextStyle(fontSize: 18)),
            LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primarySwatch),
              backgroundColor: Colors.white,
              value: _progressValue,
            ),
            Text(
                _progressValue == null
                    ? '请稍等'
                    : '${((_byteSize ?? 0) / _sizeUnit).toStringAsFixed(2)}MB/${((_byteTotal ?? 0) / _sizeUnit).toStringAsFixed(2)}MB',
                style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
    _pd.show();
  }

  void _scheduleDownloadTask(String url) async {
    var tempDir = (await getExternalCacheDirectories()).first.path;
    var file = File('$tempDir/${widget.release.tagName}.apk');

    if (!await file.exists()) {
      _initProgressDialogWithShow();
      var dio = Dio();
      var progressCallback = (int count, int total) {
        if (!(_pd?.isShowing() ?? false))
          dio.close(force: true);
        else {
          _byteTotal = total;
          _byteSize = count;
          _progressValue = count / total;
          _pd?.update();
        }
      };
      var resp = await dio.request(
        url,
        onReceiveProgress: progressCallback,
        options: Options(responseType: ResponseType.bytes),
      );
      file.writeAsBytes(resp.data);
    }
    FlutterInstallApk.installApk(file.path).then((_) => _pd?.hide());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          SizedBox(height: 10),
          Text(
            '发现新版：${widget.release.tagName}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Markdown(data: widget.release.body),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: MaterialButton(
                  child: Text(
                    '安装新版本',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () {
                    if (widget.release.assets.isEmpty) {
                      Fluttertoast.showToast(msg: '没有找到更新附件，也许是作者忘上传了～');
                    } else {
                      _scheduleDownloadTask(
                          widget.release.assets.first.browserDownloadUrl);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
