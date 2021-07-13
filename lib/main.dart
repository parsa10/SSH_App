import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:ssh/ssh.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _result = '';
  List _array;
  String host, user, pass, port, command, shell;

  Future<void> onClickCmd() async {
    var client = new SSHClient(
      host: host,
      port: int.parse(port),
      username: user,
      passwordOrKey: pass,
    );

    String result;
    try {
      result = await client.connect();
      if (result == "session_connected") result = await client.execute(command);
      client.disconnect();
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }

    setState(() {
      _result = result;
      _array = null;
    });
  }

  Future<void> onClickShell() async {
    var client = new SSHClient(
      host: host,
      port: int.parse(port),
      username: user,
      passwordOrKey: pass,
    );

    setState(() {
      _result = "";
      _array = null;
    });

    try {
      String result = await client.connect();
      if (result == "session_connected") {
        result = await client.startShell(
            ptyType: "xterm",
            callback: (dynamic res) {
              setState(() {
                _result += res;
              });
            });

        if (result == "shell_started") {
          print(await client.writeToShell(shell + "\n"));
          new Future.delayed(
            const Duration(seconds: 3000),
            () async => await client.closeShell(),
          );
        }
      }
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }
  }

  Future<void> onClickSFTP() async {
    var client = new SSHClient(
      host: host,
      port: int.parse(port),
      username: user,
      passwordOrKey: pass,
    );

    try {
      String result = await client.connect();
      if (result == "session_connected") {
        result = await client.connectSFTP();
        if (result == "sftp_connected") {
          var array = await client.sftpLs();
          setState(() {
            _result = result;
            _array = array;
          });

          print(await client.sftpMkdir("testsftp"));
          print(await client.sftpRename(
            oldPath: "testsftp",
            newPath: "testsftprename",
          ));
          print(await client.sftpRmdir("testsftprename"));

          Directory tempDir = await getTemporaryDirectory();
          String tempPath = tempDir.path;
          var filePath = await client.sftpDownload(
            path: "testupload",
            toPath: tempPath,
            callback: (progress) async {
              print(progress);
              // if (progress == 20) await client.sftpCancelDownload();
            },
          );

          print(await client.sftpRm("testupload"));

          print(await client.sftpUpload(
            path: filePath,
            toPath: ".",
            callback: (progress) async {
              print(progress);
              // if (progress == 30) await client.sftpCancelUpload();
            },
          ));

          print(await client.disconnectSFTP());

          client.disconnect();
        }
      }
    } on PlatformException catch (e) {
      print('Error: ${e.code}\nError Message: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget renderButtons() {
      return ButtonTheme(
        padding: EdgeInsets.all(5.0),
        child: ButtonBar(
          children: <Widget>[
            FlatButton(
              child: Text(
                'Command',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: onClickCmd,
              color: Colors.blue,
            ),
            FlatButton(
              child: Text(
                'Shell',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: onClickShell,
              color: Colors.blue,
            ),
            FlatButton(
              child: Text(
                'SFTP',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: onClickSFTP,
              color: Colors.blue,
            ),
          ],
        ),
      );
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('369'),
        ),
        body: ListView(
          shrinkWrap: true,
          padding: EdgeInsets.all(15.0),
          children: <Widget>[
            Text(
              "SSHeykh Info :",
              style: TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            TextFormField(
              initialValue: "192.168.16.9",
              onChanged: (text) {
                host = text;
              },
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: 'Enter HostName'),
            ),
            TextFormField(
              initialValue: "root",
              onChanged: (text) {
                user = text;
              },
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: 'Enter UserName'),
            ),
            TextFormField(
              initialValue: "22",
              onChanged: (text) {
                port = text;
              },
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: 'Enter Port'),
            ),
            TextFormField(
              obscureText: true,
              initialValue: "AdasPolo22",
              onChanged: (text) {
                pass = text;
              },
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: 'Enter Password'),
            ),
            TextFormField(
              initialValue: "ps",
              onChanged: (text) {
                command = text;
              },
              decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Enter SSH Command'),
            ),
            TextFormField(
              initialValue: "ls",
              onChanged: (text) {
                shell = text;
              },
              decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Write To Shell'),
            ),
            renderButtons(),
            Text(_result),
            _array != null && _array.length > 0
                ? Column(
                    children: _array.map((f) {
                      return Text(
                          "${f["filename"]} ${f["isDirectory"]} ${f["modificationDate"]} ${f["lastAccess"]} ${f["fileSize"]} ${f["ownerUserID"]} ${f["ownerGroupID"]} ${f["permissions"]} ${f["flags"]}");
                    }).toList(),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }
}
