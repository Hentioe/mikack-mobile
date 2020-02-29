import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:mikack/src/models.dart' as models;

class FeatureStatus extends StatelessWidget {
  FeatureStatus(this.name, this.isSupport);

  final String name;
  final bool isSupport;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(isSupport ? Icons.check : Icons.close,
              size: 45, color: isSupport ? Colors.green : Colors.red),
          Text(name, style: TextStyle(fontSize: 18))
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  DetailPage(this.platform);

  final models.Platform platform;

  Widget _buildBody() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network('http://${platform.domain}/favicon.ico',
                    fit: BoxFit.fill, width: 60, height: 60),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(platform.name,
                      style: TextStyle(color: Colors.black, fontSize: 16)),
                  SizedBox(height: 2),
                  Text('域名：${platform.domain}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  SizedBox(height: 2),
                  Text(
                    '标签：中文、NSFW',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  )
                ],
              ),
            ],
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FeatureStatus('可阅读', true),
              FeatureStatus('可分页', false),
              FeatureStatus('可搜索', true),
            ],
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
