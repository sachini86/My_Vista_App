import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArtistChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserImage;

  const ArtistChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserImage,
  });

  @override
  State<ArtistChatPage> createState() => _ArtistChatPageState();
}

class _ArtistChatPageState extends State<ArtistChatPage> {
  final _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  void sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    final messageData = {
      'senderId': currentUser!.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Save message under chat
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(messageData);

    // Update chat metadata
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('chats')
        .doc(widget.chatId)
        .update({
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .collection('chats')
        .doc(widget.chatId)
        .update({
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(backgroundImage: NetworkImage(widget.otherUserImage)),
            const SizedBox(width: 10),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser!.uid)
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
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
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser!.uid;

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
                          color: isMe ? Colors.blue[100] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(msg['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
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
