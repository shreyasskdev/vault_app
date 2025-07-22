import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:vault/providers.dart';
import 'package:vault/widget/touchable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_gradient/smooth_gradient.dart';

import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

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

  // ScrollController to monitor the GridView's scroll position.
  late final ScrollController _scrollController;
  // Boolean to track if the gradient/blur should be visible.
  bool _isGradientVisible = false;

  @override
  void initState() {
    super.initState();
    // Initialize the ScrollController and add a listener to it.
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    getImages();
  }

  // This listener function is called every time the user scrolls.
  void _scrollListener() {
    // Check if the user has scrolled down from the top.
    final bool shouldBeVisible = _scrollController.offset > 0;
    // Only call setState if the visibility state actually needs to change.
    // This prevents unnecessary rebuilds on every scroll tick.
    if (shouldBeVisible != _isGradientVisible) {
      setState(() {
        _isGradientVisible = shouldBeVisible;
      });
    }
  }

  // It's crucial to dispose of the controller to prevent memory leaks.
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future getImageFromGallery() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String directory = '${appDocDir.path}/Collections';

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
          await File(image!.path).delete(); // Delete cached file
        }
        final Uint8List uint8list = Uint8List.fromList(bytes!);

        await saveImageWrapper(uint8list, '$directory/${widget.name}');
      } catch (e) {
        debugPrint("Error processing image $i: $e");
      }
      getImages();
    }
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
    final imageData = await (getFileThumbWrapper(imagePath, ref));

    return Image.memory(
      gaplessPlayback: true,
      Uint8List.fromList(imageData),
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
        await deleteFileWrapper(filePath);
      }
    }

    _exitSelectionMode();
    getImages();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the total height needed for top padding.
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
          // Conditionally apply the ProgressiveBlurWidget based on settings
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

          // This is the decorative gradient layer that fades in on scroll.
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
