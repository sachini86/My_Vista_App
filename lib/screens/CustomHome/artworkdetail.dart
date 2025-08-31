// ============================
// lib/pages/artwork_detail_page.dart
// ============================
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArtworkDetailPage extends StatelessWidget {
  const ArtworkDetailPage({
    super.key,
    required this.artworkId,
    required this.data,
  });

  final String artworkId;
  final Map<String, dynamic> data;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final price = (data['price'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(data['title'] ?? 'Artwork')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Image.network(data['imageUrl'] ?? '', fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Artwork',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data['artistName'] ?? '',
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'US\$ ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data['description'] ?? 'No description',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.favorite_border),
                label: const Text('Favorite'),
                onPressed: () async {
                  if (_user == null) return;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .collection('favorites')
                      .doc(artworkId)
                      .set({
                        'artworkId': artworkId,
                        'title': data['title'],
                        'artistName': data['artistName'],
                        'price': price,
                        'imageUrl': data['imageUrl'],
                        'addedAt': FieldValue.serverTimestamp(),
                      });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
                onPressed: () async {
                  if (_user == null) return;
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user!.uid)
                      .collection('cart')
                      .doc(artworkId)
                      .set({
                        'artworkId': artworkId,
                        'title': data['title'],
                        'artistName': data['artistName'],
                        'price': price,
                        'imageUrl': data['imageUrl'],
                        'qty': FieldValue.increment(1),
                        'addedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
