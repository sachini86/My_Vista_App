import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser!.uid;

  /// send text message
  Future<void> sendMessage({
    required String chatId,
    required String receiverId,
    required String message,
  }) async {
    final senderId = currentUserId;
    final messageRef = _firestore
        .collection('users')
        .doc(senderId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final data = {
      'messageId': messageRef.id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': message,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    };

    // save in both sender and receiver chat
    await messageRef.set(data);
    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageRef.id)
        .set(data);

    // update last message info
    await _firestore
        .collection('users')
        .doc(senderId)
        .collection('chats')
        .doc(chatId)
        .update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('chats')
        .doc(chatId)
        .update({
          'lastMessage': message,
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
  }

  /// send image message
  Future<void> sendImage({
    required String chatId,
    required String receiverId,
    required File imageFile,
  }) async {
    final senderId = currentUserId;
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child(
      'chat_images/$chatId/$fileName.jpg',
    );
    final uploadTask = await ref.putFile(imageFile);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    final messageRef = _firestore
        .collection('users')
        .doc(senderId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final data = {
      'messageId': messageRef.id,
      'senderId': senderId,
      'receiverId': receiverId,
      'imageUrl': imageUrl,
      'type': 'image',
      'timestamp': FieldValue.serverTimestamp(),
    };

    await messageRef.set(data);
    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageRef.id)
        .set(data);
  }

  /// edit message
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newText,
  }) async {
    await _firestore
        .collectionGroup('messages')
        .where('messageId', isEqualTo: messageId)
        .get()
        .then((snapshot) async {
          for (var doc in snapshot.docs) {
            await doc.reference.update({'text': newText, 'edited': true});
          }
        });
  }

  /// delete message
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  }) async {
    await _firestore
        .collectionGroup('messages')
        .where('messageId', isEqualTo: messageId)
        .get()
        .then((snapshot) async {
          for (var doc in snapshot.docs) {
            await doc.reference.delete();
          }
        });
  }
}
