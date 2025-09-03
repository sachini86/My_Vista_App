// ============================
// lib/pages/home_page.dart
// ============================
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:my_vista/screens/CustomHome/artworkdetail.dart';
import 'package:my_vista/screens/Customchat/notificationpage.dart';
import 'package:my_vista/screens/ArtistChat/artist_chat_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final _searchController = TextEditingController();
  final _pageController = PageController(viewportFraction: .92);
  final PageController _controller = PageController();
  int _currentIndex = 0; // <-- add this

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  SliverPadding _buildArtworkGrid(BuildContext context, User? user) {
    final q = _searchController.text.trim().toLowerCase();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      sliver: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collectionGroup('artworks')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          final items = snapshot.data?.docs ?? [];

          final filtered = items.where((doc) {
            final data = doc.data();
            final category = (data['category'] ?? '').toString().toLowerCase();
            return q.isEmpty || category.contains(q);
          }).toList();

          if (filtered.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(child: Text('No artworks found')),
            );
          }

          return SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: .69,
            ),
            delegate: SliverChildBuilderDelegate((context, i) {
              final doc = filtered[i];
              final data = doc.data();
              final price = (data['price'] ?? 0).toDouble();

              return ArtworkCard(
                artworkId: doc.id,
                data: data,
                user: user,
                price: price,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ArtworkDetailPage(artworkId: doc.id, data: data),
                  ),
                ),
              );
            }, childCount: filtered.length),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // rebuilds the UI whenever the search text changes
    });
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

            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _user != null
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .collection('notifications')
                        .where('read', isEqualTo: false)
                        .snapshots()
                  : null,
              builder: (context, snapshot) {
                int unreadCount = snapshot.data?.docs.length ?? 0;

                return Stack(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (_user == null) return;
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
              SliverToBoxAdapter(child: const SizedBox(height: 5)),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: _categoryButtons()),
              SliverToBoxAdapter(child: const SizedBox(height: 20)),
              SliverToBoxAdapter(child: buildCategoryScroll(context)),
              SliverToBoxAdapter(child: const SizedBox(height: 30)),
              SliverToBoxAdapter(child: _sectionTitle('Artists')),
              SliverToBoxAdapter(
                child: _buildArtistStrip(
                  context,
                  FirebaseAuth.instance.currentUser,
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: 12)),
              SliverToBoxAdapter(child: _sectionTitle('Pick your one')),
              _buildArtworkGrid(context, _user),
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
          hintText: 'Search by type',
          prefixIcon: _searchController.text.trim().isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    _searchController.clear(); // clear the search
                    FocusScope.of(context).unfocus(); // hide keyboard
                    setState(
                      () {},
                    ); // rebuild to hide back arrow // go back to previous page
                  },
                )
              : const Icon(Icons.search),
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
  // Replace _buildAdsCarousel() with this:

  final List<String> categories = [
    'assests/images/painting.jpg',
    'assests/images/sculpture.jpg',
    'assests/images/digital art.jpg',
    'assests/images/ceramic.jpg',
    'assests/images/photography.jpg',
    'assests/images/drawings.png',
    'assests/images/crafts.jpg',
  ];

  Widget buildCategoryScroll(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 200, // single fixed rectangle height
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Main rectangle with images
          PageView.builder(
            controller: _controller,
            itemCount: categories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(categories[index], fit: BoxFit.cover),
              );
            },
          ),

          // Circle indicators at bottom (inside the same rectangle)
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(categories.length, (i) {
                final isActive = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 10 : 6,
                  height: isActive ? 10 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Tag section as images (collection: tags {label, imageUrl})
// Category Buttons
Widget _categoryButtons() {
  final categories = [
    "Sculpture",
    "Painting",
    "Drawing & illustration",
    "Photography",
    "Craft & Textiles",
    "Digital Art",
    "Ceramic",
  ];
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: categories
          .map(
            (cat) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 1.2),
              ),
              child: Text(cat, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
    ),
  );
}

Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    ),
  );
}

// Artists strip (collection: artists {displayName, photoUrl})
Widget _buildArtistStrip(BuildContext context, User? currentUser) {
  return SizedBox(
    height: 98,
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'Artist')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final artists =
            snapshot.data?.docs.where((doc) {
              // Filter only users with role 'Artist', safely
              final role = doc.data()['role']?.toString();
              return role == 'Artist';
            }).toList() ??
            [];

        if (artists.isEmpty) {
          return const Center(child: Text('No artists found'));
        }

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: artists.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final artistDoc = artists[index];
            final artistData = artistDoc.data();
            final artistId = artistDoc.id;

            final profilePhoto =
                artistData['profilePhoto']?.toString().isNotEmpty == true
                ? artistData['profilePhoto'].toString()
                : ''; // placeholder

            final name = artistData['name']?.toString().isNotEmpty == true
                ? artistData['name'].toString()
                : 'Artist';

            return Column(
              children: [
                GestureDetector(
                  onTap: () {
                    _onArtistTap(context, currentUser, artistId, artistData);
                  },
                  child: CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(profilePhoto),
                    backgroundColor: const Color(0xFFF0DADA),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    name,
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
  User? currentUser,
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
                  backgroundImage:
                      (a['profilePhoto'] != null &&
                          a['profilePhoto'].toString().isNotEmpty)
                      ? NetworkImage(a['profilePhoto'])
                      : const AssetImage('assets/default_avatar.png')
                            as ImageProvider,
                ),
                title: Text(a['name'] ?? 'Artist'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                      onPressed: () {
                        if (currentUser == null) return;
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArtistChat(
                              buyerId: artistId,
                              buyerName: a['name'] ?? 'Artist',
                            ),
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
                        if (currentUser == null) return;
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.uid)
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
                                'Following ${a['name'] ?? 'Artist'}',
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
// Move this inside the _CustomerHomePageState class (optional, but cleaner)

class ArtworkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String artworkId;
  final User? user;
  final double? price;
  final VoidCallback onOpen;

  const ArtworkCard({
    super.key,
    required this.data,
    required this.artworkId,
    required this.user,
    required this.price,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final double price = (data['price'] ?? 0).toDouble();
    final String currency = data['currency'] ?? 'US\$';
    final String artistName = data['artistName'] ?? '';
    final String title = data['title'] ?? 'Artwork';

    return GestureDetector(
      onTap: onOpen,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Artwork image
            AspectRatio(
              aspectRatio: 1.4,
              child: Image.network(
                data['artworkUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),

            // Favorite & Cart Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.favorite_border, size: 22),
                    onPressed: () async {
                      if (user == null) return;
                      final fav = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('favorites')
                          .doc(artworkId);
                      await fav.set({
                        'artworkId': artworkId,
                        'title': title,
                        'artistName': artistName,
                        'price': price,
                        'currency': currency,
                        'artworkUrl': data['artworkUrl'],
                        'addedAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Added to favorites')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add_shopping_cart, size: 22),
                    onPressed: () async {
                      if (user == null) return;
                      final cart = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .collection('cart')
                          .doc(artworkId);
                      await cart.set({
                        'artworkId': artworkId,
                        'title': title,
                        'artistName': artistName,
                        'price': price,
                        'currency': currency,
                        'artworkUrl': data['artworkUrl'],
                        'quantity': FieldValue.increment(1),
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
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 1),

                  // Artist name
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),

                  // Price + currency
                  Text(
                    '$currency ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black,
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
