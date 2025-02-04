import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final SettingsModelProvider = ChangeNotifierProvider<SettingsModel>((ref) {
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

final ImageCacheProvider = ChangeNotifierProvider<ImageCache>((ref) {
  return ImageCache();
});
