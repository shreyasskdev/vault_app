import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import "data.dart";

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage> {
  final _controller = TextEditingController();

  List<Directory> directories = [];

  @override
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
      Directory newDirectory = await Directory(newDirectoryPath).create();
      print('Created directory: ${newDirectory.path}');
    } catch (e) {
      if (e is PathNotFoundException) {
        await Directory('${appDocDir.path}/Collectons').create();
        Directory newDirectory = await Directory(newDirectoryPath).create();
        print('Created directory: ${newDirectory.path}');
      } else {
        print('Error creating directory: $e');
      }
    }
    context.pop();
    getDirs();
    _controller.text = "";
  }

  void getDirs() async {
    WidgetsFlutterBinding.ensureInitialized();

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String appDirectoryPath = '${appDocDir.path}/Collectons';

    try {
      // Get a list of all entities (files and directories) in the app directory
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
        return AlertDialog(
          content: SizedBox(
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: "Create a new Album",
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        createNewAlbumDirectory();
                      },
                      child: const Text("Create"),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text("Cancel"),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet"), actions: <Widget>[
        GestureDetector(
          onTap: () {
            createNewAlbum(context);
          },
          child: const Padding(
            padding: EdgeInsets.only(right: 15, left: 10, top: 10, bottom: 10),
            child: Icon(Icons.add),
          ),
        ),
      ]),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(14),
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            childAspectRatio: 1 / 1.46,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
          ),
          itemCount: directories.length,
          itemBuilder: (BuildContext context, int index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  // customBorder: RoundedRectangleBorder(
                  //   borderRadius: BorderRadius.circular(20),
                  // ),
                  onTap: () {
                    final String albumName = directories[index].path;
                    context.push("/album/$albumName");
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Image.network(
                        "https://picsum.photos/200",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        directories[index].path.split("/").last,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          // color: Colors.white,
                        ),
                      ),
                      const Text(
                        "items",
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 152, 152, 152)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
