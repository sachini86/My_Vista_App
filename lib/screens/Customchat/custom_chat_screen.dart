import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'chat_service.dart';

class CustomChatScreen extends StatefulWidget {
  final String artistId;
  final String artistName;
  final String? artistProfileUrl;

  const CustomChatScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.artistProfileUrl,
  });

  @override
  State<CustomChatScreen> createState() => _CustomChatScreenState();
}

class _CustomChatScreenState extends State<CustomChatScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String? editingMessageId; // For edit mode

  String get _chatId =>
      widget.artistId; // Use artistId as chatId for simplicity

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Center(child: Text('User not logged in'));

    final currentUserChatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('chats')
        .doc(_chatId)
        .collection('messages');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.artistProfileUrl != null
                  ? NetworkImage(widget.artistProfileUrl!)
                  : null,
              child: widget.artistProfileUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(widget.artistName, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: currentUserChatRef.orderBy('createdAt').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
                  return const Center(child: Text('Say Hi 👋'));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final messageId = messages[index].id;
                    final isMe = data['senderId'] == _user.uid;

                    final bool deleted = data['deleted'] ?? false;
                    final String? text = deleted
                        ? 'This message was deleted'
                        : data['text'] ?? '';
                    final bool isImage = data['type'] == 'image';
                    final bool edited = data['edited'] ?? false;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: isMe
                            ? () {
                                _showMessageOptions(messageId, data);
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? const Color(0xffe1ffc7)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isImage && !deleted)
                                Image.network(
                                  data['imageUrl'],
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              if (!isImage)
                                Text(
                                  text ?? '',
                                  style: TextStyle(
                                    fontStyle: deleted
                                        ? FontStyle.italic
                                        : FontStyle.normal,
                                    color: deleted ? Colors.grey : Colors.black,
                                  ),
                                ),
                              if (edited && !deleted)
                                const Text(
                                  'edited',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.photo), onPressed: _sendImage),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: editingMessageId != null
                      ? "Edit your message..."
                      : "Type a message",
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (editingMessageId != null) {
      await ChatService.editMessage(
        chatId: _chatId,
        messageId: editingMessageId!,
        newText: text,
        receiverId: widget.artistId,
      );
      setState(() => editingMessageId = null);
    } else {
      await ChatService.sendMessage(
        receiverId: widget.artistId,
        receiverName: widget.artistName,
        receiverProfileUrl: widget.artistProfileUrl,
        text: text,
      );
    }
    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    File imageFile = File(picked.path);
    await ChatService.sendImage(
      receiverId: widget.artistId,
      receiverName: widget.artistName,
      receiverProfileUrl: widget.artistProfileUrl,
      imageFile: imageFile,
    );
  }

  void _showMessageOptions(String messageId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    editingMessageId = messageId;
                    _messageController.text = data['text'] ?? '';
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () async {
                  Navigator.pop(context);
                  await ChatService.deleteMessage(
                    chatId: _chatId,
                    messageId: messageId,
                    receiverId: widget.artistId,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
