import 'package:flutter/foundation.dart';

class SettingsModel extends ChangeNotifier {
  bool _darkMode = true;
  bool _TheftProtection = true;

  bool get darkmode => _darkMode;
  bool get TheftProtection => _TheftProtection;

  void toggleDarkmode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  void toggleTheftProtection() {
    _TheftProtection = !_TheftProtection;
    notifyListeners();
  }
}
