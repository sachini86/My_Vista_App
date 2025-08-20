import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'artistadd_product.dart';

class ArtistHomePage extends StatefulWidget {
  const ArtistHomePage({super.key}); // ✅ super parameter used

  @override
  State<ArtistHomePage> createState() => _ArtistHomePageState();
}

class _ArtistHomePageState extends State<ArtistHomePage> {
  final user = FirebaseAuth.instance.currentUser;

  /// Edit artwork
  Future<void> _editArtwork(String id, String currentTitle) async {
    final titleController = TextEditingController(text: currentTitle);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Artwork"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: "Update artwork title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection("artists")
                    .doc(user!.uid)
                    .collection("artworks")
                    .doc(id)
                    .update({"title": titleController.text});
                if (!mounted) return; // ✅ mounted check
                Navigator.pop(context);
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteArtwork(String id) async {
    await FirebaseFirestore.instance
        .collection("artists")
        .doc(user!.uid)
        .collection("artworks")
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff3f3f3),
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(user!.uid)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                "Hi, ...",
                style: TextStyle(color: Colors.white),
              );
            }
            final name = snapshot.data?.data()?['name'] ?? 'Artist';
            return Text(
              "Hi, $name",
              style: const TextStyle(color: Colors.white),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications, color: Colors.white),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Uploaded Works",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("artists")
                    .doc(user!.uid)
                    .collection("artworks")
                    .orderBy("createdAt", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading artworks"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No artworks uploaded yet"),
                    );
                  }
                  final artworks = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: artworks.length,
                    itemBuilder: (context, index) {
                      final art = artworks[index];
                      return Card(
                        child: ListTile(
                          title: Text(art["title"]),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _editArtwork(art.id, art["title"]),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteArtwork(art.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.grey.shade300,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductDetailsPage1()),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.brush), label: "Works"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "Cart",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        onTap: (index) {},
      ),
    );
  }
}
