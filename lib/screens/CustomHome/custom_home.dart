import 'package:flutter/material.dart';
import 'Widget/custom_add.dart';
import 'Widget/customsearch_bar.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int currentslide = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const CustomAppBar(),
              const SizedBox(height: 20),
              const CustomSearchBar(),
              const SizedBox(height: 20),
              CustomAdd(
                currentSlide: currentslide,
                onChange: (value) {
                  setState(() {
                    currentslide = value;
                  });
                },
              ),
              const SizedBox(height: 15),
              _categoryButtons(),
              const SizedBox(height: 25),
              _sectionTitle("Artists"),
              const SizedBox(height: 15),
              _artistsList(),
              const SizedBox(height: 30),
              _sectionTitle("Pick your one"),
              _artworksGrid(sampleTrendingArts),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(10),
          ),
          onPressed: () {},
          icon: const Icon(Icons.grid_view, size: 20, color: Colors.black),
        ),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: const EdgeInsets.all(10),
          ),
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_outlined,
            size: 20,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

// Category Buttons
Widget _categoryButtons() {
  final categories = [
    "Sculpture",
    "Paintings",
    "Drawings",
    "Photography",
    "Sculpture",
    "Drawings",
    "Paintings",
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

// Section title
Widget _sectionTitle(String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const Text("View all", style: TextStyle(color: Color(0xff930909))),
    ],
  );
}

// Artists List
Widget _artistsList() {
  final sampleArtists = [
    "https://randomuser.me/api/portraits/women/1.jpg",
    "https://randomuser.me/api/portraits/men/2.jpg",
    "https://randomuser.me/api/portraits/women/3.jpg",
    "https://randomuser.me/api/portraits/men/4.jpg",
    "https://randomuser.me/api/portraits/women/5.jpg",
  ];
  return SizedBox(
    height: 60,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: sampleArtists.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(sampleArtists[index]),
          ),
        );
      },
    ),
  );
}

// Artworks Grid
Widget _artworksGrid(List<Map<String, dynamic>> artworks) {
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
    ),
    itemCount: artworks.length,
    itemBuilder: (context, index) {
      final art = artworks[index];
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.asset(
                  art['imageUrl'],
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: Colors.black,
                    ),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 5),
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 18,
                      color: Colors.black,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    art['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    art['artist'],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "US\$ ${art['price']}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

// Sample trending arts
final sampleTrendingArts = [
  {
    'title': 'Blue Eye',
    'artist': 'John Doe',
    'imageUrl': 'assests/images/blue eye (1).jpg',
    'price': 250,
  },
  {
    'title': 'Sunset View',
    'artist': 'Jane Smith',
    'imageUrl': 'assests/images/man.jpg',
    'price': 300,
  },
  {
    'title': 'Ocean Waves',
    'artist': 'Michael Lee',
    'imageUrl': 'assests/images/river.jpg',
    'price': 150,
  },
  {
    'title': 'Golden Hour',
    'artist': 'Emily Davis',
    'imageUrl': 'assests/images/river.jpg',
    'price': 200,
  },
];
