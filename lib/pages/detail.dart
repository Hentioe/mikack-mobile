import 'package:flutter/material.dart';
import 'package:mikack/models.dart' as models;
import '../widgets/tag.dart';
import '../fragments/libraries.dart' show buildHeaders;

class FeatureStatus extends StatelessWidget {
  FeatureStatus(this.name, this.description, this.isSupport);

  final String name;
  final String description;
  final bool isSupport;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        child: Container(
          padding: EdgeInsets.all(10),
          width: 90,
          child: Column(
            children: [
              Icon(isSupport ? Icons.check : Icons.close,
                  size: 25, color: isSupport ? Colors.green : Colors.red),
              SizedBox(height: 10),
              Text(name,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        onTap: () {},
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  DetailPage(this.platform);

  final models.Platform platform;

  Widget _buildBody() {
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.only(top: 10),
              child: Column(
                children: [
                  // 图标+元数据
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 平台图标
                      Image.network(
                        platform.favicon == null ? '' : platform.favicon,
                        fit: BoxFit.fill,
                        width: 60,
                        height: 60,
                        headers: buildHeaders(platform),
                        filterQuality: FilterQuality.none,
                      ),
                      // 平台元数据
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(platform.name,
                              style:
                                  TextStyle(color: Colors.black, fontSize: 16)),
                          SizedBox(height: 2),
                          Text(platform.domain,
                              style:
                                  TextStyle(color: Colors.black, fontSize: 13)),
                          SizedBox(height: 10),
                          Wrap(
                            spacing: 5,
                            alignment: WrapAlignment.center,
                            children: [Tag('中文'), Tag('NSFW')],
                          )
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // 状态信息
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FeatureStatus('基础可用', '可浏览资源图片', platform.isUsable),
                      FeatureStatus(
                          '分页支持', '可连续不断的加载资源列表', platform.isPageable),
                      FeatureStatus('搜索支持', '可搜索站内资源', platform.isSearchable),
                      FeatureStatus(
                          '传输安全', '使用 HTTPS 与上游通信', platform.isSearchable),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.keyboard_backspace),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('平台信息'),
      ),
      body: _buildBody(),
    );
  }
}
