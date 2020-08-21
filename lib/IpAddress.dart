import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:udp/HomePage.dart';

class IpAddress extends StatefulWidget {
  @override
  _IpAddressState createState() => _IpAddressState();
}

class _IpAddressState extends State<IpAddress> {
  String ipAddress;
  String connectionIp;
  Isolate isolate;
  ReceivePort receivePort;
  bool connectionRequested = false;
  var scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> start() async {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn(_handleIsolate, receivePort.sendPort);
    receivePort.listen((data) {
      Datagram dg = data;
      if (Utf8Codec().decode(dg.data) == 'request') {
        print('request');
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Connection Requested'),
                content: Text(
                    '${dg.address.address} has requested to connect with you'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () async {
                      print('hello');
                      var socket = await RawDatagramSocket.bind('0.0.0.0', 0);
                      socket.send(Utf8Codec().encode('ack'), dg.address, 15000);
                      socket.close();
                      print(dg.address);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HomePage(
                            ipAddress: dg.address.address,
                          ),
                        ),
                      );
                    },
                    child: Text('Allow'),
                  ),
                  FlatButton(
                    onPressed: () async {
                      var socket = await RawDatagramSocket.bind('0.0.0.0', 0);
                      socket.send(
                          Utf8Codec().encode('nack'), dg.address, 15000);
                      socket.close();
                      Navigator.of(context).pop();
                    },
                    child: Text('Disallow'),
                  ),
                ],
              );
            });
      }
      if (Utf8Codec().decode(dg.data) == 'ack') {
        print('ack');
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Connection established'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => HomePage(
                            ipAddress: dg.address.address,
                          ),
                        ),
                      );
                    },
                    child: Text('Start conversation'),
                  ),
                ],
              );
            });
      }
      if (Utf8Codec().decode(dg.data) == 'nack') {
        print('nack');
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Connection disallowed'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Ok'),
                  ),
                ],
              );
            });
      }
    });
  }

  void stop() async {
    receivePort.close();
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }

  static void _handleIsolate(SendPort sendPort) async {
    print('isolate');
    var socket = await RawDatagramSocket.bind('0.0.0.0', 15000);
    socket.listen((event) {
      print('event');
      if (event == RawSocketEvent.read) {
        print('read');
        var st = socket.receive();
        print('data');
        sendPort.send(st);
      }
    });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await start();
  }

  @override
  void dispose() {
    super.dispose();
    stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text('Ip Address'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.add_comment),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return connectionRequested
                          ? CircularProgressIndicator()
                          : AlertDialog(
                              title: Text('Enter Ip Address'),
                              content: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: TextFormField(
                                      onChanged: (value) {
                                        connectionIp = value;
                                      },
                                    ),
                                  )
                                ],
                              ),
                              actions: <Widget>[
                                FlatButton(
                                  onPressed: () async {
                                    print('send');
                                    var socket = await RawDatagramSocket.bind(
                                        '0.0.0.0', 0);
                                    socket.send(Utf8Codec().encode('request'),
                                        InternetAddress(connectionIp), 15000);
                                    socket.close();
                                    print('sended');
                                  },
                                  child: Text('Connect'),
                                ),
                                FlatButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'))
                              ],
                            );
                    });
              })
        ],
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20.0),
              child: TextFormField(
                onFieldSubmitted: (String value) {
                  if (value != null &&
                      value.trim() != '' &&
                      value.contains(
                          '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          ipAddress: value.trim(),
                        ),
                      ),
                    );
                  } else {
                    scaffoldKey.currentState.hideCurrentSnackBar();
                    SnackBar snackBar = SnackBar(
                      content: Text(
                        'Enter correct ip Address',
                        style: TextStyle(color: Colors.blue),
                      ),
                      action: SnackBarAction(label: 'ok', onPressed: () {}),
                    );
                    scaffoldKey.currentState.showSnackBar(snackBar);
                  }
                },
                initialValue: '',
                onChanged: (String value) {
                  ipAddress = value;
                },
                decoration: InputDecoration(
                  labelText: 'Enter IP Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(20.0),
                    ),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20.0),
              child: FlatButton(
                color: Colors.blue,
                onPressed: () {
                  if (ipAddress != null &&
                      ipAddress.trim() != '' &&
                      ipAddress.contains(
                          '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?).(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HomePage(
                          ipAddress: ipAddress.trim(),
                        ),
                      ),
                    );
                  } else {
                    FocusScope.of(context).requestFocus(FocusNode());
                    scaffoldKey.currentState.hideCurrentSnackBar();
                    SnackBar snackBar = SnackBar(
                      content: Text(
                        'Enter correct ip Address',
                        style: TextStyle(color: Colors.blue),
                      ),
                      action: SnackBarAction(label: 'ok', onPressed: () {}),
                    );
                    scaffoldKey.currentState.showSnackBar(snackBar);
                  }
                },
                child: Text(
                  'Ok',
                  style: TextStyle(color: Colors.white, fontSize: 15.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
