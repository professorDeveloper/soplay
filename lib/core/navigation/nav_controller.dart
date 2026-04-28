import 'package:flutter/foundation.dart';

class NavController {
  final _index = ValueNotifier<int>(0);

  ValueListenable<int> get index => _index;

  void goTo(int tab) => _index.value = tab;
}
