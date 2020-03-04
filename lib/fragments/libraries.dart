import 'package:flutter/material.dart';
import '../pages/detail.dart';
import '../pages/index.dart';
import 'bookshelf.dart' show platformList;
import '../ext.dart';

class LibrariesFragment extends StatelessWidget {
  final _platforms = platformList;

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
                    headers: p.buildBaseHeaders(),
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
