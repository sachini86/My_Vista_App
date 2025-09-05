import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:my_vista/screens/ArtistHome/productdetails2.dart';

class ProductDetailsPage1 extends StatefulWidget {
  const ProductDetailsPage1({super.key});

  @override
  State<ProductDetailsPage1> createState() => _ProductDetailsPage1State();
}

class _ProductDetailsPage1State extends State<ProductDetailsPage1> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _depthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  // Dropdown values
  String? _selectedCategory;
  String? _selectedStyle;
  String? _selectedMaterial;
  String? _heightUnit = 'cm';
  String? _widthUnit = 'cm';
  String? _depthUnit = 'cm';
  String? existingProfileUrl;

  // Files
  XFile? _artwork;
  XFile? _profilePhoto;
  final List<XFile> _additionalFiles = [];
  final List<File> _thumbnails = [];

  final ImagePicker _picker = ImagePicker();

  // Pick main artwork
  Future<void> _pickArtwork() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _artwork = picked);
  }

  // Pick profile photo
  Future<void> _pickProfilePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _profilePhoto = picked);
  }

  // Pick additional images
  Future<void> _pickAdditionalFiles() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) {
      for (var file in picked) {
        _additionalFiles.add(file);
        _thumbnails.add(File(file.path));
      }
      setState(() {});
    }
  }

  // Pick video and generate thumbnail
  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      _additionalFiles.add(picked);
      final thumb = await VideoThumbnail.thumbnailFile(
        video: picked.path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 150,
        quality: 75,
      );
      if (thumb != null) _thumbnails.add(File(thumb));
      setState(() {});
    }
  }

  // Submit: validate and navigate
  void _submit() {
    if (!_formKey.currentState!.validate() || _artwork == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage2(
          artwork: _artwork!,
          additionalFiles: _additionalFiles,
          title: _titleController.text,
          artistName: _artistController.text,
          description: _descriptionController.text,
          category: _selectedCategory ?? '',
          style: _selectedStyle ?? '',
          material: _selectedMaterial ?? '',
          sizes: {
            'height': {'value': _heightController.text, 'unit': _heightUnit},
            'width': {'value': _widthController.text, 'unit': _widthUnit},
            'depth': {'value': _depthController.text, 'unit': _depthUnit},
          },
          yearCreated: _yearController.text,
          profilePhotoFile: _profilePhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff930909),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _profilePhoto != null
                          ? FileImage(File(_profilePhoto!.path))
                          : null,
                      child: _profilePhoto == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: () => _profilePhoto == null
                            ? _pickProfilePhoto()
                            : setState(() => _profilePhoto = null),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black,
                          child: Icon(
                            _profilePhoto == null
                                ? Icons.add_a_photo
                                : Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Artwork upload
              _buildUploadField(
                label: 'Upload Artwork',
                requiredField: true,
                file: _artwork,
                onTap: _pickArtwork,
              ),
              const SizedBox(height: 16),

              // Additional files
              _buildUploadField(
                label: 'Additional Images/Videos (optional)',
                thumbnails: _thumbnails,
                files: _additionalFiles,
                onTap: _showPickOptions,
              ),
              const SizedBox(height: 16),

              // Text fields
              _buildTextField(_titleController, 'Artwork Title'),
              const SizedBox(height: 12),
              _buildTextField(_artistController, 'Artist Name'),
              const SizedBox(height: 12),
              _buildTextField(
                _descriptionController,
                'Description',
                maxLines: 5,
              ),
              const SizedBox(height: 12),

              // Dropdowns
              _buildDropdown(
                [
                  'Painting',
                  'Sculpture',
                  'Digital Art',
                  'Ceramic',
                  'Photography',
                  'Drawings & illustration',
                  'Craft & Textiles',
                ],
                'Category',
                _selectedCategory,
                (val) => setState(() => _selectedCategory = val),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                [
                  'Modern',
                  'Classic',
                  'Abstract',
                  'Pop Art',
                  'Surrealism',
                  'Minimalism',
                ],
                'Style',
                _selectedStyle,
                (val) => setState(() => _selectedStyle = val),
              ),
              const SizedBox(height: 12),
              _buildDropdown(
                [
                  'Canvas',
                  'Paper',
                  'Wood',
                  'Metal',
                  'Glass',
                  'Fabric',
                  'Ceramic/Clay',
                  'Stone',
                  'Mixed media',
                ],
                'Material',
                _selectedMaterial,
                (val) => setState(() => _selectedMaterial = val),
              ),
              const SizedBox(height: 12),

              // Year
              _buildTextField(
                _yearController,
                'Year Created',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 5),
              _buildDimensionsField(),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff930909),
                  minimumSize: const Size(150, 40),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------- Helper Widgets --------------------

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      height: label == 'Description' ? 150 : 70,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: (val) {
          if (val == null || val.isEmpty) return 'Required';
          if (label == 'Year Created') {
            final number = int.tryParse(val);
            final currentYear = DateTime.now().year;
            if (number == null) return 'Enter a valid year';
            if (number < 0) return 'Year cannot be negative';
            if (val.length != 4) return 'Enter valid year';
            if (number > currentYear) return 'Year cannot exceed $currentYear';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          floatingLabelStyle: const TextStyle(color: Color(0xff930909)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff930909)),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String label,
    String? value,
    Function(String?) onChanged,
  ) {
    return SizedBox(
      height: 55,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black, fontSize: 16),
          floatingLabelStyle: const TextStyle(color: Color(0xff930909)),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xff930909)),
          ),
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            onChanged: onChanged,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDimensionsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Dimensions",
          style: TextStyle(fontSize: 16, color: Colors.black),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _dimensionInput(
                controller: _heightController,
                label: "Height",
                unit: _heightUnit,
                onUnitChanged: (u) => setState(() => _heightUnit = u),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dimensionInput(
                controller: _widthController,
                label: "Width",
                unit: _widthUnit,
                onUnitChanged: (u) => setState(() => _widthUnit = u),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _dimensionInput(
                controller: _depthController,
                label: "Depth",
                unit: _depthUnit,
                onUnitChanged: (u) => setState(() => _depthUnit = u),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dimensionInput({
    required TextEditingController controller,
    required String label,
    required String? unit,
    required Function(String?) onUnitChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      validator: (val) {
        if (val == null || val.isEmpty) return 'Required';
        final num? number = num.tryParse(val);
        if (number == null || number <= 0) return 'Enter positive';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        floatingLabelStyle: const TextStyle(color: Color(0xff930909)),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xff930909)),
        ),
        suffixIcon: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: unit,
            onChanged: onUnitChanged,
            items: const [
              DropdownMenuItem(value: 'cm', child: Text('cm')),
              DropdownMenuItem(value: 'inch', child: Text('inch')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadField({
    required String label,
    bool requiredField = false,
    XFile? file,
    List<XFile>? files,
    List<File>? thumbnails,
    required VoidCallback onTap,
  }) {
    if (file != null) {
      return Stack(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.file(
              File(file.path),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: const Color(0xff930909),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                onPressed: () {
                  setState(() {
                    if (file == _artwork) _artwork = null;
                    if (file == _profilePhoto) _profilePhoto = null;
                  });
                },
              ),
            ),
          ),
        ],
      );
    } else if (thumbnails != null && thumbnails.isNotEmpty) {
      return SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: thumbnails.length + 1,
          itemBuilder: (context, index) {
            if (index == thumbnails.length) {
              return GestureDetector(
                onTap: onTap,
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.add, size: 40)),
                ),
              );
            }
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.file(
                    thumbnails[index],
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xff930909),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                      onPressed: () {
                        setState(() {
                          _additionalFiles.removeAt(index);
                          _thumbnails.removeAt(index);
                        });
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo, size: 50),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.black)),
            ],
          ),
        ),
      );
    }
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 120,
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Pick Images'),
              onTap: () {
                Navigator.pop(context);
                _pickAdditionalFiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Pick Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
          ],
        ),
      ),
    );
  }
}
