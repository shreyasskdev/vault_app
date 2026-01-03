import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialRectArcTween;
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:smooth_gradient/smooth_gradient.dart';
import 'package:vault/providers.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

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
  bool _isThumbnailLoading = false;

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
      // Start loading all thumbnails in the background
      _loadAllThumbnails();
    }
  }

  Future<void> _loadAllThumbnails() async {
    if (_isThumbnailLoading || files.isEmpty) return;
    _isThumbnailLoading = true;

    final List<Future<void>> thumbnailFutures = [];
    for (int i = 0; i < files.length; i++) {
      if (!_thumbnailCache.containsKey(i)) {
        thumbnailFutures.add(_loadThumbnailAtIndex(i));
      }
    }

    await Future.wait(thumbnailFutures);

    if (mounted) {
      setState(() {
        _isThumbnailLoading = false;
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

  // Future<Uint8List?> _generateVideoThumbnailMediaKit(String path) async {
  //   final player = Player();
  //   // Attaching the controller tells MediaKit to initialize the hardware surface
  //   VideoController(player);

  //   try {
  //     // 1. Open media (play: false is important to avoid audio blast)
  //     await player.open(Media(path), play: false);

  //     // 2. Wait for the video parameters to be initialized (Real width/height)
  //     // This is the "Go" signal from the engine
  //     setState(() {});
  //     await player.stream.videoParams
  //         .firstWhere((p) => p.w != null && p.w! > 0)
  //         .timeout(const Duration(seconds: 5));
  //     setState(() {});

  //     // 3. Seek to get a frame (2 seconds in as you wanted)
  //     await player.seek(const Duration(seconds: 2));
  //     setState(() {});

  //     // 4. Wait for the seek to finish. This is much faster than Future.delayed(5000)
  //     await player.stream.position
  //         .firstWhere((p) => p.inSeconds >= 1) // Wait until it's moved
  //         .timeout(const Duration(seconds: 2))
  //         .catchError((_) => Duration.zero);

  //     // 5. A very small delay (200ms) just to ensure the GPU has painted the texture
  //     await Future.delayed(const Duration(milliseconds: 200));

  //     // 6. Capture
  //     return await player.screenshot();
  //   } catch (e) {
  //     debugPrint("MediaKit Error: $e");
  //     return null;
  //   } finally {
  //     await player.dispose(); // This also cleans up the controller
  //   }
  // }

  Future getImageFromGallery() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collections';

    final List<XFile> images = await ImagePicker().pickMultipleMedia();

    if (images.isEmpty) {
      debugPrint("No image selected");
      return;
    }

    await Future.forEach(images, (image) async {
      try {
        final bytes = await image.readAsBytes();

        final Uint8List uint8list = Uint8List.fromList(bytes);
        // final Uint8List? thumbData;

        // if (await isVideoWrapper(uint8list)) {
        // thumbData = await _generateVideoThumbnailMediaKit(image.path);
        // if (Platform.isAndroid) {
        // await File(image.path).delete();
        // }
        // await saveImageWrapper(thumbData, '$directory/${widget.name}');
        // } else {
        await saveImageWrapper(uint8list, '$directory/${widget.name}');
        // }
      } catch (e) {
        debugPrint("Error processing image: $e");
      }
    });

    _initializeAndLoadFiles();
    setState(() {});
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

    await Future.wait(sortedIndices.map((index) async {
      if (index < files.length) {
        final fileName = files[index].keys.first;
        final filePath = "$photoDirectoryPath/$fileName";
        await deleteFileWrapper(filePath);
      }
    }));

    _exitSelectionMode();
    _initializeAndLoadFiles();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.of(context).padding.top + kMinInteractiveDimensionCupertino;

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

        return RepaintBoundary(
          child: GestureDetector(
            onTap: () {
              if (_isSelectionMode) {
                _toggleSelection(index);
              } else {
                final String imageUrl =
                    Uri.encodeQueryComponent(photoDirectoryPath);

                Navigator.of(context)
                    .push(
                      CupertinoPageRoute(
                        builder: (context) => PhotoView(
                          url: Uri.decodeQueryComponent(imageUrl),
                          index: index,
                          count: files.length,
                          initialThumbnail: thumbnailData,
                        ),
                      ),
                    )
                    .then((t) => {_initializeAndLoadFiles()});
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _toggleSelectionMode(index);
              }
            },
            child: Hero(
              tag: index,
              createRectTween: (begin, end) {
                return MaterialRectArcTween(begin: begin, end: end);
              },
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
                    else
                      BlurHash(hash: files[index].values.first.$1),
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
                                ? CupertinoTheme.of(context).primaryColor
                                : CupertinoColors.secondaryLabel
                                    .resolveFrom(context),
                            border: Border.all(
                              color: isSelected
                                  ? CupertinoTheme.of(context).primaryColor
                                  : CupertinoColors.systemFill
                                      .resolveFrom(context),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  CupertinoIcons.check_mark,
                                  size: 16,
                                  color: CupertinoTheme.of(context)
                                      .scaffoldBackgroundColor,
                                )
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return CupertinoPageScaffold(
      // extendBodyBehindAppBar: true,
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            CupertinoTheme.of(context).scaffoldBackgroundColor.withAlpha(0),
        border: null,
        enableBackgroundFilterBlur: false,
        leading: _isSelectionMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _exitSelectionMode,
                child: const Icon(CupertinoIcons.xmark, size: 22),
              )
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                // CupertinoIcons.back is the native iOS chevron
                child: const Icon(CupertinoIcons.back, size: 28),
              ),
        middle: _isSelectionMode
            ? Text("${_selectedIndices.length} selected")
            : Text(widget.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: _isSelectionMode
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _deleteSelectedPhotos,
                // Using systemRed for destructive actions is standard iOS practice
                child: const Icon(CupertinoIcons.delete,
                    color: CupertinoColors.systemRed, size: 24),
              )
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  getImageFromGallery();
                  HapticFeedback.heavyImpact();
                },
                child: const Padding(
                  padding: EdgeInsets.only(
                      right: 8), // Standard iOS trailing padding
                  child: Icon(CupertinoIcons.add_circled, size: 26),
                ),
              ),
      ),
      child: Stack(
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
                    from: CupertinoTheme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(
                            !kIsWeb && (Platform.isAndroid || Platform.isIOS)
                                ? 255
                                : 220),
                    to: CupertinoTheme.of(context)
                        .scaffoldBackgroundColor
                        .withAlpha(0),
                    // from: Theme.of(context).colorScheme.surface.withAlpha(
                    //     !kIsWeb && (Platform.isAndroid || Platform.isIOS)
                    //         ? 255
                    //         : 220),
                    // to: Theme.of(context).colorScheme.surface.withAlpha(0),
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
