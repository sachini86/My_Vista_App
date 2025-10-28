import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_vista/screens/ArtistChat/artist_chat.dart';

class ArtistChatList extends StatefulWidget {
  const ArtistChatList({super.key});

  @override
  State<ArtistChatList> createState() => _ArtistChatListState();
}

class _ArtistChatListState extends State<ArtistChatList> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Please log in.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Artist Chats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .collection('chats')
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading chats'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final chatId = chat.id;
              final data = chat.data() as Map<String, dynamic>;

              final otherUserName = data['otherUserName'] ?? 'Unknown User';
              final otherUserImage =
                  data['otherUserImage'] ??
                  'https://cdn-icons-png.flaticon.com/512/149/149071.png';
              final lastMessage = data['lastMessage'] ?? '';
              final lastMessageTime = (data['lastMessageTime'] as Timestamp?)
                  ?.toDate();

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(otherUserImage),
                ),
                title: Text(
                  otherUserName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: lastMessageTime != null
                    ? Text(
                        _formatTime(lastMessageTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistChatPage(
                        chatId: chatId,
                        otherUserId: data['otherUserId'],
                        otherUserName: otherUserName,
                        otherUserImage: otherUserImage,
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
    } else {
      return "${time.day}/${time.month}/${time.year}";
    }
  }
}
