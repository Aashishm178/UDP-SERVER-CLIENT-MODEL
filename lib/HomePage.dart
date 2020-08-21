import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'MessageList.dart';

// ignore: must_be_immutable
class HomePage extends StatefulWidget {
  String ipAddress;

  HomePage({@required this.ipAddress});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String dataToSend = '';
  Isolate isolate;
  ReceivePort receivePort;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  ScrollController scrollController = ScrollController();

  Future<void> start(BuildContext context) async {
    receivePort = ReceivePort();
    isolate = await Isolate.spawn(_handleIsolate, receivePort.sendPort);
    receivePort.listen((data) {
      Provider.of<MessageList>(context, listen: false)
          .addItem(Utf8Codec().decode(data).toString());
    });
  }

  void stop() {
    receivePort.close();
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }

  static void _handleIsolate(SendPort port) async {
    var socket = await RawDatagramSocket.bind('0.0.0.0', 11000);
    socket.listen((event) {
      print(event);
      if (event == RawSocketEvent.read) {
        var st = socket.receive();
        port.send(st.data);
      }
    });
  }

  void onClick(String data) async {
    if (data != null && data.trim() != '') {
      var socket = await RawDatagramSocket.bind('0.0.0.0', 0);
      socket.send(
          Utf8Codec().encode(data), InternetAddress(widget.ipAddress), 11000);
    } else {
      scaffoldKey.currentState.hideCurrentSnackBar();
      SnackBar snackBar = SnackBar(
        action: SnackBarAction(label: 'OK', onPressed: () {}),
        content: Text('Please enter message'),
        duration: Duration(seconds: 2),
      );
      scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await start(context);
  }

  @override
  void dispose() {
    super.dispose();
    stop();
  }

  @override
  Widget build(BuildContext context) {
    var messageList = Provider.of<MessageList>(context);
    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: Text('UDP'),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: messageList.getLength() >= 1
                  ? ListView.builder(
                      shrinkWrap: true,
                      controller: scrollController,
                      reverse: false,
                      itemCount: messageList.getLength(),
                      itemBuilder: (context, index) {
                        return Container(
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.lightBlue.withOpacity(0.1),
                                Colors.lightBlue.withOpacity(0.9)
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(20.0),
                              bottomLeft: Radius.circular(20.0),
                              bottomRight: Radius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            '${messageList.messages[index]}',
                            style:
                                TextStyle(color: Colors.black, fontSize: 14.0),
                          ),
                        );
                      })
                  : Container(),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      initialValue: '',
                      onChanged: (value) {
                        if (value != null) {
                          dataToSend = value;
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Send Message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(20.0),
                          ),
                          borderSide: BorderSide(
                            color: Colors.grey,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 10),
                    child: FlatButton(
                      color: Colors.blue,
                      onPressed: () {
                        onClick(dataToSend);
                      },
                      child: Text(
                        'Send',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
