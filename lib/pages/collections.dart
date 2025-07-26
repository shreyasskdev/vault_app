import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:progressive_blur/progressive_blur.dart';
import 'package:smooth_gradient/smooth_gradient.dart';
import 'package:vault/moiton_detector.dart';
import 'package:vault/providers.dart';
import 'package:vault/utils/file_api_wrapper.dart' as fileapi;
import 'package:vault/widget/touchable.dart';
import 'dart:io' show Platform;

class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({super.key});

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage>
    with fileapi.FileApiWrapper {
  final _controller = TextEditingController();

  List<String>? directories;
  String? appDirectoryPath;
  List<Map<String, (String, double)>?>? imageValue;

  final Map<int, Uint8List> _thumbnailCache = {};

  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};

  late final ScrollController _scrollController;
  bool _isGradientVisible = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    init();
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> init() async {
    await initAppDir();
    await getDirsAndAlbum();
  }

  Future<void> initAppDir() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dir = await getApplicationDocumentsDirectory();
    if (mounted) {
      setState(() {
        appDirectoryPath = '${dir.path}/Collections';
      });
    }
  }

  Future<void> getDirsAndAlbum() async {
    if (appDirectoryPath == null) await initAppDir();

    final newDirectories = await getDirsWrapper(appDirectoryPath);
    final newImageValues = <Map<String, (String, double)>?>[];

    for (String directory in newDirectories) {
      final value =
          await getAlbumThumbWrapper("${appDirectoryPath!}/$directory");
      newImageValues.add(value);
    }

    if (mounted) {
      setState(() {
        directories = newDirectories;
        imageValue = newImageValues;
      });
    }
  }

  Future<void> _loadAlbumThumbnail(int index) async {
    if (_thumbnailCache.containsKey(index) ||
        appDirectoryPath == null ||
        imageValue == null ||
        imageValue![index] == null) {
      return;
    }

    try {
      final imageData = await getFileThumbWrapper(
          "$appDirectoryPath/${directories?[index]}/${imageValue![index]!.keys.first}",
          ref);

      if (mounted && !_thumbnailCache.containsKey(index)) {
        setState(() {
          _thumbnailCache[index] = Uint8List.fromList(imageData);
        });
      }
    } catch (e) {
      debugPrint("Error loading album thumbnail for index $index: $e");
    }
  }

  Future<void> createNewAlbumDirectory() async {
    if (appDirectoryPath == null) await initAppDir();
    String directoryName = _controller.text;
    if (directoryName.isEmpty) return;

    createDirWrapper(appDirectoryPath, directoryName);

    if (mounted) {
      context.pop();
    }
    _controller.clear();
    await getDirsAndAlbum();
  }

  void createNewAlbum(context) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AlertDialog(
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            contentPadding: const EdgeInsets.all(0),
            content: SizedBox(
              height: 150,
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    height: 75,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: SizedBox(
                      height: 43,
                      child: TextField(
                          onSubmitted: (string) {
                            createNewAlbumDirectory();
                          },
                          autofocus: true,
                          autocorrect: true,
                          cursorColor:
                              Theme.of(context).colorScheme.surfaceBright,
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: "Create a new Album",
                          )),
                    ),
                  ),
                  Container(
                    height: 75,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 75,
                            child: TouchableButton(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              onPressed: () {
                                createNewAlbumDirectory();
                              },
                              child: const Text(
                                "Create",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: SizedBox(
                            height: 75,
                            child: TouchableButton(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              onPressed: () => context.pop(),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (directories == null) {
      final loadingScaffold = Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Vault",
              style: TextStyle(fontWeight: FontWeight.w600)),
          centerTitle: true,
          actions: <Widget>[
            TouchableOpacity(
              onPressed: () {
                createNewAlbum(context);
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
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 8),
              Text("Loading...", style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        return MotionDetector(child: loadingScaffold);
      } else {
        return loadingScaffold;
      }
    }

    void toggleSelectionMode(int index) {
      setState(() {
        _isSelectionMode = true;
        _selectedIndices.add(index);
      });
      HapticFeedback.mediumImpact();
    }

    void toggleSelection(int index) {
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

    void exitSelectionMode() {
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });
    }

    Future<void> deleteSelectedAlbums() async {
      if (appDirectoryPath == null) return;

      final sortedIndices = _selectedIndices.toList()
        ..sort((a, b) => b.compareTo(a));

      for (final index in sortedIndices) {
        if (directories != null && index < directories!.length) {
          final dirPath = "$appDirectoryPath/${directories![index]}";
          await deleteDirWrapper(dirPath);
        }
      }

      exitSelectionMode();
      await getDirsAndAlbum();
    }

    Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top + 14,
        left: 14,
        right: 14,
        bottom: 14,
      ),
      physics:
          const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        childAspectRatio: 1,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
      ),
      itemCount: directories?.length ?? 0,
      itemBuilder: (BuildContext context, int index) {
        if (directories == null ||
            imageValue == null ||
            index >= directories!.length ||
            index >= imageValue!.length) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final isSelected = _selectedIndices.contains(index);
        // Get thumbnail data directly from cache.
        final thumbnailData = _thumbnailCache[index];
        final albumInfo = imageValue![index];

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              toggleSelection(index);
            } else {
              context.push("/album/${directories![index]}").then((_) async {
                await getDirsAndAlbum();
              });
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              toggleSelectionMode(index);
            }
          },
          child: Stack(
            children: [
              ClipRSuperellipse(
                borderRadius: BorderRadius.circular(30),
                clipBehavior: Clip.antiAliasWithSaveLayer,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailData != null)
                      Image.memory(
                        thumbnailData,
                        gaplessPlayback: true,
                        fit: BoxFit.cover,
                      )
                    else if (albumInfo != null && albumInfo.values.isNotEmpty)
                      Stack(
                        fit: StackFit.expand,
                        children: [
                          BlurHash(hash: albumInfo.values.first.$1),
                          Builder(builder: (context) {
                            _loadAlbumThumbnail(index);
                            return const SizedBox.shrink();
                          })
                        ],
                      )
                    else
                      Container(
                        color: Theme.of(context).colorScheme.surfaceDim,
                        child: const Center(child: Text("Empty")),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.surface.withAlpha(0),
                            Theme.of(context).colorScheme.surface
                          ],
                        ),
                      ),
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
                      child: Text(
                        directories![index].split("/").last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isSelectionMode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.transparent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30),
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
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(204),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .surfaceBright
                                .withAlpha(128),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );

    final mainScaffold = Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: exitSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  context.push("/settings");
                },
              ),
        title: _isSelectionMode
            ? Text("${_selectedIndices.length} selected")
            : const Text("Vault",
                style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: <Widget>[
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: deleteSelectedAlbums,
            )
          else
            TouchableOpacity(
              onPressed: () {
                createNewAlbum(context);
                HapticFeedback.heavyImpact();
              },
              child: const Padding(
                padding:
                    EdgeInsets.only(right: 15, left: 10, top: 10, bottom: 10),
                child: Icon(Icons.add_circle_outline_rounded, size: 25),
              ),
            ),
        ],
        forceMaterialTransparency: true,
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

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return MotionDetector(child: mainScaffold);
    } else {
      return mainScaffold;
    }
  }
}
