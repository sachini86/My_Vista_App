import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "VistA",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: "Nonile"),
      home: Scaffold(
        backgroundColor: Color(0xFFEDEDEB),
        body: Container(child: Column(children: [])),
      ),
    );
  }
}
