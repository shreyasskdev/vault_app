import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vault/pages/password.dart';
import 'package:vault/src/rust/api/file.dart' as file_api;
import 'package:vault/src/rust/api/encryption.dart' as encryption_api;
import 'package:vault/src/rust/frb_generated.dart';

mixin FileApiWrapper {
  Future<void> createDirWrapper(path, albumname) async {
    try {
      await file_api.createDir(dir: path, albumName: albumname);
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

  Future<Map<String, (String, double)>> getImagesWrapper(path) async {
    try {
      return await file_api.getImages(dir: path);
    } catch (e) {
      debugPrint("Vault error: WARN: $e");
      return {};
    }
  }

  Future<Map<String, (String, double)>?> getAlbumThumbWrapper(dir) async {
    try {
      print(dir);
      return await file_api.getAlbumThumb(dir: dir);
    } catch (e) {
      debugPrint("Vault error: WARN: $e");
      return {};
    }
  }

  Future<Uint8List> getFileWrapper(String path) async {
    return await compute(_isolateGetFile, path);
  }

  Future<Uint8List> getFileThumbWrapper(String path) async {
    return await compute(_isolateGetFileThumb, path);
  }

  Future<void> saveFileWrapper(data, path) async {
    return await file_api
        .saveFile(
          imageData: data,
          dir: path,
        )
        .catchError((e) => debugPrint("Vault error: WARN: $e"));
  }

  Future<bool> setCrytoParamsWrapper(password) async {
    return await encryption_api
        .setCryptoParams(password: password)
        .then((value) => value)
        .catchError((e) {
      debugPrint("Vault error: WARN: $e");
      return false;
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
  print(" YOOOO >>>>> " + path);

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
