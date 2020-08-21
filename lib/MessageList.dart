import 'package:flutter/cupertino.dart';

class MessageList with ChangeNotifier {
  List<String> messages = [];

  List<String> get() => messages;

  void addItem(String data) {
    if (data != null && data.trim() != '') {
      messages.add(data);
      notifyListeners();
    }
  }

  int getLength() {
    if (messages.length >= 1) {
      return messages.length;
    } else {
      return 0;
    }
  }
}
