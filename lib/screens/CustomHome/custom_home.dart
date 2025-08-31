// ============================
// lib/pages/home_page.dart
// ============================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_vista/screens/CustomHome/artworkdetail.dart';
import 'package:my_vista/screens/Customchat/notificationpage.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _searchController = TextEditingController();
  final _pageController = PageController(viewportFraction: .92);
  int _adIndex = 0;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff930909), // deep red
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.person, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _user != null
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(_user!.uid)
                          .snapshots()
                    : null,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Text(
                      'Hi, Guest',
                      style: TextStyle(color: Colors.white),
                    );
                  }

                  final username = snapshot.data!.data()?['name'] ?? 'Guest';
                  return Text(
                    'Hi, $username',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(_user!.uid)
                  .collection('messages')
                  .where('read', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = snapshot.hasData
                    ? snapshot.data!.docs.length
                    : 0;

                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationsPage(userId: _user!.uid),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildAdsCarousel()),
              SliverToBoxAdapter(child: const SizedBox(height: 8)),
              SliverToBoxAdapter(child: _buildTagSection()),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _sectionTitle('Artists')),
              SliverToBoxAdapter(child: _buildArtistStrip()),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _sectionTitle('Trending Arts')),
              _buildArtworkGrid(),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  // Search
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: const Color(0xFFF3F3F3),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (q) => setState(() {}),
      ),
    );
  }

  // Ads/featured carousel from artworks where featured == true
  Widget _buildAdsCarousel() {
    final q = _searchController.text.trim();
    return SizedBox(
      height: 160,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('artworks')
            .where('featured', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          final items = docs
              .where(
                (d) =>
                    q.isEmpty ||
                    (d['title'] as String).toLowerCase().contains(
                      q.toLowerCase(),
                    ),
              )
              .toList();
          if (items.isEmpty) {
            return _placeholderBanner();
          }
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _adIndex = i),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final data = items[i].data();
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              data['imageUrl'] ?? '',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFEDEDED),
                                alignment: Alignment.center,
                                child: const Text('Ad'),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  data['title'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  final active = i == _adIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 8 : 6,
                    height: active ? 8 : 6,
                    decoration: BoxDecoration(
                      color: active ? Colors.black87 : Colors.black26,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    );
  }

  Widget _placeholderBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 150,
          color: const Color(0xFFE9E9E9),
          alignment: Alignment.center,
          child: const Text('Ads'),
        ),
      ),
    );
  }

  // Tag section as images (collection: tags {label, imageUrl})
  Widget _buildTagSection() {
    return SizedBox(
      height: 56,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('tags')
            .orderBy('order', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          final tags = snapshot.data?.docs ?? [];
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final t = tags[i].data();
              return GestureDetector(
                onTap: () {
                  _searchController.text = t['label'] ?? '';
                  setState(() {});
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(t['imageUrl'] ?? ''),
                      backgroundColor: const Color(0xFFF0DADA),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (t['label'] ?? '').toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );
  }

  // Artists strip (collection: artists {displayName, photoUrl})
  Widget _buildArtistStrip() {
    return SizedBox(
      height: 98,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('artists')
            .orderBy('joinedAt', descending: true)
            .limit(25)
            .snapshots(),
        builder: (context, snapshot) {
          final artists = snapshot.data?.docs ?? [];
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final a = artists[i].data();
              final artistId = artists[i].id;
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => _onArtistTap(context, artistId, a),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundImage: NetworkImage(a['photoUrl'] ?? ''),
                      backgroundColor: const Color(0xFFF0DADA),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 70,
                    child: Text(
                      (a['displayName'] ?? 'Artist'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _onArtistTap(
    BuildContext context,
    String artistId,
    Map<String, dynamic> a,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(a['photoUrl'] ?? ''),
                  ),
                  title: Text(a['displayName'] ?? 'Artist'),
                  subtitle: Text(a['bio'] ?? ''),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat'),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Open chat (to implement)'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Follow'),
                        onPressed: () async {
                          if (_user == null) return;
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(_user!.uid)
                              .collection('following')
                              .doc(artistId)
                              .set({
                                'artistId': artistId,
                                'followedAt': FieldValue.serverTimestamp(),
                              });
                          if (context.mounted) Navigator.pop(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Following ${a['displayName'] ?? ''}',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Artworks list/grid
  SliverPadding _buildArtworkGrid() {
    final q = _searchController.text.trim().toLowerCase();
    final stream = FirebaseFirestore.instance
        .collection('artworks')
        .orderBy('createdAt', descending: true)
        .snapshots();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      sliver: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          final items = (snapshot.data?.docs ?? [])
              .where(
                (d) =>
                    q.isEmpty ||
                    (d['title'] as String).toLowerCase().contains(q) ||
                    (d['artistName'] as String? ?? '').toLowerCase().contains(
                      q,
                    ),
              )
              .toList();

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .72,
            ),
            delegate: SliverChildBuilderDelegate(childCount: items.length, (
              context,
              i,
            ) {
              final doc = items[i];
              final data = doc.data();
              return _ArtworkCard(
                artworkId: doc.id,
                data: data,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ArtworkDetailPage(artworkId: doc.id, data: data),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  const _ArtworkCard({
    required this.artworkId,
    required this.data,
    required this.onOpen,
  });

  final String artworkId;
  final Map<String, dynamic> data;
  final VoidCallback onOpen;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final price = (data['price'] ?? 0).toDouble();
    return GestureDetector(
      onTap: onOpen,
      child: Card(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.2,
              child: Image.network(data['imageUrl'] ?? '', fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data['title'] ?? 'Artwork',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () async {
                          if (_user == null) return;
                          final fav = FirebaseFirestore.instance
                              .collection('users')
                              .doc(_user!.uid)
                              .collection('favorites')
                              .doc(artworkId);
                          await fav.set({
                            'artworkId': artworkId,
                            'title': data['title'],
                            'artistName': data['artistName'],
                            'price': price,
                            'imageUrl': data['imageUrl'],
                            'addedAt': FieldValue.serverTimestamp(),
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to favorites'),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: () async {
                          if (_user == null) return;
                          final cart = FirebaseFirestore.instance
                              .collection('users')
                              .doc(_user!.uid)
                              .collection('cart')
                              .doc(artworkId);
                          await cart.set({
                            'artworkId': artworkId,
                            'title': data['title'],
                            'artistName': data['artistName'],
                            'price': price,
                            'imageUrl': data['imageUrl'],
                            'qty': FieldValue.increment(1),
                            'addedAt': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data['artistName'] ?? '',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'US\$ ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
