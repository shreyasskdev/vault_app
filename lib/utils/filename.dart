import 'dart:io';

String filename(String name, String path, String format, bool space) {
  if (Platform.isWindows) {
    return _forWindows(name, path, format, space);
  } else {
    return _forOthers(name, path, format, space);
  }
}

String _forOthers(String name, String path, String format, bool space) {
  // get all from directory path
  var list = Directory(path).listSync();

  // make name list
  var nameList = list.map((e) => e.absolute.path.split("/").last).toList();

  // get file name
  var fileName = name.substring(0, name.lastIndexOf('.'));

  // get file type
  var fileType = name.substring(name.lastIndexOf('.'), name.length);

  // make val for loop
  var result = name;

  int i = 0;
  while (nameList.contains(result)) {
    i += 1;
    result =
        fileName + (space ? ' ' : '') + format.replaceAll('d', '$i') + fileType;
  }
  return result;
}

String _forWindows(String name, String path, String format, bool space) {
  // get all from directory path
  var list = Directory(path).listSync();

  // make name list and it is case-insensitive for windows file systems
  // so nameList shoud be compared by lower-case
  var nameList =
      list.map((e) => e.absolute.path.split("\\").last.toLowerCase()).toList();

  // get file name
  var fileName = name.substring(0, name.lastIndexOf('.'));

  // get file type
  var fileType = name.substring(name.lastIndexOf('.'), name.length);

  // make val for loop
  var result = name;

  int i = 0;
  while (nameList.contains(result.toLowerCase())) {
    i += 1;
    result =
        fileName + (space ? ' ' : '') + format.replaceAll('d', '$i') + fileType;
  }
  return result;
}
