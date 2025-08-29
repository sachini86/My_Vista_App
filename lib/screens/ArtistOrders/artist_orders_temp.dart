import 'package:flutter/material.dart';

class ArtistOrders extends StatelessWidget {
  const ArtistOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Artist Orders')),
      body: const Center(child: Text('View your orders here')),
    );
  }
}
