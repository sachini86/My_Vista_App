import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_vista/screens/Customchat/custom_chat.dart';

class CustomChatList extends StatefulWidget {
  const CustomChatList({super.key});

  @override
  State<CustomChatList> createState() => _CustomChatListState();
}

class _CustomChatListState extends State<CustomChatList> {
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: const Color(0xff930909),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_user.uid)
            .collection('chats')
            .orderBy('lastMessageTime', descending: true)
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
              final chat = chats[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: chat['artistProfileUrl'] != null
                      ? NetworkImage(chat['artistProfileUrl'])
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: chat['artistProfileUrl'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(chat['artistName'] ?? "Artist"),
                subtitle: Text(
                  chat['lastMessage'] ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: chat['unreadCount'] != null && chat['unreadCount'] > 0
                    ? CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          chat['unreadCount'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomChat(
                        artistId: chat['artistId'],
                        artistName: chat['artistName'],
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
}
