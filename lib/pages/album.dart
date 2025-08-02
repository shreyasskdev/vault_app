import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:smooth_gradient/smooth_gradient.dart';
import 'package:vault/providers.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;
import 'package:vault/widget/touchable.dart';

import 'photo.dart';

class AlbumPage extends ConsumerStatefulWidget {
  final String name;
  const AlbumPage({super.key, required this.name});

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage>
    with fileapi.FileApiWrapper {
  List<Map<String, (String, double)>> files = [];
  String photoDirectoryPath = "";

  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  late final ScrollController _scrollController;
  bool _isGradientVisible = false;

  final Map<int, Uint8List> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _initializeAndLoadFiles();
  }

  void _scrollListener() {
    final bool shouldBeVisible = _scrollController.offset > 0;
    if (shouldBeVisible != _isGradientVisible) {
      setState(() {
        _isGradientVisible = shouldBeVisible;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeAndLoadFiles() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    photoDirectoryPath = '${appDocDir.path}/Collections/${widget.name}';

    final imageList = await getImagesWrapper(photoDirectoryPath);
    if (mounted) {
      setState(() {
        files = sortMapToList(imageList);
      });
    }
  }

  Future<void> _loadThumbnailAtIndex(int index) async {
    if (_thumbnailCache.containsKey(index) || files.isEmpty) return;

    try {
      final imagePath = "$photoDirectoryPath/${files[index].keys.first}";
      final imageData = await getFileThumbWrapper(imagePath, ref);

      if (mounted && !_thumbnailCache.containsKey(index)) {
        setState(() {
          _thumbnailCache[index] = Uint8List.fromList(imageData);
        });
      }
    } catch (e) {
      debugPrint("Error loading thumbnail for index $index: $e");
    }
  }

  Future getImageFromGallery() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collections';

    // final List<XFile?> images = await ImagePicker().pickMultipleMedia();
    final List<XFile?> images = await ImagePicker().pickMultiImage();

    if (images.isEmpty) {
      debugPrint("No image selected");
      return;
    }
    for (int i = 0; i < images.length; i++) {
      try {
        final XFile? image = images[i];

        final bytes = await image?.readAsBytes();
        if (Platform.isAndroid) {
          await File(image!.path).delete();
        }
        final Uint8List uint8list = Uint8List.fromList(bytes!);

        await saveImageWrapper(uint8list, '$directory/${widget.name}');
      } catch (e) {
        debugPrint("Error processing image $i: $e");
      }
    }
    _initializeAndLoadFiles();
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
    final sortedIndices = _selectedIndices.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final index in sortedIndices) {
      if (index < files.length) {
        final fileName = files[index].keys.first;
        final filePath = "$photoDirectoryPath/$fileName";
        await deleteFileWrapper(filePath);
      }
    }

    _exitSelectionMode();
    _initializeAndLoadFiles();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    final Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: topPadding + 14,
        left: 0,
        right: 0,
        bottom: 14,
      ),
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
        final thumbnailData = _thumbnailCache[index];

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(index);
            } else {
              final String imageUrl =
                  Uri.encodeQueryComponent(photoDirectoryPath);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PhotoView(
                    url: Uri.decodeQueryComponent(imageUrl),
                    index: index,
                    count: files.length,
                    initialThumbnail: thumbnailData,
                  ),
                ),
              );
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
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailData != null)
                    Image.memory(
                      thumbnailData,
                      gaplessPlayback: true,
                      fit: BoxFit.cover,
                    )
                  else ...[
                    BlurHash(hash: files[index].values.first.$1),
                    Builder(
                      builder: (context) {
                        _loadThumbnailAtIndex(index);
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
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
                              : Colors.white.withAlpha(204),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withAlpha(128),
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
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        forceMaterialTransparency: true,
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
      body: Stack(
        children: [
          ref.watch(settingsModelProvider).advancedTextures
              ? ProgressiveBlurWidget(
                  linearGradientBlur: const LinearGradientBlur(
                    values: [1, 0],
                    stops: [0, 0.2],
                    start: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  sigma: _isGradientVisible ? 24.0 : 0,
                  blurTextureDimensions: 128,
                  child: gridView)
              : gridView,
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isGradientVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastEaseInToSlowEaseOut,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: SmoothGradient(
                    from: Theme.of(context).colorScheme.surface.withAlpha(
                        !kIsWeb && (Platform.isAndroid || Platform.isIOS)
                            ? 255
                            : 220),
                    to: Theme.of(context).colorScheme.surface.withAlpha(0),
                    curve: const Cubic(.05, .26, 1, .55),
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
