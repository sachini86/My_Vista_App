import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as path;
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// ---------------------------
/// Reusable Floating Upload UI
/// ---------------------------
class FloatingUploadField extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? child;
  final VoidCallback onTap;
  final bool hasValue;
  final Color accent;

  const FloatingUploadField({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.hasValue,
    this.child,
    this.accent = const Color(0xff930909),
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasValue ? accent : Colors.black;
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 2),
            ),
            child:
                child ??
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 40, color: borderColor),
                      const SizedBox(height: 10),
                      Text(
                        hasValue ? "Selected" : "Tap to upload",
                        style: TextStyle(
                          color: borderColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
        Positioned(
          left: 12,
          top: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: borderColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: borderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// ----------------------------------
/// PAGE 1: Product details + uploads
/// ----------------------------------
class ProductDetailsPage1 extends StatefulWidget {
  const ProductDetailsPage1({super.key});

  @override
  State<ProductDetailsPage1> createState() => _ProductDetailsPage1State();
}

class _ProductDetailsPage1State extends State<ProductDetailsPage1> {
  final _formKey = GlobalKey<FormState>();

  XFile? artworkImage;
  final List<XFile> additionalFiles = []; // images/videos

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final yearController = TextEditingController();

  final List<Map<String, dynamic>> sizes = [
    {"label": "Height", "value": "", "unit": "Inch"},
    {"label": "Width", "value": "", "unit": "Inch"},
    {"label": "Depth", "value": "", "unit": "Inch"},
  ];

  String? selectedCategory;
  String? selectedStyle;
  String? selectedMaterial;

  final List<String> categories = ["Painting", "Sculpture", "Digital Art"];
  final List<String> styles = ["Modern", "Abstract", "Classic"];
  final List<String> materials = ["Canvas", "Wood", "Metal", "Digital"];
  final List<String> units = ["Inch", "Cm"];

  final ImagePicker picker = ImagePicker();

  Future<void> pickArtwork() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => artworkImage = picked);
  }

  Future<void> pickAdditionalFiles() async {
    final pickedImages = await picker.pickMultiImage();
    final pickedVideo = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedImages.isNotEmpty) additionalFiles.addAll(pickedImages);
    if (pickedVideo != null) additionalFiles.add(pickedVideo);
    setState(() {});
  }

  Future<Uint8List?> getVideoThumbnail(String videoPath) async {
    return await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
  }

  bool get canProceed {
    final allSizeValuesFilled = sizes.every((s) {
      final v = (s["value"] ?? "").toString().trim();
      return v.isNotEmpty;
    });

    return artworkImage != null &&
        additionalFiles.isNotEmpty &&
        titleController.text.trim().isNotEmpty &&
        descController.text.trim().isNotEmpty &&
        selectedCategory != null &&
        selectedStyle != null &&
        selectedMaterial != null &&
        yearController.text.trim().isNotEmpty &&
        allSizeValuesFilled;
  }

  Widget _sizeRow(Map<String, dynamic> s) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(s["label"])),
          Expanded(
            flex: 3,
            child: TextFormField(
              onChanged: (val) => s["value"] = val.trim(),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Required" : null,
              decoration: const InputDecoration(
                labelText: "Value",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField(
              value: s["unit"],
              items: units
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (val) => setState(() => s["unit"] = val),
              decoration: const InputDecoration(
                labelText: "Unit",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _additionalFilesPreview() {
    if (additionalFiles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: additionalFiles.length,
        itemBuilder: (_, i) {
          final file = additionalFiles[i];
          final isVideo = [
            ".mp4",
            ".mov",
            ".m4v",
            ".avi",
          ].contains(path.extension(file.path).toLowerCase());
          return Container(
            margin: const EdgeInsets.all(8),
            width: 120,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff930909), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: isVideo
                  ? FutureBuilder<Uint8List?>(
                      future: getVideoThumbnail(file.path),
                      builder: (_, snap) {
                        if (snap.connectionState == ConnectionState.done &&
                            snap.data != null) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.memory(snap.data!, fit: BoxFit.cover),
                              const Icon(
                                Icons.play_circle_fill,
                                size: 40,
                                color: Colors.white,
                              ),
                            ],
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : Image.file(File(file.path), fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  void _goNext() {
    if (!_formKey.currentState!.validate()) return;
    if (!canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields.")),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsPage2(
          artworkImage: artworkImage!,
          additionalFiles: additionalFiles,
          title: titleController.text.trim(),
          description: descController.text.trim(),
          category: selectedCategory!,
          style: selectedStyle!,
          material: selectedMaterial!,
          sizes: sizes,
          year: yearController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xff930909);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        backgroundColor: red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              FloatingUploadField(
                label: "Upload Artwork",
                icon: Icons.image_outlined,
                hasValue: artworkImage != null,
                onTap: pickArtwork,
                child: artworkImage == null
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(artworkImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              FloatingUploadField(
                label: "Additional images/videos",
                icon: Icons.collections_outlined,
                hasValue: additionalFiles.isNotEmpty,
                onTap: pickAdditionalFiles,
                child: _additionalFilesPreview(),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: titleController,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Title is required"
                    : null,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: descController,
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Description is required"
                    : null,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                value: selectedCategory,
                validator: (v) => v == null ? "Select a category" : null,
                items: categories
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Style",
                  border: OutlineInputBorder(),
                ),
                value: selectedStyle,
                validator: (v) => v == null ? "Select a style" : null,
                items: styles
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedStyle = val),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Material Type",
                  border: OutlineInputBorder(),
                ),
                value: selectedMaterial,
                validator: (v) => v == null ? "Select a material" : null,
                items: materials
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedMaterial = val),
              ),
              const SizedBox(height: 16),

              Column(children: sizes.map(_sizeRow).toList()),
              const SizedBox(height: 16),

              TextFormField(
                controller: yearController,
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Year is required" : null,
                decoration: const InputDecoration(
                  labelText: "Year Created",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: canProceed ? _goNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Next", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------
/// PAGE 2: Pricing, NIC, Signature
/// ----------------------------------
class ProductDetailsPage2 extends StatefulWidget {
  final XFile artworkImage;
  final List<XFile> additionalFiles;
  final String title, description, year;
  final String category, style, material;
  final List<Map<String, dynamic>> sizes;

  const ProductDetailsPage2({
    super.key,
    required this.artworkImage,
    required this.additionalFiles,
    required this.title,
    required this.description,
    required this.category,
    required this.style,
    required this.material,
    required this.sizes,
    required this.year,
  });

  @override
  State<ProductDetailsPage2> createState() => _ProductDetailsPage2State();
}

class _ProductDetailsPage2State extends State<ProductDetailsPage2> {
  final _formKey = GlobalKey<FormState>();

  final priceController = TextEditingController();
  final discountController = TextEditingController(); // optional
  final qtyController = TextEditingController();
  final shippingController = TextEditingController();

  String? selectedCurrency = 'USD';

  XFile? nicFront;
  XFile? nicBack;

  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  Future<void> pickNICFront() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => nicFront = picked);
  }

  Future<void> pickNICBack() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => nicBack = picked);
  }

  Future<Uint8List> _buildPdfBytes({
    required Uint8List signatureBytes,
    Uint8List? artworkBytes,
  }) async {
    final pdf = pw.Document();
    final sig = pw.MemoryImage(signatureBytes);
    final logoRed = PdfColor.fromInt(0xff930909);

    pw.Widget productData(String k, String v) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              k,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(v)),
        ],
      ),
    );

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(
            base: await PdfGoogleFonts.robotoRegular(),
            bold: await PdfGoogleFonts.robotoBold(),
          ),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Artwork Declaration Letter',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: logoRed,
                ),
              ),
              pw.Text(
                DateTime.now().toIso8601String().substring(0, 19),
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),

          // Artwork preview (small)
          if (artworkBytes != null)
            pw.Center(
              child: pw.Container(
                width: 240,
                height: 160,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey700, width: 1),
                ),
                child: pw.Image(
                  pw.MemoryImage(artworkBytes),
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          if (artworkBytes != null) pw.SizedBox(height: 16),

          productData("Title", widget.title),
          productData("Description", widget.description),
          productData("Category", widget.category),
          productData("Style", widget.style),
          productData("Material", widget.material),
          productData("Year Created", widget.year),
          productData(
            "Sizes",
            widget.sizes
                .map((s) => "${s['label']}: ${s['value']} ${s['unit']}")
                .join(" | "),
          ),
          productData(
            "Price",
            "${priceController.text.trim()} ${selectedCurrency ?? ''}",
          ),
          productData(
            "Discount",
            (discountController.text.trim().isEmpty)
                ? "None"
                : discountController.text.trim(),
          ),
          productData("Quantity", qtyController.text.trim()),
          productData("Shipping Price", shippingController.text.trim()),

          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: logoRed, width: 1),
              borderRadius: pw.BorderRadius.circular(6),
              color: PdfColor.fromInt(0xFFFDF2F2),
            ),
            child: pw.Text(
              "I hereby certify that the information provided in this form is true and correct. "
              "I understand that providing any false, misleading, or fraudulent details may result "
              "in the rejection of my listing and I agree to accept any legal actions taken for such false submissions.",
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Digital Signature:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            width: 220,
            height: 100,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600, width: 1),
            ),
            child: pw.Image(sig, fit: pw.BoxFit.contain),
          ),
        ],
      ),
    );

    return pdf.save();
    // Caller will upload bytes and also pass to Preview page.
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate non-form requirements:
    if (nicFront == null || nicBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload NIC front and back.")),
      );
      return;
    }

    // Signature check
    final signatureBytes = await signatureController.toPngBytes();
    if (signatureBytes == null || signatureBytes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please provide your signature.")),
      );
      return;
    }
    if (!mounted) return;
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final storage = FirebaseStorage.instance;

      // Upload artwork
      final artRef = storage.ref(
        "artworks/${DateTime.now().millisecondsSinceEpoch}_${path.basename(widget.artworkImage.path)}",
      );
      await artRef.putFile(File(widget.artworkImage.path));
      final artworkUrl = await artRef.getDownloadURL();

      // Upload additional files
      final List<String> additionalUrls = [];
      for (final f in widget.additionalFiles) {
        final ref = storage.ref(
          "artworks/additional/${DateTime.now().millisecondsSinceEpoch}_${path.basename(f.path)}",
        );
        await ref.putFile(File(f.path));
        additionalUrls.add(await ref.getDownloadURL());
      }

      // Upload NIC
      final nicFrontRef = storage.ref(
        "kyc/nic_front_${DateTime.now().millisecondsSinceEpoch}${path.extension(nicFront!.path)}",
      );
      await nicFrontRef.putFile(File(nicFront!.path));
      final nicFrontUrl = await nicFrontRef.getDownloadURL();

      final nicBackRef = storage.ref(
        "kyc/nic_back_${DateTime.now().millisecondsSinceEpoch}${path.extension(nicBack!.path)}",
      );
      await nicBackRef.putFile(File(nicBack!.path));
      final nicBackUrl = await nicBackRef.getDownloadURL();

      // Upload Signature
      final signRef = storage.ref(
        "signatures/${DateTime.now().millisecondsSinceEpoch}.png",
      );
      await signRef.putData(
        signatureBytes,
        SettableMetadata(contentType: 'image/png'),
      );
      final signUrl = await signRef.getDownloadURL();

      // Prepare artwork bytes for PDF preview thumbnail
      Uint8List? artworkBytes;
      try {
        artworkBytes = await File(widget.artworkImage.path).readAsBytes();
      } catch (_) {}

      // Build PDF
      final pdfBytes = await _buildPdfBytes(
        signatureBytes: signatureBytes,
        artworkBytes: artworkBytes,
      );

      // Upload PDF
      final pdfRef = storage.ref(
        "letters/${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await pdfRef.putData(
        pdfBytes,
        SettableMetadata(contentType: 'application/pdf'),
      );
      final pdfUrl = await pdfRef.getDownloadURL();

      // Write Firestore
      final docRef = await FirebaseFirestore.instance
          .collection("products")
          .add({
            "title": widget.title,
            "description": widget.description,
            "category": widget.category,
            "style": widget.style,
            "material": widget.material,
            "sizes": widget.sizes,
            "year": widget.year,
            "price": priceController.text.trim(),
            "discount": discountController.text
                .trim(), // optional; may be empty
            "quantity": qtyController.text.trim(),
            "currency": selectedCurrency,
            "shipping": shippingController.text.trim(),

            "artworkUrl": artworkUrl,
            "additionalUrls": additionalUrls,
            "nicFrontUrl": nicFrontUrl,
            "nicBackUrl": nicBackUrl,
            "signatureUrl": signUrl,
            "pdfUrl": pdfUrl,

            "createdAt": FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      Navigator.of(context).pop(); // close loader

      // Success: go to preview page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PreviewLetterPage(
            docId: docRef.id,
            pdfBytes: pdfBytes,
            pdfUrl: pdfUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loader
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Submit failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xff930909);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Product Details (2/2)",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: red,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Price + currency
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? "Price required"
                          : null,
                      decoration: const InputDecoration(
                        labelText: "Price",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: selectedCurrency,
                      items: const ['USD', 'EUR', 'LKR', 'GBP']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCurrency = val),
                      decoration: const InputDecoration(
                        labelText: "Currency",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: discountController,
                keyboardType: TextInputType.number,
                // Optional, so no validator here
                decoration: const InputDecoration(
                  labelText: "Discount (Optional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Quantity required"
                    : null,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: shippingController,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Shipping price required"
                    : null,
                decoration: const InputDecoration(
                  labelText: "Shipping Price",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 18),

              // NIC uploads with floating labels
              FloatingUploadField(
                label: "NIC Front",
                icon: Icons.badge_outlined,
                hasValue: nicFront != null,
                onTap: pickNICFront,
                child: nicFront == null
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(nicFront!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              FloatingUploadField(
                label: "NIC Back",
                icon: Icons.badge_outlined,
                hasValue: nicBack != null,
                onTap: pickNICBack,
                child: nicBack == null
                    ? null
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(nicBack!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 18),

              // Confirmation text
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Declaration",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "I hereby certify that the information provided is true and correct. "
                "If I submit false details, I agree to accept any legal actions.",
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),

              // Signature pad
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Digital Signature",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Signature(
                  controller: signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => signatureController.clear(),
                    child: const Text("Clear"),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info: PDF field (auto)
              const SizedBox(height: 18),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _submit,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: red,
                    side: const BorderSide(color: red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Submit & Generate Letter",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------
/// PAGE 3: PDF Preview + Download
/// ----------------------------------
class PreviewLetterPage extends StatelessWidget {
  final String docId;
  final Uint8List pdfBytes; // already generated in Page 2
  final String pdfUrl; // stored in Firestore/Storage for record

  const PreviewLetterPage({
    super.key,
    required this.docId,
    required this.pdfBytes,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    const red = Color(0xff930909);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Preview Letter",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              // Disable changes; we just preview the generated file.
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: true,
              allowSharing: true,
              build: (format) async => pdfBytes,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // Let user save/share the PDF
                        await Printing.sharePdf(
                          bytes: pdfBytes,
                          filename: "artwork_declaration_$docId.pdf",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      icon: const Icon(Icons.download),
                      label: const Text("Download / Share"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
