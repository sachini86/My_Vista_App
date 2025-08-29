import 'package:flutter/material.dart';

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
            padding: EdgeInsets.all(10),
          ),
          onPressed: () {},
          icon: const Icon(Icons.grid_view, size: 20, color: Colors.black),
        ),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[200],
            padding: EdgeInsets.all(10),
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
