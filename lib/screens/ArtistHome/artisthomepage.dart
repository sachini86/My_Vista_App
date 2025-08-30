import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ArtistHomePage extends StatefulWidget {
  const ArtistHomePage({super.key});

  @override
  State<ArtistHomePage> createState() => _ArtistHomePageState();
}

class _ArtistHomePageState extends State<ArtistHomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  late final CollectionReference artworksRef;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      artworksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('artworks');
    }
  }

  Future<void> _deleteArtwork(
    String docId,
    String? artworkUrl,
    BuildContext ctx,
  ) async {
    try {
      await artworksRef.doc(docId).delete();
      if (artworkUrl != null && artworkUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(artworkUrl).delete();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Artwork deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting artwork: $e')));
    }
  }

  Future<void> _editArtwork(
    String docId,
    Map<String, dynamic> currentData,
  ) async {
    final formKey = GlobalKey<FormState>();
    File? pickedImage;
    final Map<String, TextEditingController> controllers = {
      'title': TextEditingController(text: currentData['title']),
      'artistName': TextEditingController(text: currentData['artistName']),
      'category': TextEditingController(text: currentData['category']),
      'material': TextEditingController(text: currentData['material']),
      'style': TextEditingController(text: currentData['style']),
      'description': TextEditingController(text: currentData['description']),
      'height': TextEditingController(text: currentData['height']?.toString()),
      'width': TextEditingController(text: currentData['width']?.toString()),
      'depth': TextEditingController(text: currentData['depth']?.toString()),
      'price': TextEditingController(text: currentData['price']?.toString()),
      'discount': TextEditingController(
        text: currentData['discount']?.toString(),
      ),
      'quantity': TextEditingController(
        text: currentData['quantity']?.toString(),
      ),
      'shippingFee': TextEditingController(
        text: currentData['shippingFee']?.toString(),
      ),
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Edit Artwork',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Artwork Image
                GestureDetector(
                  onTap: () async {
                    final picked = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (picked != null) {
                      setState(() {
                        pickedImage = File(picked.path);
                      });
                    }
                  },
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      image: pickedImage != null
                          ? DecorationImage(
                              image: FileImage(pickedImage!),
                              fit: BoxFit.cover,
                            )
                          : (currentData['artworkUrl'] != null &&
                                    currentData['artworkUrl'].isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(
                                      currentData['artworkUrl'],
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                : null),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 50,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Text fields
                ...controllers.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextFormField(
                      controller: entry.value,
                      decoration: InputDecoration(
                        labelText: entry.key,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType:
                          (entry.key == 'height' ||
                              entry.key == 'width' ||
                              entry.key == 'depth' ||
                              entry.key == 'price' ||
                              entry.key == 'discount' ||
                              entry.key == 'quantity' ||
                              entry.key == 'shippingFee')
                          ? TextInputType.number
                          : TextInputType.text,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff930909),
                  ),
                  onPressed: () async {
                    Map<String, dynamic> updatedData = {};
                    controllers.forEach((key, controller) {
                      if (controller.text.isNotEmpty) {
                        if (key == 'height' ||
                            key == 'width' ||
                            key == 'depth' ||
                            key == 'price' ||
                            key == 'discount' ||
                            key == 'quantity' ||
                            key == 'shippingFee') {
                          updatedData[key] =
                              double.tryParse(controller.text) ?? 0;
                        } else {
                          updatedData[key] = controller.text;
                        }
                      }
                    });

                    try {
                      // Update image if picked
                      if (pickedImage != null) {
                        final storageRef = FirebaseStorage.instance.ref().child(
                          'artworks/${docId}_${DateTime.now().millisecondsSinceEpoch}',
                        );
                        final uploadTask = await storageRef.putFile(
                          pickedImage!,
                        );
                        final imageUrl = await uploadTask.ref.getDownloadURL();
                        updatedData['artworkUrl'] = imageUrl;

                        // Optionally delete old image
                        if (currentData['artworkUrl'] != null &&
                            currentData['artworkUrl'].isNotEmpty) {
                          try {
                            await FirebaseStorage.instance
                                .refFromURL(currentData['artworkUrl'])
                                .delete();
                          } catch (_) {}
                        }
                      }

                      await artworksRef.doc(docId).update(updatedData);
                      if (!mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Artwork updated successfully'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating artwork: $e')),
                      );
                    }
                  },
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: const Text(
          'My Uploaded Artworks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: artworksRef.snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artwork Image
                      if (data['artworkUrl'] != null &&
                          data['artworkUrl'].toString().isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            data['artworkUrl'],
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Artwork Details
                      Text(
                        data['title'] ?? 'Untitled',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("Artist: ${data['artistName'] ?? 'Unknown'}"),
                      Text("Category: ${data['category'] ?? 'N/A'}"),
                      Text("Material: ${data['material'] ?? 'N/A'}"),
                      Text("Style: ${data['style'] ?? 'N/A'}"),
                      const SizedBox(height: 4),
                      Text("Description: ${data['description'] ?? 'N/A'}"),
                      const SizedBox(height: 6),

                      // Dimensions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "H: ${data['height']?.toString() ?? '0'} ${data['heightUnit'] ?? 'cm'}",
                          ),
                          Text(
                            "W: ${data['width']?.toString() ?? '0'} ${data['widthUnit'] ?? 'cm'}",
                          ),
                          Text(
                            "D: ${data['depth']?.toString() ?? '0'} ${data['depthUnit'] ?? 'cm'}",
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Price & Other Info
                      Text(
                        "Price: ${data['price']?.toString() ?? '0'} ${data['currency'] ?? 'USD'}",
                      ),
                      Text("Discount: ${data['discount']?.toString() ?? '0'}%"),
                      Text("Quantity: ${data['quantity']?.toString() ?? '0'}"),
                      Text(
                        "Shipping Fee: ${data['shippingFee']?.toString() ?? '0'} ${data['currency'] ?? 'USD'}",
                      ),
                      const SizedBox(height: 8),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () => _editArtwork(doc.id, data),
                            icon: const Icon(
                              Icons.edit,
                              color: Color(0xff930909),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _deleteArtwork(
                              doc.id,
                              data['artworkUrl'],
                              context,
                            ),
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
