import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_vista/screens/ArtistChat/artist_chat_page.dart';

class ArtistChatList extends StatelessWidget {
  const ArtistChatList({super.key});

  @override
  Widget build(BuildContext context) {
    final artistId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: const Text('My Chats', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: artistId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;
          if (chats.isEmpty) return const Center(child: Text('No chats yet'));

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants']);
              final buyerId = participants.firstWhere((id) => id != artistId);
              final lastMessage = chat['lastMessage'] ?? '';

              return FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(buyerId)
                    .get(),
                builder: (context, buyerSnapshot) {
                  if (!buyerSnapshot.hasData) return const SizedBox();

                  final buyerData = buyerSnapshot.data!.data() ?? {};
                  final buyerName = buyerData['name'] ?? 'Buyer';
                  final buyerImage = buyerData['profileImageUrl'];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: buyerImage != null
                          ? NetworkImage(buyerImage)
                          : null,
                      child: buyerImage == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(buyerName),
                    subtitle: Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArtistChat(
                            buyerId: buyerId,
                            buyerName: buyerName,
                          ),
                        ),
                      );
                    },
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
