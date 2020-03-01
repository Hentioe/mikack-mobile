import 'package:flutter/material.dart';
import 'package:mikack/mikack.dart' as mikack;
import 'package:mikack_mobile/main.dart' show primaryColor;
import '../pages/detail.dart';
import '../pages/index.dart';

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
                leading: Image.network('http://${p.domain}/favicon.ico',
                    width: 30, height: 30, fit: BoxFit.fill),
                title: Text(p.name),
                trailing: MaterialButton(
                  elevation: 1.5,
                  color: primaryColor,
                  textColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadiusDirectional.all(Radius.circular(5))),
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
