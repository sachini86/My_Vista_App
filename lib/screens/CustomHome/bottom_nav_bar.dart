import 'package:flutter/material.dart';
import 'package:vista/screens/CustomHome/custom_favourite.dart';
import 'package:vista/screens/CustomHome/custom_home.dart';
import 'package:vista/screens/Customcart/custom_cart.dart';
import 'package:vista/screens/Customprofile/custom_profile.dart';
import 'package:vista/screens/Customchat/custom_chat.dart';

class RoundedBottomnavbar extends StatefulWidget {
  const RoundedBottomnavbar({super.key});

  @override
  State<RoundedBottomnavbar> createState() => _RoundedBottomnavbarState();
}

class _RoundedBottomnavbarState extends State<RoundedBottomnavbar> {
  int currentIndex = 2;
  List screens = const [
    Scaffold(),
    CustomFavourite(),
    CustomCart(),
    CustomProfile(),
    CustomerHomePage(),
    CustomChat(),
    Scaffold(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            currentIndex = 2;
          });
        },
        shape: const CircleBorder(),
        backgroundColor: Color(0xffC78A81),
        child: Icon(Icons.home_outlined, size: 40, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20), // top left corner
            topRight: Radius.circular(20), // top right corner
          ),
          border: Border.all(
            color: Colors.grey, // stroke color
            width: 1, // stroke width
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomAppBar(
            elevation: 1,
            height: 60,
            color: Colors.white,
            shape: const CircularNotchedRectangle(),
            notchMargin: 10,
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => currentIndex = 0);
                  },
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 30,
                    color: currentIndex == 0 ? Color(0xff930909) : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => currentIndex = 1);
                  },
                  icon: Icon(
                    Icons.favorite_border,
                    size: 30,
                    color: currentIndex == 1 ? Color(0xff930909) : Colors.black,
                  ),
                ),
                const SizedBox(width: 20), // middle gap for FAB if needed
                IconButton(
                  onPressed: () {
                    setState(() => currentIndex = 3);
                  },
                  icon: Icon(
                    Icons.shopping_cart_outlined,
                    size: 30,
                    color: currentIndex == 3 ? Color(0xff930909) : Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => currentIndex = 4);
                  },
                  icon: Icon(
                    Icons.person_outline,
                    size: 30,
                    color: currentIndex == 4 ? Color(0xff930909) : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: screens[currentIndex],
    );
  }
}
