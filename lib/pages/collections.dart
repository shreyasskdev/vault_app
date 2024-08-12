import 'dart:ui';
// import 'package:flutter/widgets.dart';
import 'dart:ui' as ui;

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vault/widget/touchable.dart';
import 'dart:io';

import 'package:vault/utils/file_api_wrapper.dart' as fileapi;

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage>
    with fileapi.FileApiWrapper {
  final _controller = TextEditingController();

  List<String>? directories;
  String? appDirectoryPath;
  List<Map<String, (String, double)>?>? imageValue;

  @override // Code to run in startup
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await initAppDir();
    await getDirsAndAlbum();
  }

  Future<void> initAppDir() async {
    WidgetsFlutterBinding.ensureInitialized();
    await getApplicationDocumentsDirectory().then((dir) {
      setState(() {
        appDirectoryPath = '${dir.path}/Collections';
      });
    });
  }

  Future<void> getDirsAndAlbum() async {
    if (appDirectoryPath == null) await initAppDir();

    List<String> directories = await getDirsWrapper(appDirectoryPath);
    setState(() {
      // this.directories = directories;
      imageValue = [];
    });
    for (String directory in directories) {
      await getAlbumThumbWrapper("${appDirectoryPath!}/$directory")
          .then((value) {
        setState(() {
          imageValue!.add(value);
        });
      });
    }
    setState(() {
      this.directories = directories;
      // imageValue = [];
    });
  }

  Future<Widget> chainedAsyncOperations(index) async {
    if (appDirectoryPath == null) await initAppDir();
    if (imageValue == null) {
      await getDirsAndAlbum();
    }

    print("$imageValue :: $directories");

    if (imageValue![index] == null) {
      return Container(
        color: const Color.fromARGB(255, 14, 14, 14),
        child: const Center(
          child: Text("Empty"),
        ),
      );
    }
    print("THIS >> ${directories?[index]}/${imageValue![index]!.keys.first}");
    Uint8List imageData = await getFileThumbWrapper(
        "$appDirectoryPath/${directories?[index]}/${imageValue![index]!.keys.first}");

    return Image.memory(
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

  Future<void> createNewAlbumDirectory() async {
    if (appDirectoryPath == null) await initAppDir();

    String directoryName = _controller.text;
    createDirWrapper(appDirectoryPath, directoryName);

    if (mounted) {
      context.pop();
    }
    _controller.text = "";
    getDirsAndAlbum();
  }

  void createNewAlbum(context) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: AlertDialog(
            shape: SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius(
                cornerRadius: 30,
                cornerSmoothing: 0.6,
              ),
            ),
            contentPadding: const EdgeInsets.all(0),
            content: ClipSmoothRect(
              radius: const SmoothBorderRadius.all(
                SmoothRadius(cornerRadius: 30, cornerSmoothing: 0.6),
              ),
              child: SizedBox(
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
                              child: ClipSmoothRect(
                                radius: const SmoothBorderRadius.all(
                                  SmoothRadius(
                                      cornerRadius: 20, cornerSmoothing: 0.6),
                                ),
                                child: TouchableButton(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius:
                                      const BorderRadius.all(Radius.zero),
                                  // padding: EdgeInsets.all(15),

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
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 75,
                              child: ClipSmoothRect(
                                radius: const SmoothBorderRadius.all(
                                  SmoothRadius(
                                      cornerRadius: 20, cornerSmoothing: 0.6),
                                ),
                                child: TouchableButton(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderColor: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  borderRadius:
                                      const BorderRadius.all(Radius.zero),
                                  onPressed: () => context.pop(),
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (directories == null) return Container(child: Text("Loading"));
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Vault", style: TextStyle(fontWeight: FontWeight.w600)),
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
              child: Icon(
                Icons.add_circle_outline_rounded,
                size: 25,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(14),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            childAspectRatio: 1,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: directories?.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                context
                    .push("/album/${directories?[index].split("/").last}")
                    // .then((_) => getDirs());
                    .then((_) async {
                  await getDirsAndAlbum();
                });
              },
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: ShapeDecoration(
                  shape: SmoothRectangleBorder(
                    // side: const BorderSide(
                    //   color: Color.fromARGB(255, 135, 135, 135),
                    //   width: 2,
                    // ),
                    borderRadius: SmoothBorderRadius(
                      cornerRadius: 30,
                      cornerSmoothing: 0.5,
                    ),
                  ),
                ),
                child:
                    // ClipSmoothRect(
                    //   radius: const SmoothBorderRadius.all(
                    //     SmoothRadius(cornerRadius: 30, cornerSmoothing: 0.5),
                    //   ),
                    Stack(
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
                            if (imageValue != null &&
                                imageValue![index] != null &&
                                imageValue![index]!.values.isNotEmpty) {
                              child = BlurHash(
                                hash: imageValue![index]!.values.first.$1,
                              );
                            } else {
                              child = Text("Empty");
                            }
                          }
                          // return child;
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
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(0, 0, 0, 0),
                            Color.fromARGB(200, 0, 0, 0)
                          ],
                        ),
                      ),
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 5),
                      child: Text(
                        directories![index].split("/").last,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.fade,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
