import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_vista/screens/CustomHome/bottom_nav_bar.dart';
import 'package:my_vista/screens/Customchat/custom_chat.dart';

class ArtworkDetailPage extends StatelessWidget {
  const ArtworkDetailPage({
    super.key,
    required this.artworkId,
    required this.data,
  });

  final String artworkId;
  final Map<String, dynamic> data;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final price = (data['price'] ?? 0).toDouble();
    final currency = data['currency'] ?? "US\$";

    // Media files
    final List<dynamic> extraImages = data['extraImages'] ?? [];
    final List<dynamic> thumbnails = data['thumbnails'] ?? [];
    final List<dynamic> videos = data['videos'] ?? [];

    final List<String> mediaItems = [
      if (data['artworkUrl'] != null && data['artworkUrl'] != "")
        data['artworkUrl'],
      ...extraImages.cast<String>(),
      ...thumbnails.cast<String>(),
      if (videos.isNotEmpty) "VIDEO_PLACEHOLDER",
    ];

    // Sizes (map with keys: height, width, depth)
    final Map<String, dynamic> size = data['size'] ?? {};

    // Artist info - Try multiple possible field names
    final String artistId =
        data['artistId'] ?? data['userId'] ?? data['uid'] ?? '';
    final String artistName = data['artistName'] ?? "Unknown Artist";
    final String artistProfileUrl = data['artistProfileUrl'] ?? "";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey.shade200,
        title: Text(
          data['title'] ?? 'Artwork',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const RoundedBottomnavbar()),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---- Media Carousel ----
            SizedBox(
              height: 250,
              child: PageView.builder(
                itemCount: mediaItems.length,
                itemBuilder: (context, index) {
                  final item = mediaItems[index];
                  if (item == "VIDEO_PLACEHOLDER") {
                    return const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 64,
                        color: Colors.black54,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(item, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ---- Artwork Details ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Artwork',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // ---- Metadata ----
                  _metaRow("Category", data['category']),
                  _metaRow("Style", data['style']),
                  _metaRow("Material", data['material']),

                  // ---- Sizes ----
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 90,
                          child: Text(
                            "Size:",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (size['height'] != null)
                                Text(
                                  "Height: ${size['height']['value']} ${size['height']['unit']}",
                                ),
                              if (size['width'] != null)
                                Text(
                                  "Width: ${size['width']['value']} ${size['width']['unit']}",
                                ),
                              if (size['depth'] != null)
                                Text(
                                  "Depth: ${size['depth']['value']} ${size['depth']['unit']}",
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(thickness: 1.2),
                  const SizedBox(height: 8),

                  // ---- Artist Info ----
                  const Text(
                    "Artist",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: artistProfileUrl != ""
                            ? NetworkImage(artistProfileUrl)
                            : null,
                        backgroundColor: Colors.grey.shade300,
                        child: artistProfileUrl == ""
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          artistName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;

                              if (currentUser == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to chat'),
                                  ),
                                );
                                return;
                              }

                              // Check if artistId is available
                              if (artistId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Artist information not available',
                                    ),
                                  ),
                                );
                                return;
                              }

                              // Don't allow chatting with yourself
                              if (currentUser.uid == artistId) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You cannot chat with yourself',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                // Create unique chat ID
                                final userIds = [currentUser.uid, artistId]
                                  ..sort();
                                final chatId = '${userIds[0]}_${userIds[1]}';

                                // Check if chat already exists, if not create it
                                final chatDoc = await FirebaseFirestore.instance
                                    .collection('chats')
                                    .doc(chatId)
                                    .get();

                                if (!chatDoc.exists) {
                                  // Create new chat document
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(chatId)
                                      .set({
                                        'participants': [
                                          currentUser.uid,
                                          artistId,
                                        ],
                                        'participantDetails': {
                                          currentUser.uid: {
                                            'name':
                                                currentUser.displayName ??
                                                'User',
                                            'image': currentUser.photoURL ?? '',
                                          },
                                          artistId: {
                                            'name': artistName,
                                            'image': artistProfileUrl,
                                          },
                                        },
                                        'lastMessage': '',
                                        'lastMessageTime':
                                            FieldValue.serverTimestamp(),
                                        'createdAt':
                                            FieldValue.serverTimestamp(),
                                        'artworkId': artworkId,
                                        'artworkTitle':
                                            data['title'] ?? 'Artwork',
                                      });
                                }

                                // Navigate to chat page
                                if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CustomChat(
                                      key: ValueKey(chatId),
                                      chatId: chatId,
                                      otherUserId: artistId,
                                      otherUserName: artistName,
                                      otherUserImage: artistProfileUrl,
                                      artworkTitle: data['title'] ?? 'Artwork',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error starting chat: $e'),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            child: const Icon(
                              Icons.chat,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () async {
                              if (_user == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please login to follow'),
                                  ),
                                );
                                return;
                              }

                              if (artistId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Artist information not available',
                                    ),
                                  ),
                                );
                                return;
                              }

                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_user!.uid)
                                    .collection('following')
                                    .doc(artistId)
                                    .set({
                                      'artistId': artistId,
                                      'artistName': artistName,
                                      'artistProfileUrl': artistProfileUrl,
                                      'followedAt':
                                          FieldValue.serverTimestamp(),
                                    });

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Artist followed successfully',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error following artist: $e'),
                                  ),
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            child: const Text(
                              "Follow",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 100), // space for bottom bar
                ],
              ),
            ),
          ],
        ),
      ),

      // ---- Bottom Navigation Bar ----
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 1.5)),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Price row
            Row(
              children: [
                Text(
                  "$currency ${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.black,
                    ),
                    label: const Text(
                      "Favorite",
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () async {
                      if (_user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to add favorites'),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .collection('favourites')
                            .doc(artworkId)
                            .set({
                              'artworkId': artworkId,
                              'title': data['title'],
                              'artistName': artistName,
                              'artistId': artistId,
                              'price': price,
                              'currency': currency,
                              'artworkUrl': data['artworkUrl'],
                              'addedAt': FieldValue.serverTimestamp(),
                            });
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Added to Favorites")),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text("Add to Cart"),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xff930909),
                    ),
                    onPressed: () async {
                      if (_user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to add to cart'),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user!.uid)
                            .collection('cart')
                            .doc(artworkId)
                            .set({
                              'artworkId': artworkId,
                              'title': data['title'],
                              'artistName': artistName,
                              'artistId': artistId,
                              'price': price,
                              'currency': currency,
                              'artworkUrl': data['artworkUrl'],
                              'qty': FieldValue.increment(1),
                              'addedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Added to Cart")),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? "-",
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
