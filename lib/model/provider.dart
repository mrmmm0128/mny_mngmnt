import 'package:flutter/material.dart';

class ChildNotifier extends ChangeNotifier {
  String _selectedChild = "";
  String get selectedChild => _selectedChild;
  void setSelectedChild(String child) {
    _selectedChild = child;
    notifyListeners();
  }
}
