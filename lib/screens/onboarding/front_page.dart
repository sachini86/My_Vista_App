import 'package:flutter/material.dart';

class FrontPage extends StatelessWidget {
  const FrontPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          "Assests/Images/784d3858-6179-48fc-9407-e4d259d36c22.png",
          fit: BoxFit.cover,
        ),
      ],
    );
  }
}
