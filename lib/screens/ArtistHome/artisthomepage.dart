import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArtistHomePage extends StatefulWidget {
  const ArtistHomePage({super.key});

  @override
  State<ArtistHomePage> createState() => _ArtistHomePageState();
}

class _ArtistHomePageState extends State<ArtistHomePage> {
  final userId = FirebaseAuth.instance.currentUser!.uid;
  final CollectionReference artworksRef = FirebaseFirestore.instance.collection(
    'artworks',
  );

  // Delete artwork
  Future<void> _deleteArtwork(String docId) async {
    await artworksRef.doc(docId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artwork deleted successfully')),
    );
  }

  // Edit artwork
  Future<void> _editArtwork(
    String docId,
    Map<String, dynamic> currentData,
  ) async {
    // Controllers for each field
    TextEditingController titleController = TextEditingController(
      text: currentData['title'],
    );
    TextEditingController artistController = TextEditingController(
      text: currentData['artistName'],
    );
    TextEditingController categoryController = TextEditingController(
      text: currentData['category'],
    );
    TextEditingController materialController = TextEditingController(
      text: currentData['material'],
    );
    TextEditingController descriptionController = TextEditingController(
      text: currentData['description'],
    );
    TextEditingController styleController = TextEditingController(
      text: currentData['style'],
    );
    TextEditingController heightController = TextEditingController(
      text: currentData['height'],
    );
    TextEditingController widthController = TextEditingController(
      text: currentData['width'],
    );
    TextEditingController depthController = TextEditingController(
      text: currentData['depth'],
    );
    TextEditingController priceController = TextEditingController(
      text: currentData['price']?.toString(),
    );
    TextEditingController discountController = TextEditingController(
      text: currentData['discount']?.toString(),
    );
    TextEditingController quantityController = TextEditingController(
      text: currentData['quantity']?.toString(),
    );
    TextEditingController shippingFeeController = TextEditingController(
      text: currentData['shippingFee']?.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Artwork'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(titleController, 'Title'),
              _buildTextField(artistController, 'Artist Name'),
              _buildTextField(categoryController, 'Category'),
              _buildTextField(materialController, 'Material'),
              _buildTextField(descriptionController, 'Description'),
              _buildTextField(styleController, 'Style'),
              _buildTextField(heightController, 'Height'),
              _buildTextField(widthController, 'Width'),
              _buildTextField(depthController, 'Depth'),
              _buildTextField(priceController, 'Price', isNumber: true),
              _buildTextField(
                discountController,
                'Discount (%)',
                isNumber: true,
              ),
              _buildTextField(quantityController, 'Quantity', isNumber: true),
              _buildTextField(
                shippingFeeController,
                'Shipping Fee',
                isNumber: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await artworksRef.doc(docId).update({
                'title': titleController.text,
                'artistName': artistController.text,
                'category': categoryController.text,
                'material': materialController.text,
                'description': descriptionController.text,
                'style': styleController.text,
                'height': heightController.text,
                'width': widthController.text,
                'depth': depthController.text,
                'price': double.tryParse(priceController.text) ?? 0,
                'discount': double.tryParse(discountController.text) ?? 0,
                'quantity': int.tryParse(quantityController.text) ?? 0,
                'shippingFee': double.tryParse(shippingFeeController.text) ?? 0,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Artwork updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Reusable text field builder
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: const Text(
          'My Uploaded Works',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: artworksRef.where('artistId', isEqualTo: userId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No artworks uploaded yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey[300], // Light grey background
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artwork Image
                      if (data['artworkUrl'] != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['artworkUrl'],
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),

                      const SizedBox(width: 15),

                      // Artwork Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("Artist: ${data['artistName'] ?? 'Unknown'}"),
                            Text("Category: ${data['category'] ?? 'N/A'}"),
                            Text("Material: ${data['material'] ?? 'N/A'}"),
                            Text(
                              "Description: ${data['description'] ?? 'N/A'}",
                            ),
                            Text("Style: ${data['style'] ?? 'N/A'}"),

                            // Dimensions
                            Text("Height: ${data['height'] ?? 'N/A'}"),
                            Text("Width: ${data['width'] ?? 'N/A'}"),
                            Text("Depth: ${data['depth'] ?? 'N/A'}"),

                            // Price and others
                            Text("Price: \$${(data['price'] ?? 0).toString()}"),
                            Text(
                              "Discount: ${(data['discount'] ?? 0).toString()}%",
                            ),
                            Text(
                              "Quantity: ${(data['quantity'] ?? 0).toString()}",
                            ),
                            Text(
                              "Shipping Fee: \$${(data['shippingFee'] ?? 0).toString()}",
                            ),
                          ],
                        ),
                      ),

                      // Edit & Delete Buttons
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _editArtwork(doc.id, data),
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xff930909),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteArtwork(doc.id),
                            icon: const Icon(
                              Icons.delete,
                              color: Color(0xff930909),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
