import 'package:flutter/material.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned(
            top: 125,
            left: 50,
            right: 1,
            child: Container(
              alignment: Alignment.center,
              child: Image.asset(
                "assets/images/bcgrnd new pic.png",
                width: 500, // ✅ Correct path and name
                fit: BoxFit.cover,
              ), // Fills the screen
            ),
          ),

          // Foreground Content
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 1), //space if we needed
                Container(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    "assets/images/vist (2) (1).png",
                    width: 400,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
