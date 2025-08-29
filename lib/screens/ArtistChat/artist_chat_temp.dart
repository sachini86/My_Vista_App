import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ArtistChat extends StatefulWidget {
  const ArtistChat({super.key});

  @override
  State<ArtistChat> createState() => _ArtistChatState();
}

class _ArtistChatState extends State<ArtistChat> {
  String? _selectedChatId;
  final TextEditingController _controller = TextEditingController();
  bool _showEmojiPicker = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: Text(
          _selectedChatId == null ? "My Chats" : "Chat",
          style: const TextStyle(color: Colors.white),
        ),
        leading: _selectedChatId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _selectedChatId = null),
              )
            : null,
      ),
      body: _selectedChatId == null
          ? _buildChatList(uid)
          : _buildChatPage(uid, _selectedChatId!),
    );
  }

  /// 🔹 Chat list
  Widget _buildChatList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("participants", arrayContains: uid)
          .orderBy("createdAt", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data!.docs;
        if (chats.isEmpty) return const Center(child: Text("No chats yet"));

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            final otherId = (chat["participants"] as List).firstWhere(
              (id) => id != FirebaseAuth.instance.currentUser!.uid,
            );

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(otherId)
                  .get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) {
                  return const ListTile(title: Text("Loading..."));
                }
                final userData = userSnap.data!;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userData["profilePic"] != null
                        ? NetworkImage(userData["profilePic"])
                        : null,
                    child: userData["profilePic"] == null
                        ? Text(userData["name"][0])
                        : null,
                  ),
                  title: Text(userData["name"] ?? "Unknown"),
                  subtitle: Text(chat["lastMessage"] ?? ""),
                  onTap: () => setState(() => _selectedChatId = chat.id),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 🔹 Chat page
  Widget _buildChatPage(String uid, String chatId) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("chats")
                .doc(chatId)
                .collection("messages")
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg["senderId"] == uid;

                  if (msg["imageUrl"] != null) {
                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onLongPress: () async {
                              final url = msg["imageUrl"];
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Download link: $url")),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.all(6),
                              child: Image.network(
                                msg["imageUrl"],
                                width: 200,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Text("Image load failed"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.green : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(msg["text"] ?? ""),
                    ),
                  );
                },
              );
            },
          ),
        ),

        /// Message Input + Emoji + Image
        Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () =>
                      setState(() => _showEmojiPicker = !_showEmojiPicker),
                ),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => _pickImage(chatId, uid),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: "Message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(chatId, uid),
                ),
              ],
            ),
            const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  /// 🔹 Send text message
  Future<void> _sendMessage(String chatId, String uid) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final msgRef = FirebaseFirestore.instance
        .collection("chats")
        .doc(chatId)
        .collection("messages")
        .doc();

    await msgRef.set({
      "senderId": uid,
      "text": text,
      "imageUrl": null,
      "createdAt": FieldValue.serverTimestamp(),
      "readBy": [uid],
    });

    await FirebaseFirestore.instance.collection("chats").doc(chatId).update({
      "lastMessage": text,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  /// 🔹 Pick & upload image
  Future<void> _pickImage(String chatId, String uid) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final storageRef = FirebaseStorage.instance
        .ref()
        .child("chat_images")
        .child("${DateTime.now().millisecondsSinceEpoch}.jpg");

    try {
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      final msgRef = FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .collection("messages")
          .doc();

      await msgRef.set({
        "senderId": uid,
        "text": null,
        "imageUrl": downloadUrl,
        "createdAt": FieldValue.serverTimestamp(),
        "readBy": [uid],
      });

      await FirebaseFirestore.instance.collection("chats").doc(chatId).update({
        "lastMessage": "📷 Image",
        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
    }
  }
}
