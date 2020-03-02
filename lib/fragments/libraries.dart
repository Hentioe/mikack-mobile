import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart' as mikack;
import 'package:mikack/models.dart';
import '../main.dart' show primaryColor;
import '../pages/detail.dart';
import '../pages/index.dart';

Map<String, String> buildHeaders(Platform platform) {
  return platform != null
      ? {
          'Referer':
              '${platform.isHttps ? 'https' : 'http'}://${platform.domain}'
        }
      : null;
}

class LibrariesFragment extends StatelessWidget {
  final _platforms = mikack.platforms();

  List<Widget> _buildPlatformList(BuildContext context) {
    return _platforms
        .map((p) => Card(
              margin: EdgeInsets.only(bottom: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadiusDirectional.all(Radius.circular(2))),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    p.favicon == null ? '' : p.favicon,
                    width: 30,
                    height: 30,
                    fit: BoxFit.fill,
                    headers: buildHeaders(p),
                    filterQuality: FilterQuality.none,
                  ),
                ),
                title: Text(p.name),
                trailing: OutlineButton(
                  textColor: Colors.blueAccent,
                  borderSide: BorderSide(color: Colors.blueAccent),
                  highlightedBorderColor: Colors.blueAccent,
                  child: Text('详细'),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => DetailPage(p))),
                ),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => IndexPage(p))),
              ),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20),
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.only(top: 15, bottom: 15),
            child: Text(
              '全部 (${_platforms.length})',
              style: TextStyle(color: Colors.black, fontSize: 15.0),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 10),
            child: Column(
              children: _buildPlatformList(context),
            ),
          ),
        ],
      ),
    );
  }
}
