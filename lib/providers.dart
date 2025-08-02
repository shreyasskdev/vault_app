import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel extends ChangeNotifier {
  // private vars with default values
  bool _darkMode = true;
  bool _theftProtection = false;
  bool _advancedTextures = false;

  // Getter for private variables
  bool get darkmode => _darkMode;
  bool get theftProtection => _theftProtection;
  bool get advancedTextures => _advancedTextures;

  // Constructor that triggers loading the settings
  SettingsModel() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Loads stored data
    _darkMode = prefs.getBool('darkMode') ?? true;
    _theftProtection = prefs.getBool('theftProtection') ?? true;
    _advancedTextures = prefs.getBool('advancedTextures') ?? false;

    notifyListeners();
  }

  Future<void> toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = !_darkMode;
    await prefs.setBool('darkMode', _darkMode);
    notifyListeners();
  }

  Future<void> toggleTheftProtection() async {
    final prefs = await SharedPreferences.getInstance();
    _theftProtection = !_theftProtection;
    await prefs.setBool('theftProtection', _theftProtection);
    notifyListeners();
  }

  Future<void> toggleAdvancedTextures() async {
    final prefs = await SharedPreferences.getInstance();
    _advancedTextures = !_advancedTextures;
    await prefs.setBool('advancedTextures', _advancedTextures);
    notifyListeners();
  }
}

final settingsModelProvider = ChangeNotifierProvider<SettingsModel>((ref) {
  return SettingsModel();
});

//////////////////////////////////////////////////////////

class ImageCache extends ChangeNotifier {
  final Map<String, Uint8List> _cachedImages = {};
  final Map<String, Uint8List> _cachedThumbImages = {};
  final int _maxCacheSize = 50;

  // Uint8List? getImage(String imageId) => _cachedImages[imageId];
  Map<String, Uint8List> get cachedImage => _cachedImages;
  Map<String, Uint8List> get cachedThumbImage => _cachedThumbImages;

  void addImage(String imageId, Uint8List decryptedBytes) {
    if (_cachedImages.length >= _maxCacheSize) {
      // Remove the oldest entry (LRU logic can be added if needed)
      _cachedImages.remove(_cachedImages.keys.first);
    }
    _cachedImages[imageId] = decryptedBytes;
    // notifyListeners(); // Optional: Only if UI needs immediate update
  }

  void addThumbImage(String imageId, Uint8List decryptedBytes) {
    if (_cachedImages.length >= _maxCacheSize) {
      _cachedThumbImages.remove(_cachedThumbImages.keys.first);
    }
    _cachedThumbImages[imageId] = decryptedBytes;
  }
}

final imageCacheProvider = ChangeNotifierProvider<ImageCache>((ref) {
  return ImageCache();
});

///////////////////////////////////////////////////////////////////////////////////////

final isolatePoolProvider = FutureProvider<IsolatePool>((ref) async {
  final pool = IsolatePool(Platform.numberOfProcessors - 1);
  await pool.start();
  ref.onDispose(() => pool.stop());
  return pool;
});
