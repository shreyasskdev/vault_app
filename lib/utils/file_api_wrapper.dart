import 'package:flutter/foundation.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
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

  // Future<Uint8List> getFileWrapper(String path, WidgetRef ref) async {
  //   final imageCache = ref.read(imageCacheProvider);
  //   final cachedImage = imageCache.cachedImage[path];

  //   if (cachedImage != null) {
  //     return cachedImage;
  //   }

  //   final data = await compute(_isolateGetFile, path);
  //   imageCache.addImage(path, data);
  //   return data;
  // }

  // Future<Uint8List> getFileThumbWrapper(String path, WidgetRef ref) async {
  //   final imageCache = ref.read(imageCacheProvider);
  //   final cachedImage = imageCache.cachedThumbImage[path];

  //   if (cachedImage != null) {
  //     return cachedImage;
  //   }
  //   final data = await compute(_isolateGetFileThumb, path);
  //   imageCache.addThumbImage(path, data);
  //   return data;
  // }

  Future<Uint8List> getFileWrapper(String path, WidgetRef ref) async {
    final imageCache = ref.read(imageCacheProvider);
    final cachedImage = imageCache.cachedImage[path];
    if (cachedImage != null) return cachedImage;

    final pool = await ref.read(isolatePoolProvider.future);
    final data = await pool.scheduleJob(GetFileJob(path));

    imageCache.addImage(path, data);
    return data;
  }

  Future<Uint8List> getFileThumbWrapper(String path, WidgetRef ref) async {
    final imageCache = ref.read(imageCacheProvider);
    final cachedImage = imageCache.cachedThumbImage[path];
    if (cachedImage != null) return cachedImage;

    final pool = await ref.read(isolatePoolProvider.future);
    final data = await pool.scheduleJob(GetFileThumbJob(path));

    imageCache.addThumbImage(path, data);
    return data;
  }

  Future<void> saveImageWrapper(data, path) async {
    return await file_api
        .saveMedia(
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

  Future<bool> isVideoWrapper(data) async {
    return await file_api.isVideo(imageData: data).catchError((e) {
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

// Future<Uint8List> _isolateGetFile(String path) async {
//   await RustLib.init();

//   Uint8List value =
//       await file_api.getFile(path: path).then((value) => value).catchError((e) {
//     debugPrint(
//         "Vault error: WARN: Encryption error (wrong password): ${e.toString()}");
//     return Uint8List.fromList([]);
//   });
//   return value;
// }

// Future<Uint8List> _isolateGetFileThumb(String path) async {
//   await RustLib.init();

//   Uint8List value = await file_api
//       .getFileThumb(path: path)
//       .then((value) => value)
//       .catchError((e) {
//     debugPrint(
//         "Vault error: WARN: Encryption error (wrong password): ${e.toString()}");
//     return Uint8List.fromList([]);
//   });
//   return value;
// }

////////////////////////////////////////////////////////////////////////////

@pragma('vm:isolate-local')
var _isRustInitialized = false;

// An abstract base class to handle our shared initialization logic.
abstract class BaseFileJob<T> extends PooledJob<T> {
  Future<void> initializeRust() async {
    if (!_isRustInitialized) {
      try {
        await RustLib.init();
        _isRustInitialized = true;
      } catch (e) {
        // If init fails, log it. The jobs will likely fail after this.
        debugPrint("FATAL: RustLib.init() failed in isolate: $e");
      }
    }
  }
}

class GetFileJob extends BaseFileJob<Uint8List> {
  final String path;
  GetFileJob(this.path);

  @override
  Future<Uint8List> job() async {
    await initializeRust();
    if (!_isRustInitialized) {
      return Uint8List(0);
    }

    try {
      final value = await file_api.getFile(path: path);
      return value;
    } catch (e) {
      debugPrint("Vault error (getFile job): ${e.toString()}");
      return Uint8List(0);
    }
  }
}

class GetFileThumbJob extends BaseFileJob<Uint8List> {
  final String path;
  GetFileThumbJob(this.path);

  @override
  Future<Uint8List> job() async {
    await initializeRust();
    if (!_isRustInitialized) {
      return Uint8List(0);
    }

    try {
      final value = await file_api.getFileThumb(path: path);
      return value;
    } catch (e) {
      debugPrint("Vault error (getFileThumb job): ${e.toString()}");
      return Uint8List(0);
    }
  }
}
