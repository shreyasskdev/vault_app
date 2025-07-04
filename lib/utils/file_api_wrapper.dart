import 'package:flutter/foundation.dart';
import 'package:vault/providers.dart';
import 'package:vault/src/rust/api/file.dart' as file_api;
import 'package:vault/src/rust/frb_generated.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin FileApiWrapper {
  Future<void> createDirWrapper(path, albumname) async {
    try {
      await file_api.createDir(dir: path, albumName: albumname);
    } catch (e) {
      debugPrint('Vault error: WARN: $e');
    }
  }

  Future<void> deleteDirWrapper(dir) async {
    try {
      await file_api.deleteDir(dir: dir);
    } catch (e) {
      debugPrint('Vault error: WARN: $e');
    }
  }

  Future<List<String>> getDirsWrapper(path) async {
    try {
      return file_api.getDirs(dir: path);
    } catch (e) {
      debugPrint('Vault error: WARN: $e');
      return Future(List.empty);
    }
  }

  Future<Map<String, (String, double)>> getImagesWrapper(String path) async {
    try {
      return await file_api.getImages(dir: path);
    } catch (e) {
      debugPrint("Vault error: WARN: $e");
      return {};
    }
  }

  Future<Map<String, (String, double)>?> getAlbumThumbWrapper(
      String dir) async {
    try {
      return await file_api.getAlbumThumb(dir: dir);
    } catch (e) {
      debugPrint("Vault error: WARN: $e");
      return {};
    }
  }

  Future<Uint8List> getFileWrapper(String path, WidgetRef ref) async {
    final imageCache = ref.read(ImageCacheProvider);
    final cachedImage = imageCache.cachedImage[path];

    if (cachedImage != null) {
      return cachedImage;
    }

    final data = await compute(_isolateGetFile, path);
    imageCache.addImage(path, data);
    return data;
  }

  Future<Uint8List> getFileThumbWrapper(String path, WidgetRef ref) async {
    final imageCache = ref.read(ImageCacheProvider);
    final cachedImage = imageCache.cachedThumbImage[path];

    if (cachedImage != null) {
      return cachedImage;
    }
    final data = await compute(_isolateGetFileThumb, path);
    imageCache.addThumbImage(path, data);
    return data;
  }

  Future<void> saveImageWrapper(data, path) async {
    return await file_api
        .saveImage(
          imageData: data,
          dir: path,
        )
        .catchError((e) => debugPrint("Vault error: WARN: $e"));
  }

  Future<void> deleteFileWrapper(path) async {
    return await file_api
        .deleteFile(path: path)
        .catchError((e) => debugPrint("Vault error: WARN: $e"));
  }

  Future<bool> setPasswordWrapper(password, dir) async {
    return await file_api
        .setPassword(password: password, dir: dir)
        .then((value) => value)
        .catchError((e) {
      debugPrint("Vault error: WARN: $e");
      return false;
    });
  }

  Future<void> savePasswordWrapper(password, dir) async {
    await file_api
        .savePassword(dir: dir, password: password)
        .then((value) => {value})
        .catchError((e) => {debugPrint("Vault error: WARN: $e")});
  }

  Future<bool> checkPasswordExistWrapper(dir) async {
    return await file_api
        .checkPasswordExist(dir: dir)
        .then((value) => value)
        .catchError((e) {
      debugPrint("Vault error: WARN: $e");
      return false;
    });
  }

  Future<void> zipBackupWrapper(rootDir, savePath, bool encryption) async {
    return await file_api
        .zipBackup(rootDir: rootDir, savePath: savePath, encryption: encryption)
        .catchError((e) => debugPrint("Vault error: WARN: $e"));
  }

  Future<void> restoreBackupWrapper(rootDir, zipPath, password) async {
    return await file_api
        .restoreBackup(rootDir: rootDir, zipPath: zipPath, password: password)
        .catchError((e) => debugPrint("Vault error: WARN: $e"));
  }

  Future<bool> checkZipEncryptedWrapper(zipPath) async {
    return await file_api.checkZipEncrypted(zipPath: zipPath).catchError((e) {
      debugPrint("Vault error: WARN: $e");
      throw e;
    });
  }

  Future<bool> checkZipPasswordWrapper(zipPath, password) async {
    return await file_api
        .checkZipPassword(zipPath: zipPath, password: password)
        .catchError((e) {
      debugPrint("Vault error: WARN: $e");
      throw e;
    });
  }

  List<Map<String, (String, double)>> sortMapToList(
      Map<String, (String, double)> inputMap) {
    // Convert the map entries to a list and sort by keys
    List<MapEntry<String, (String, double)>> sortedEntries =
        inputMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    // Convert each sorted entry to a Map and return as a List
    return sortedEntries.map((entry) => {entry.key: entry.value}).toList();
  }
}

Future<Uint8List> _isolateGetFile(String path) async {
  await RustLib.init();

  Uint8List value =
      await file_api.getFile(path: path).then((value) => value).catchError((e) {
    debugPrint(
        "Vault error: WARN: Encryption error (wrong password): ${e.toString()}");
    return Uint8List.fromList([]);
  });
  return value;
}

Future<Uint8List> _isolateGetFileThumb(String path) async {
  await RustLib.init();

  Uint8List value = await file_api
      .getFileThumb(path: path)
      .then((value) => value)
      .catchError((e) {
    debugPrint(
        "Vault error: WARN: Encryption error (wrong password): ${e.toString()}");
    return Uint8List.fromList([]);
  });
  return value;
}
