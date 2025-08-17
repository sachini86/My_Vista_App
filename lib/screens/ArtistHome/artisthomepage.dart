import 'package:flutter/material.dart';

class Artisthomepage extends StatelessWidget {
  const Artisthomepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Artist Home")),
      body: Center(child: const Text("Welcome to the Artist Home Page!")),
    );
  }
}
