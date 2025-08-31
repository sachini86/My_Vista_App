// ============================
// lib/pages/favorites_page.dart
// ============================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomFavourite extends StatelessWidget {
  const CustomFavourite({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: user == null
          ? const Center(child: Text('Sign in to view favorites'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final items = snapshot.data?.docs ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('No favorites yet'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = items[i].data();
                    return Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            d['imageUrl'] ?? '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(d['title'] ?? ''),
                        subtitle: Text(d['artistName'] ?? ''),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'US\$ ${(d['price'] ?? 0).toStringAsFixed(2)}',
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => items[i].reference.delete(),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
