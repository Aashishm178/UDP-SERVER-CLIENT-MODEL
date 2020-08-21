import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:udp/IpAddress.dart';
import 'package:udp/MessageList.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: MessageList(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: IpAddress(),
      ),
    );
  }
}
