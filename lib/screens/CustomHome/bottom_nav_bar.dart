import 'package:flutter/material.dart';
import 'package:my_vista/screens/CustomHome/custom_home.dart';
import 'package:my_vista/screens/CustomHome/custom_favourite.dart';
import 'package:my_vista/screens/Customcart/custom_cart.dart';
import 'package:my_vista/screens/Customprofile/custom_profile.dart';
import 'package:my_vista/screens/Customchat/custom_chat.dart';

class RoundedBottomnavbar extends StatefulWidget {
  const RoundedBottomnavbar({super.key});

  @override
  State<RoundedBottomnavbar> createState() => _RoundedBottomnavbarState();
}

class _RoundedBottomnavbarState extends State<RoundedBottomnavbar> {
  int _currentIndex = 0;

  // List of screens
  final List<Widget> _screens = [
    const CustomerHomePage(),
    const CustomChat(artistId: "someArtistId", artistName: "Artist Name"),
    const CustomFavourite(),
    const CustomCart(),
    const CustomProfile(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex], // show current screen
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onTabTapped(0), // home
        shape: const CircleBorder(),
        backgroundColor: const Color(0xffC78A81),
        child: const Icon(Icons.home_outlined, size: 40, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
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
                  onPressed: () => _onTabTapped(1),
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 30,
                    color: _currentIndex == 1
                        ? const Color(0xff930909)
                        : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => _onTabTapped(2),
                  icon: Icon(
                    Icons.favorite_border,
                    size: 30,
                    color: _currentIndex == 2
                        ? const Color(0xff930909)
                        : Colors.black,
                  ),
                ),
                const SizedBox(width: 40), // gap for FAB
                IconButton(
                  onPressed: () => _onTabTapped(3),
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    size: 30,
                    color: _currentIndex == 3
                        ? const Color(0xff930909)
                        : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () => _onTabTapped(4),
                  icon: Icon(
                    Icons.person_outline,
                    size: 30,
                    color: _currentIndex == 4
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
