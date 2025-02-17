import 'package:flutter/material.dart';

class ChildNotifier extends ChangeNotifier {
  String _selectedChild = "";
  String get selectedChild => _selectedChild;
  void setSelectedChild(String child) {
    _selectedChild = child;
    notifyListeners();
  }
}

class ColorNotifier extends ChangeNotifier {
  Color _gradientEndColor = const Color(0xFFFF9800);
  bool _gradation = true;
  Color get gradientEndColor => _gradientEndColor;
  bool get gradation => _gradation;
  void setEndColor(Color newcolor) {
    _gradientEndColor = newcolor;
    notifyListeners();
  }

  void setGradation(bool newbool) {
    _gradation = newbool;
    notifyListeners();
  }
}
