import 'dart:ui';
// import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
// import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:vault/utils/filename.dart';
import 'package:vault/widget/touchable.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class AlbumPage extends StatefulWidget {
  final String name;
  const AlbumPage({super.key, required this.name});

  @override
  State<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> with fileapi.FileApiWrapper {
  // List<File> files = [];
  List<Map<String, (String, double)>> files = [];
  String photoDirectoryPath = "";

  bool _isSelectionMode = false;
  Set<int> _selectedIndices = {};

  @override // stratup code
  void initState() {
    super.initState();
    getImages();
  }

  Future getImageFromGallery() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collections';

    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) {
      debugPrint("No image selected");
      return;
    }

    final bytes = await image.readAsBytes();
    await File(image.path).delete(); // Delete cached file
    final Uint8List uint8list = Uint8List.fromList(bytes);

    saveFileWrapper(uint8list, '$directory/${widget.name}');

    getImages();
  }

  void getImages() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    photoDirectoryPath = '${appDocDir.path}/Collections/${widget.name}';

    await getImagesWrapper(photoDirectoryPath).then((value) {
      setState(() {
        files = sortMapToList(value);
      });
    });
  }

  Future<Widget> chainedAsyncOperations(index) async {
    String imagePath = "$photoDirectoryPath/${files[index].keys.first}";
    final imageData = await (getFileThumbWrapper(imagePath));

    return Image.memory(
      gaplessPlayback: true,
      Uint8List.fromList(imageData),
      // cacheWidth: 200,
      // cacheHeight: ((size.height / size.width) * 200).toInt(),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint("Vault error: INFO: $error");
        return Container(
          color: const Color.fromARGB(255, 14, 14, 14),
          child: const Center(
            child: Text("Error"),
          ),
        );
      },
    );
  }

  void _toggleSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.add(index);
    });
    HapticFeedback.mediumImpact();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIndices.add(index);
      }
    });
    HapticFeedback.lightImpact();
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  Future<void> _deleteSelectedPhotos() async {
    // Sort indices in descending order to avoid index shifting
    final sortedIndices = _selectedIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      if (index < files.length) {
        final fileName = files[index].keys.first;
        final filePath = "$photoDirectoryPath/$fileName";
        // await deleteFileWrapper(filePath);
        print(filePath);
      }
    }

    _exitSelectionMode();
    getImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : TouchableOpacity(
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 25,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: _isSelectionMode
            ? Text("${_selectedIndices.length} selected")
            : Text(widget.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color.fromARGB(135, 0, 0, 0),
        forceMaterialTransparency: true,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.compose(
              outer: ImageFilter.blur(
                  sigmaY: 20, sigmaX: 20, tileMode: TileMode.decal),
              inner: ImageFilter.blur(
                  sigmaY: 40, sigmaX: 30, tileMode: TileMode.clamp),
            ),
            child: Container(color: Colors.transparent),
          ),
        ),
        actions: <Widget>[
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelectedPhotos,
            )
          else
            TouchableOpacity(
              onPressed: () {
                getImageFromGallery();
                HapticFeedback.heavyImpact();
              },
              child: const Padding(
                padding:
                    EdgeInsets.only(right: 15, left: 10, top: 10, bottom: 10),
                child: Icon(Icons.add_circle_outline_rounded, size: 25),
              ),
            ),
        ],
      ),
      body: GridView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          childAspectRatio: 1 / 1,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: files.length,
        itemBuilder: (BuildContext context, int index) {
          final isSelected = _selectedIndices.contains(index);

          return GestureDetector(
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(index);
              } else {
                final String imageUrl =
                    Uri.encodeQueryComponent(photoDirectoryPath);
                context.push("/photo/$imageUrl/$index/${files.length}");
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode(index);
              }
            },
            child: Hero(
              tag: index,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.black,
                    width: isSelected ? 3 : 0,
                  ),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1 / 1,
                      child: FutureBuilder<Widget>(
                        future: chainedAsyncOperations(index),
                        builder: (context, snapshot) {
                          Widget child;
                          if (snapshot.hasData) {
                            child = SizedBox.expand(child: snapshot.data!);
                          } else {
                            child = BlurHash(hash: files[index].values.last.$1);
                          }
                          return AnimatedSwitcher(
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            duration: const Duration(milliseconds: 200),
                            child: child,
                          );
                        },
                      ),
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white.withOpacity(0.8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey.withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
