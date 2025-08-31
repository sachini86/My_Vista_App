import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

// Full-screen image viewer
class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

class CustomChat extends StatefulWidget {
  final String artistId;
  final String artistName;

  const CustomChat({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<CustomChat> createState() => _CustomChatState();
}

class _CustomChatState extends State<CustomChat> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  File? _selectedImage;

  String getChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? "${uid1}_$uid2" : "${uid2}_$uid1";
  }

  // Pick image from gallery
  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Send message (text, image, or both)
  Future<void> sendMessage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final chatId = getChatId(user.uid, widget.artistId);
    String? imageUrl;

    // Upload image if selected
    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(chatId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_selectedImage!);
      imageUrl = await storageRef.getDownloadURL();
    }

    if ((_controller.text.trim().isEmpty) && imageUrl == null) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': user.uid,
          'text': _controller.text.trim().isEmpty
              ? null
              : _controller.text.trim(),
          'imageUrl': imageUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

    // Clear input
    _controller.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    final chatId = getChatId(user.uid, widget.artistId);

    return Scaffold(
      backgroundColor: Colors.white, // ✅ fixes red background globally
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: Text(
          widget.artistName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('chats')
                    .doc(chatId)
                    .collection('messages')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No messages yet",
                        style: TextStyle(color: Colors.black54),
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs;

                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final data = msg.data() as Map<String, dynamic>? ?? {};
                      final text = data['text'] as String?;
                      final imageUrl = data['imageUrl'] as String?;
                      final isMe = data['senderId'] == user.uid;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xffFAD2CF)
                                : Colors.black,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (text != null && text.isNotEmpty)
                                Text(
                                  text,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: isMe ? Colors.black : Colors.white,
                                  ),
                                ),
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => FullScreenImage(
                                            imageUrl: imageUrl,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        // ✅ show progress while loading
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              }
                                              return Container(
                                                width: 200,
                                                height: 200,
                                                alignment: Alignment.center,
                                                child:
                                                    const CircularProgressIndicator(),
                                              );
                                            },
                                        // ✅ show fallback if load fails
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 200,
                                                  height: 200,
                                                  color: Colors.grey[300],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
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
          ),

          // Selected image preview
          if (_selectedImage != null)
            Container(
              color: Colors.white, // ✅ keeps preview area white
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Image.file(
                    _selectedImage!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      child: const Icon(Icons.close, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Input area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Color(0xff930909)),
                  onPressed: pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: "Type a message.......",
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: Color(0xff930909),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xff930909)),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
