import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import "data.dart";

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet"),
      ),
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
          itemCount: imageList.length,
          itemBuilder: (BuildContext context, int index) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  // customBorder: RoundedRectangleBorder(
                  //   borderRadius: BorderRadius.circular(20),
                  // ),
                  onTap: () {
                    final String albumName = imageList[index]['name'];
                    context.push("/album/$albumName");
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1 / 1,
                      child: Image.network(
                        imageList[index]["url"],
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
                        imageList[index]["name"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          // color: Colors.white,
                        ),
                      ),
                      Text(
                        imageList[index]["items"].toString(),
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
