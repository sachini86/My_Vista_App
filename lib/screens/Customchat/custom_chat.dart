import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🔹 Helper: Create or Get Chat
Future<String> createOrGetChat(String artistId, String buyerId) async {
  final chats = FirebaseFirestore.instance.collection("chats");

  // Create predictable chat ID (sorted so both sides see same ID)
  final ids = [artistId, buyerId]..sort();
  final chatId = ids.join("_");

  final chatDoc = chats.doc(chatId);

  final snapshot = await chatDoc.get();
  if (!snapshot.exists) {
    await chatDoc.set({
      "participants": [artistId, buyerId],
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  return chatId;
}

// 🔹 Custom Chat Screen (single page with list + chat)
class CustomChat extends StatefulWidget {
  final String? initialArtistId; // passed from "Message Artist"

  const CustomChat({super.key, this.initialArtistId});

  @override
  State<CustomChat> createState() => _CustomChatState();
}

class _CustomChatState extends State<CustomChat> {
  String? _selectedChatId;

  @override
  void initState() {
    super.initState();
    _openChatIfNeeded();
  }

  Future<void> _openChatIfNeeded() async {
    if (widget.initialArtistId != null) {
      final buyerId = FirebaseAuth.instance.currentUser!.uid;
      final chatId = await createOrGetChat(widget.initialArtistId!, buyerId);
      setState(() {
        _selectedChatId = chatId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChatId != null) {
      // 🔹 Directly show chat page if opened via "Message Artist"
      return ChatPage(chatId: _selectedChatId!);
    }

    final buyerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff930909),
        title: const Text("My Chats", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("chats")
            .where("participants", arrayContains: buyerId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text("No chats yet"));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat["participants"]);
              final otherId = participants.firstWhere((id) => id != buyerId);

              return ListTile(
                title: Text("Chat with $otherId"),
                onTap: () {
                  setState(() {
                    _selectedChatId = chat.id;
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

// 🔹 Chat Page (used inside BuyerChatScreen or ArtistChatScreen)
class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final userId = FirebaseAuth.instance.currentUser!.uid;

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .add({
          "text": _controller.text.trim(),
          "senderId": userId,
          "timestamp": FieldValue.serverTimestamp(),
        });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("chats")
                  .doc(widget.chatId)
                  .collection("messages")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg["senderId"] == userId;

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
                          color: isMe ? Colors.blue[200] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg["text"]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
