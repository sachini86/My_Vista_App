import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Universal chat page that works for both buyers and artists
class ArtistBuyerChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId; // The person we're chatting with
  final String otherUserName;
  final String otherUserImage;
  final String artworkTitle;

  const ArtistBuyerChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserImage = '',
    this.artworkTitle = '',
  });

  @override
  State<ArtistBuyerChatPage> createState() => _ArtistBuyerChatPageState();
}

class _ArtistBuyerChatPageState extends State<ArtistBuyerChatPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize chat document if it doesn't exist
  Future<void> _initializeChat() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final chatDoc = await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (!chatDoc.exists) {
        // Get current user's data
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() ?? {};

        // Create initial chat document
        await _firestore.collection('chats').doc(widget.chatId).set({
          'participants': [user.uid, widget.otherUserId],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastTimestamp': FieldValue.serverTimestamp(),
          'unreadCount_${user.uid}': 0,
          'unreadCount_${widget.otherUserId}': 0,
          'artworkTitle': widget.artworkTitle,
          'users': {
            user.uid: {
              'name': userData['name'] ?? user.displayName ?? 'User',
              'image': userData['profilePhoto'] ?? user.photoURL ?? '',
              'role': userData['role'] ?? 'Customer',
            },
            widget.otherUserId: {
              'name': widget.otherUserName,
              'image': widget.otherUserImage,
            },
          },
        });
      }
    } catch (e) {
      debugPrint('Error initializing chat: $e');
    }
  }

  /// Mark messages as read for current user
  Future<void> _markMessagesAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('chats').doc(widget.chatId).set({
        'lastRead_${user.uid}': FieldValue.serverTimestamp(),
        'unreadCount_${user.uid}': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Send text message
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final chatRef = _firestore.collection('chats').doc(widget.chatId);
    final messagesRef = chatRef.collection('messages');

    try {
      // Get current user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Update chat document
      await chatRef.set({
        'participants': [user.uid, widget.otherUserId],
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
        'artworkTitle': widget.artworkTitle,
        'users': {
          user.uid: {
            'name': userData['name'] ?? user.displayName ?? 'User',
            'image': userData['profilePhoto'] ?? user.photoURL ?? '',
            'role': userData['role'] ?? 'Customer',
          },
          widget.otherUserId: {
            'name': widget.otherUserName,
            'image': widget.otherUserImage,
          },
        },
      }, SetOptions(merge: true));

      // Add message
      await messagesRef.add({
        'senderId': user.uid,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending message: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to send message"),
          backgroundColor: const Color(0xff930909),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Upload image to Firebase Storage
  Future<String?> _uploadImage(File image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.chatId)
          .child('${user.uid}_$timestamp.jpg');

      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Send image message
  Future<void> _sendImageMessage(File image) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isUploading = true);

    try {
      final imageUrl = await _uploadImage(image);
      if (imageUrl == null) throw Exception('Failed to upload image');

      final chatRef = _firestore.collection('chats').doc(widget.chatId);
      final messagesRef = chatRef.collection('messages');

      await chatRef.set({
        'participants': [user.uid, widget.otherUserId],
        'lastMessage': '📷 Photo',
        'lastTimestamp': FieldValue.serverTimestamp(),
        'unreadCount_${widget.otherUserId}': FieldValue.increment(1),
        'artworkTitle': widget.artworkTitle,
      }, SetOptions(merge: true));

      await messagesRef.add({
        'senderId': user.uid,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'image',
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to send image"),
            backgroundColor: const Color(0xff930909),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Show image picker
  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Send Image',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  source: ImageSource.camera,
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  source: ImageSource.gallery,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 70,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        if (pickedFile != null) {
          await _sendImageMessage(File(pickedFile.path));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEEBEC6),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFEEBEC6)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: const Color(0xFF000000)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Delete message
  Future<void> _deleteMessage(
    String messageId,
    String messageType,
    String? imageUrl,
  ) async {
    try {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Message'),
          content: const Text('Are you sure you want to delete this message?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff930909),
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (shouldDelete != true) return;

      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (messageType == 'image' && imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint('Error deleting image: $e');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message deleted')));
    } catch (e) {
      debugPrint('Error deleting message: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Widget _buildMessageBubble({
    required String messageId,
    required String text,
    required bool isMe,
    required Timestamp? timestamp,
    String? imageUrl,
    required String type,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: isMe
          ? () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.delete,
                          color: Color(0xff930909),
                        ),
                        title: const Text(
                          'Delete Message',
                          style: TextStyle(color: Color(0xff930909)),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await _deleteMessage(messageId, type, imageUrl);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: type == 'image'
              ? const EdgeInsets.all(4)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
            minWidth: type == 'image' ? 200 : 0,
          ),
          decoration: BoxDecoration(
            color: isMe ? const Color(0x33B71C1C) : Colors.grey[300],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: isMe
                  ? const Radius.circular(16)
                  : const Radius.circular(4),
              bottomRight: isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (type == 'image' && imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.black54 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.black : Colors.black87,
                    fontSize: 15,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: isMe ? Colors.black54 : Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: widget.otherUserImage.isNotEmpty
                    ? NetworkImage(widget.otherUserImage)
                    : null,
                child: widget.otherUserImage.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Color(0xff930909),
                        size: 20,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.artworkTitle.isNotEmpty)
                    Text(
                      widget.artworkTitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0x33B71C1C),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Color(0xff930909),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          "No messages yet",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Start the conversation",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Auto scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final messageId = doc.id;
                    final text = data['text']?.toString() ?? '';
                    final imageUrl = data['imageUrl']?.toString();
                    final senderId = data['senderId']?.toString() ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final type = data['type']?.toString() ?? 'text';
                    final isMe = senderId == currentUser?.uid;

                    return Padding(
                      key: ValueKey(messageId),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _buildMessageBubble(
                        messageId: messageId,
                        text: text,
                        isMe: isMe,
                        timestamp: timestamp,
                        imageUrl: imageUrl,
                        type: type,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_isUploading)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const CircularProgressIndicator(strokeWidth: 2),
                  const SizedBox(width: 16),
                  Text(
                    'Uploading image...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showImagePicker,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0x33B71C1C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Color(0xff930909),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xff930909),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
