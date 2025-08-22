import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductDetailPage2 extends StatefulWidget {
  final XFile artwork;
  final List<XFile> additionalFiles;
  final String title;
  final String artistName;
  final String description;
  final String category;
  final String style;
  final String material;
  final Map<String, dynamic> sizes;
  final String yearCreated;

  const ProductDetailPage2({
    super.key,
    required this.artwork,
    required this.additionalFiles,
    required this.title,
    required this.artistName,
    required this.description,
    required this.category,
    required this.style,
    required this.material,
    required this.sizes,
    required this.yearCreated,
  });

  @override
  State<ProductDetailPage2> createState() => _ProductDetailPage2State();
}

class _ProductDetailPage2State extends State<ProductDetailPage2> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  Future<String> _uploadFile(XFile file, String folder) async {
    File f = File(file.path);
    final ref = FirebaseStorage.instance.ref('$folder/${file.name}');
    await ref.putFile(f);
    return await ref.getDownloadURL();
  }

  Future<void> _submitAll() async {
    // Upload main artwork
    String artworkUrl = await _uploadFile(widget.artwork, 'artworks');

    // Upload additional files
    List<String> additionalUrls = [];
    for (var file in widget.additionalFiles) {
      String url = await _uploadFile(file, 'artworks_additional');
      additionalUrls.add(url);
    }

    // Save everything to Firestore
    await FirebaseFirestore.instance.collection('artworks').add({
      'title': widget.title,
      'artistName': widget.artistName,
      'description': widget.description,
      'category': widget.category,
      'style': widget.style,
      'material': widget.material,
      'size': widget.sizes,
      'yearCreated': widget.yearCreated,
      'price': _priceController.text,
      'tags': _tagsController.text,
      'artworkUrl': artworkUrl,
      'additionalFiles': additionalUrls,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artwork submitted successfully!')),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Additional Details'),
        backgroundColor: const Color(0xff930909),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff930909),
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
