import 'dart:ui';

import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Vault/widget/touchable.dart';
import 'dart:io';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final _controller = TextEditingController();

  List<Directory> directories = [];

  @override // Code to run in startup
  void initState() {
    super.initState();
    getDirs();
  }

  void createNewAlbumDirectory() async {
    WidgetsFlutterBinding.ensureInitialized(); // Required for path_provider
    String directoryName = _controller.text;
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String newDirectoryPath = '${appDocDir.path}/Collectons/$directoryName';

    try {
      await Directory(newDirectoryPath).create();
    } catch (e) {
      if (e is PathNotFoundException) {
        await Directory('${appDocDir.path}/Collectons').create();
        await Directory(newDirectoryPath).create();
      } else {
        print('Error creating directory: $e');
      }
    }
    if (mounted) {
      context.pop();
    }
    getDirs();
    _controller.text = "";
  }

  void getDirs() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDirectoryPath = '${appDocDir.path}/Collectons';

    try {
      List<FileSystemEntity> entities = Directory(appDirectoryPath).listSync();

      setState(() {
        directories = entities.whereType<Directory>().toList();
      });
    } catch (e) {
      print('Error: $e');
    }
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
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Wallet", style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: <Widget>[
          TouchableOpacity(
            onPressed: () {
              createNewAlbum(context);
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
          itemCount: directories.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                context
                    .push("/album/${directories[index].path.split("/").last}");
              },
              child: Stack(
                children: [
                  ClipSmoothRect(
                    radius: const SmoothBorderRadius.all(
                      SmoothRadius(cornerRadius: 30, cornerSmoothing: 0.5),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: FutureBuilder<Directory>(
                        future: getApplicationDocumentsDirectory(),
                        builder: (BuildContext context,
                            AsyncSnapshot<Directory> snapshot) {
                          if (snapshot.hasData) {
                            String imagePath =
                                '${snapshot.data!.path}/Collectons/${directories[index].path.split("/").last}/${directories[index].path.split("/").last}.image';

                            return Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print("Wallet_Error: $error");
                                return Container(
                                  color: const Color.fromARGB(255, 14, 14, 14),
                                  child: const Center(
                                    child: Text("error"),
                                  ),
                                );
                              },
                            );
                          } else {
                            return const CircularProgressIndicator();
                          }
                        },
                      ),
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
                    padding: const EdgeInsets.fromLTRB(0, 0, 15, 5),
                    child: Text(
                      directories[index].path.split("/").last,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
