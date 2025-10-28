import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_vista/screens/BothChats/artistbuyer_chatpage.dart'; // Import the unified chat page

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Messages'),
          backgroundColor: const Color(0xff930909),
        ),
        body: const Center(child: Text('Please log in to view messages')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff930909),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .orderBy('lastTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
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
                  const SizedBox(height: 20),
                  const Text(
                    'No conversations yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start chatting with artists or buyers',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300], indent: 80),
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final chatId = chatDoc.id;

              // Get the other user's info
              final participants = List<String>.from(
                chatData['participants'] ?? [],
              );
              final otherUserId = participants.firstWhere(
                (id) => id != currentUser.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              // Get other user's data from the chat document
              final users = chatData['users'] as Map<String, dynamic>? ?? {};
              final otherUserData =
                  users[otherUserId] as Map<String, dynamic>? ?? {};

              final otherUserName =
                  otherUserData['name']?.toString() ?? 'Unknown';
              final otherUserImage = otherUserData['image']?.toString() ?? '';
              final lastMessage =
                  chatData['lastMessage']?.toString() ?? 'No messages yet';
              final lastTimestamp = chatData['lastTimestamp'] as Timestamp?;
              final artworkTitle = chatData['artworkTitle']?.toString() ?? '';
              final unreadCount =
                  chatData['unreadCount_${currentUser.uid}'] ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xff930909),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: otherUserImage.isNotEmpty
                            ? NetworkImage(otherUserImage)
                            : null,
                        child: otherUserImage.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Color(0xff930909),
                                size: 28,
                              )
                            : null,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xff930909),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherUserName,
                        style: TextStyle(
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lastTimestamp != null)
                      Text(
                        _formatTimestamp(lastTimestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: unreadCount > 0
                              ? const Color(0xff930909)
                              : Colors.grey[600],
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (artworkTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        artworkTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff930909),
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: unreadCount > 0
                            ? Colors.black87
                            : Colors.grey[600],
                        fontWeight: unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistBuyerChatPage(
                        chatId: chatId,
                        otherUserId: otherUserId,
                        otherUserName: otherUserName,
                        otherUserImage: otherUserImage,
                        artworkTitle: artworkTitle,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inDays == 0) {
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $ampm';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }
}
