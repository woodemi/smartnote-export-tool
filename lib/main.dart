import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(MyApp());

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

_toast(String msg) => _scaffoldKey.currentState
    .showSnackBar(SnackBar(content: Text(msg), duration: Duration(seconds: 2)));

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('36记导出'),
          actions: <Widget>[
            FlatButton(
              child: Text('导出'),
              onPressed: () async {
                var permissionHandler = PermissionHandler();
                var permissionStatus = await permissionHandler.checkPermissionStatus(PermissionGroup.storage);
                if (permissionStatus != PermissionStatus.granted) {
                  var map = await permissionHandler.requestPermissions([PermissionGroup.storage]);
                  if (map[PermissionGroup.storage] != PermissionStatus.granted) {
                    _toast("无法获取外部存储权限");
                    return;
                  }
                }

                exportAsync();
              },
            )
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return FutureBuilder(
      future: getApplicationDocumentsDirectory(),
      builder: (context, snapshot) {
        return !snapshot.hasData ? Container() : _buildFileList(snapshot.data);
      }
    );
  }

  Widget _buildFileList(Directory docDir) {
    var entities = docDir.parent.listSync();
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          for (var entity in entities)
            ListTile(
              title: Text(basename(entity.path)),
              subtitle: Text(entity.path),
            ),
        ],
      ),
    );
  }

  Future<void> exportAsync() async {
    print('exportAsync start');

    var srcDir = (await getApplicationDocumentsDirectory()).parent;
    var destDir = (await getExternalStorageDirectories(type: StorageDirectory.downloads)).first;
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }
    copyDirectory(srcDir, destDir);

    print('exportAsync end');
  }

  void copyDirectory(Directory src, Directory dest) {
    print('copyDirectory $src, $dest');
    for (var entity in src.listSync()) {
      if (entity is Directory) {
        var newDir = Directory(join(dest.absolute.path, basename(entity.path)));
        newDir.createSync();
        copyDirectory(entity.absolute, newDir);
      } else if (entity is File) {
        var name = basename(entity.path);
        if (name.endsWith('pts') || name.endsWith('realm') || entity.path.contains('thumbnail'))
          entity.copySync(join(dest.path, basename(entity.path)));
      }
    }
  }
}
