import 'package:flutter/material.dart';

class CustomChat extends StatefulWidget {
  const CustomChat({super.key});

  @override
  State<CustomChat> createState() => _CustomChatState();
}

class _CustomChatState extends State<CustomChat> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.blue);
  }
}
