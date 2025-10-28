import 'package:flutter/material.dart';
import 'package:my_vista/screens/ArtistHome/artisthomepage.dart';
import 'package:my_vista/screens/BothChats/artistbuyer_chatlist.dart';
import 'package:my_vista/screens/ArtistOrders/artist_orders_temp.dart';
import 'package:my_vista/screens/ArtistProfile/artist_profile_temp.dart';
import 'package:my_vista/screens/ArtistHome/artistadd_product.dart';

class ArtistRoundedBottomNavbar extends StatefulWidget {
  const ArtistRoundedBottomNavbar({super.key});

  @override
  State<ArtistRoundedBottomNavbar> createState() =>
      _ArtistRoundedBottomNavbarState();
}

class _ArtistRoundedBottomNavbarState extends State<ArtistRoundedBottomNavbar> {
  int _currentIndex = 0;

  // List of screens for tabs
  final List<Widget> _screens = [
    const ArtistHomePage(),
    const ChatListPage(),
    const ArtistOrders(),
    const ArtistProfile(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens, // all pages stay alive
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.grey.shade300,
              onPressed: () {
                // Navigate to add new artwork page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProductDetailsPage1()),
                );
              },
              child: const Icon(Icons.add, color: Colors.black),
            )
          : null,
      bottomNavigationBar: SizedBox(
        height: 70, // reduced height
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.black54, // color of the border
                width: 1, // thickness of the border
              ),
            ),
          ),
          child: BottomAppBar(
            elevation: 1,
            color: Colors.white,
            shape: const CircularNotchedRectangle(),
            notchMargin: 10,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _onTabTapped(0),
                  icon: Icon(
                    Icons.home_outlined,
                    size: 30,
                    color: _currentIndex == 0
                        ? const Color(0xff930909)
                        : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => _onTabTapped(1),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 30,
                    color: _currentIndex == 1
                        ? const Color(0xff930909)
                        : Colors.black,
                  ),
                ),
                const SizedBox(width: 40), // gap for FAB
                IconButton(
                  onPressed: () => _onTabTapped(2),
                  icon: Icon(
                    Icons.receipt_long_outlined,
                    size: 30,
                    color: _currentIndex == 2
                        ? const Color(0xff930909)
                        : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => _onTabTapped(3),
                  icon: Icon(
                    Icons.person_outline,
                    size: 30,
                    color: _currentIndex == 3
                        ? const Color(0xff930909)
                        : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
