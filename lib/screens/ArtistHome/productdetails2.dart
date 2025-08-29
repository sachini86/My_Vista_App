import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_saver/file_saver.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:signature/signature.dart';
import 'dart:developer';

/// ---------------------------------------------------------------------------
/// FULL FILE:
/// - Robust Firebase Storage uploads (with retries & contentType)
/// - One-time digital signature per user (re-used for future products)
/// - Signature auto-inserted into agreement PDF
/// - No signature pad shown once user already has a signature
/// - Clear error handling for the `StorageException Code: -13040` case
/// ---------------------------------------------------------------------------

class ProductDetailPage2 extends StatefulWidget {
  final String? profilePhotoUrl;
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
    this.profilePhotoUrl,
  });

  @override
  State<ProductDetailPage2> createState() => _ProductDetailPage2State();
}

class _ProductDetailPage2State extends State<ProductDetailPage2> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();

  final FocusNode _quantityFocus = FocusNode();

  String _selectedCurrency = 'USD';
  bool _agreeLegal = false;

  XFile? _nicFront;
  XFile? _nicBack;

  final _picker = ImagePicker();
  final _signatureKey = GlobalKey<SignatureState>();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final Color _labelColor = Colors.black;
  final Color _focusColor = const Color(0xff930909);

  /// Tracks if the user already has an uploaded signature.
  /// If non-null, we will NOT show the signature pad and reuse this URL.
  String? _existingSignatureUrl;
  bool _checkingSignature = true;

  @override
  void initState() {
    super.initState();
    _quantityFocus.addListener(() => setState(() {}));
    _checkExistingSignature();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _discountController.dispose();
    _quantityController.dispose();
    _shippingController.dispose();
    _quantityFocus.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  /// -------------------------------------------------------------------------
  /// STORAGE HELPERS
  /// -------------------------------------------------------------------------

  /// Returns a content type based on the file extension; defaults to octet-stream.
  String _guessContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
  }

  /// Robust upload with retries to mitigate transient cancellations (-13040).
  Future<String> _uploadFileWithRetry({
    required File file,
    required String storagePath,
    required String contentType,
    int maxRetries = 3,
  }) async {
    final ref = FirebaseStorage.instance.ref().child(storagePath);

    int attempt = 0;
    int delayMs = 600; // initial backoff

    while (true) {
      try {
        final task = await ref.putFile(
          file,
          SettableMetadata(contentType: contentType),
        );
        final url = await task.ref.getDownloadURL();
        return url;
      } on FirebaseException catch (e) {
        // If operation was canceled or network hiccup, we retry.
        final isCancellableIssue =
            e.code == 'canceled' ||
            e.code == 'unknown' ||
            e.code == 'retry-limit-exceeded';
        if (attempt < maxRetries && isCancellableIssue) {
          await Future.delayed(Duration(milliseconds: delayMs));
          attempt += 1;
          delayMs *= 2;
          continue;
        }
        rethrow;
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Uploads an XFile into /{folder}/{uid}/{timestamp_originalName}
  Future<String> _uploadXFile(XFile xfile, String folder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final file = File(xfile.path);
    if (!await file.exists()) {
      throw Exception('File does not exist: ${xfile.path}');
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final safeName = xfile.name.replaceAll(' ', '_');
    final storagePath = '$folder/${user.uid}/${ts}_$safeName';
    final contentType = _guessContentType(xfile.path);

    return _uploadFileWithRetry(
      file: file,
      storagePath: storagePath,
      contentType: contentType,
    );
  }

  /// Check if a signature already exists for this user by consulting Firestore
  /// at `signatures/{uid}`. If present, store its URL so we can reuse it.
  Future<void> _checkExistingSignature() async {
    setState(() => _checkingSignature = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _existingSignatureUrl = null;
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('signatures')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        _existingSignatureUrl = doc.data()?["url"] as String?;
      } else {
        _existingSignatureUrl = null;
      }
    } catch (_) {
      _existingSignatureUrl = null;
    } finally {
      if (mounted) setState(() => _checkingSignature = false);
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        if (isFront) {
          _nicFront = picked;
        } else {
          _nicBack = picked;
        }
      });
    }
  }

  Future<void> _submitAll() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeLegal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to legal terms')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      log("❌ User not signed in");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not signed in')));
      return;
    }

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      log("➡️ Uploading main artwork...");
      late String artworkUrl;
      try {
        artworkUrl = await _uploadXFile(widget.artwork, 'artworks');
        log("✅ Artwork uploaded: $artworkUrl");
      } catch (e) {
        log("❌ Failed to upload artwork: $e");
        rethrow;
      }

      // Upload additional files
      final additionalUrls = <String>[];
      for (final file in widget.additionalFiles) {
        try {
          final url = await _uploadXFile(file, 'artworks_additional');
          additionalUrls.add(url);
          log("✅ Additional file uploaded: $url");
        } catch (e) {
          log("❌ Failed to upload additional file ${file.name}: $e");
        }
      }

      // Upload NIC images (optional)
      String? nicFrontUrl;
      String? nicBackUrl;
      if (_nicFront != null) {
        try {
          nicFrontUrl = await _uploadXFile(_nicFront!, 'nic');
          log("✅ NIC Front uploaded: $nicFrontUrl");
        } catch (e) {
          log("❌ NIC Front upload failed: $e");
        }
      }
      if (_nicBack != null) {
        try {
          nicBackUrl = await _uploadXFile(_nicBack!, 'nic');
          log("✅ NIC Back uploaded: $nicBackUrl");
        } catch (e) {
          log("❌ NIC Back upload failed: $e");
        }
      }

      // Signature
      String? signatureUrl = _existingSignatureUrl;
      if (signatureUrl == null) {
        final sigBytes = await _signatureController.toPngBytes();
        if (sigBytes == null || sigBytes.isEmpty) {
          if (!mounted) return;
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide a digital signature.'),
            ),
          );
          return;
        }

        final tempFile = File('${Directory.systemTemp.path}/signature.png');
        await tempFile.writeAsBytes(sigBytes, flush: true);

        try {
          signatureUrl = await _uploadFileWithRetry(
            file: tempFile,
            storagePath: 'signatures/${user.uid}/signature.png',
            contentType: 'image/png',
          );
          log("✅ Signature uploaded: $signatureUrl");

          await FirebaseFirestore.instance
              .collection('signatures')
              .doc(user.uid)
              .set({
                'url': signatureUrl,
                'createdAt': FieldValue.serverTimestamp(),
                'uid': user.uid,
                'immutable': true,
              }, SetOptions(merge: false));
          log("✅ Signature document saved in Firestore");
        } catch (e) {
          log("❌ Signature upload failed: $e");
        }

        _existingSignatureUrl = signatureUrl;
      }

      // Parse numeric fields
      final price = double.tryParse(_priceController.text) ?? 0;
      final shippingFee = double.tryParse(_shippingController.text) ?? 0;
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      final discount = double.tryParse(_discountController.text) ?? 0;

      // Save artwork document
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('artworks')
            .add({
              'title': widget.title,
              'artistName': widget.artistName,
              'description': widget.description,
              'category': widget.category,
              'style': widget.style,
              'material': widget.material,
              'size': widget.sizes,
              'yearCreated': widget.yearCreated,
              'price': price,
              'currency': _selectedCurrency,
              'discount': discount,
              'quantity': quantity,
              'shippingFee': shippingFee,
              'artworkUrl': artworkUrl,
              'additionalFiles': additionalUrls,
              'nicFrontUrl': nicFrontUrl,
              'nicBackUrl': nicBackUrl,
              'signatureUrl': signatureUrl,
              'agreeLegal': _agreeLegal,
              'createdAt': Timestamp.now(),
              'userId': user.uid,
            });
        log("✅ Artwork document created: ${docRef.id}");
      } catch (e) {
        log("❌ Firestore document creation failed: $e");
        rethrow;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // hide loading

      // Navigate to preview page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewAgreementPage(
            name: widget.artistName,
            email: user.email ?? 'unknown@email.com',
            signatureUrl: signatureUrl ?? '',
            artworkImageUrl: artworkUrl,
            artworkTitle: widget.title,
          ),
        ),
      );
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting artwork: $e')));
      log("❌ _submitAll() failed: $e");
    }
  }

  InputDecoration _boxDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _labelColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _focusColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _labelColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSignaturePad =
        !_checkingSignature && _existingSignatureUrl == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _focusColor,
      ),
      body: _checkingSignature
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Price + Currency
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _boxDecoration('Price'),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              final d = double.tryParse(value);
                              if (d == null) return 'Invalid number';
                              if (d < 0) return 'Cannot be negative';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            items: const ['USD', 'LKR', 'EUR', 'INR']
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(
                              () => _selectedCurrency = val ?? 'USD',
                            ),
                            decoration: _boxDecoration('Currency'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Discount
                    TextFormField(
                      controller: _discountController,
                      keyboardType: TextInputType.number,
                      decoration: _boxDecoration('Discount (%) - optional'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return null;
                        final d = double.tryParse(value);
                        if (d == null) return 'Invalid number';
                        if (d < 0 || d > 100) return '0 - 100 only';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quantity
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            width: 250,
                            height: 65,
                            child: TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              focusNode: _quantityFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Quantity',
                                labelStyle: TextStyle(
                                  color: _quantityFocus.hasFocus
                                      ? const Color(0xff930909)
                                      : Colors.black,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: _quantityFocus.hasFocus
                                        ? const Color(0xff930909)
                                        : Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xff930909),
                                    width: 2,
                                  ),
                                ),
                                suffixIcon: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        int currentValue =
                                            int.tryParse(
                                              _quantityController.text,
                                            ) ??
                                            0;
                                        currentValue++;
                                        setState(
                                          () => _quantityController.text =
                                              currentValue.toString(),
                                        );
                                      },
                                      child: const Icon(
                                        Icons.arrow_drop_up,
                                        size: 18,
                                        color: Color(0xff930909),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        int currentValue =
                                            int.tryParse(
                                              _quantityController.text,
                                            ) ??
                                            0;
                                        if (currentValue > 0) {
                                          currentValue--;
                                          setState(
                                            () => _quantityController.text =
                                                currentValue.toString(),
                                          );
                                        }
                                      },
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        size: 18,
                                        color: Color(0xff930909),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final i = int.tryParse(value);
                                if (i == null) return 'Invalid number';
                                if (i < 0) return 'Cannot be negative';
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Shipping Fee
                    TextFormField(
                      controller: _shippingController,
                      keyboardType: TextInputType.number,
                      decoration: _boxDecoration('Shipping Fee'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        final d = double.tryParse(value);
                        if (d == null) return 'Invalid number';
                        if (d < 0) return 'Cannot be negative';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // NIC Upload (Front & Back)
                    Row(
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _pickImage(true),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'NIC Front',
                                    labelStyle: TextStyle(
                                      color: _nicFront != null
                                          ? _focusColor
                                          : _labelColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _labelColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _focusColor,
                                        width: 2,
                                      ),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.image,
                                      color: Colors.black,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: _nicFront != null
                                      ? Image.file(
                                          File(_nicFront!.path),
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : const SizedBox(
                                          height: 50,
                                          child: Center(
                                            child: Text(
                                              'Tap to upload',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (_nicFront != null)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xff930909),
                                    ),
                                    onPressed: () =>
                                        setState(() => _nicFront = null),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () => _pickImage(false),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'NIC Back',
                                    labelStyle: TextStyle(
                                      color: _nicBack != null
                                          ? _focusColor
                                          : _labelColor,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _labelColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: _focusColor,
                                        width: 2,
                                      ),
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.image,
                                      color: Colors.black,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 12,
                                    ),
                                  ),
                                  child: _nicBack != null
                                      ? Image.file(
                                          File(_nicBack!.path),
                                          height: 100,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : const SizedBox(
                                          height: 50,
                                          child: Center(
                                            child: Text(
                                              'Tap to upload',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              if (_nicBack != null)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(0xff930909),
                                    ),
                                    onPressed: () =>
                                        setState(() => _nicBack = null),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Legal agreement checkbox
                    CheckboxListTile(
                      value: _agreeLegal,
                      onChanged: (val) =>
                          setState(() => _agreeLegal = val ?? false),
                      title: const Text(
                        'I certify the truthfulness of data and accept legal actions for false data.',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Signature section: show once if none exists, else show a note
                    if (showSignaturePad) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Digital Signature (required once)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _focusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Signature(
                          controller: _signatureController,
                          key: _signatureKey,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _signatureController.clear,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: const [
                          Icon(Icons.verified, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your saved signature will be used automatically for this and future products.',
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Next button
                    ElevatedButton(
                      onPressed: _submitAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _focusColor,
                        minimumSize: const Size(150, 40),
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// PreviewAgreementPage
// ---------------------------------------------------------------------------
class PreviewAgreementPage extends StatefulWidget {
  final String name;
  final String email;
  final String signatureUrl;
  final String artworkImageUrl;
  final String artworkTitle;

  const PreviewAgreementPage({
    super.key,
    required this.name,
    required this.email,
    required this.signatureUrl,
    required this.artworkImageUrl,
    required this.artworkTitle,
  });

  @override
  State<PreviewAgreementPage> createState() => _PreviewAgreementPageState();
}

class _PreviewAgreementPageState extends State<PreviewAgreementPage> {
  Future<Uint8List> _generatePdf() async {
    final pdf = pw.Document();
    final signatureImage = widget.signatureUrl.isNotEmpty
        ? await networkImage(widget.signatureUrl)
        : null;
    final artworkImage = await networkImage(widget.artworkImageUrl);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Agreement & Certification of Truthfulness',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Artwork Title: ${widget.artworkTitle}',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Image(artworkImage, height: 150),
            pw.SizedBox(height: 20),
            pw.Text(
              'I hereby certify that all information provided in this form, including personal, artwork, and identification details, is true, accurate, and complete to the best of my knowledge. I understand that submitting false, misleading, or fraudulent information may result in legal action, including but not limited to civil or criminal liability.\n\n'
              'By signing below digitally, I, ${widget.name}, acknowledge and agree to this certification and accept full responsibility for the accuracy of the information provided.',
              style: const pw.TextStyle(fontSize: 12),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 30),
            pw.Text(
              'Name: ${widget.name}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Text(
              'Email: ${widget.email}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            if (signatureImage != null) ...[
              pw.Text(
                'Digital Signature:',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 6),
              pw.Image(signatureImage, height: 50),
            ] else ...[
              pw.Text(
                'Digital Signature: (missing)',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ✅ Updated upload method
  Future<String> _uploadPdfToFirebase(
    Uint8List pdfBytes,
    String artworkTitle,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'unknown';

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = FirebaseStorage.instance.ref().child(
      'agreements/$uid/${artworkTitle}_$timestamp.pdf',
    );

    await storageRef.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );

    final downloadUrl = await storageRef.getDownloadURL();

    return downloadUrl; // ✅ Return the URL
  }

  // ✅ Download PDF
  Future<void> _downloadPdf() async {
    try {
      final pdfBytes = await _generatePdf();

      // Save locally
      final result = await FileSaver.instance.saveFile(
        name: 'Agreement_${widget.artworkTitle}.pdf',
        bytes: pdfBytes,
        mimeType: MimeType.pdf,
      );

      if (result != '') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Agreement saved locally!')),
        );
      }

      // Upload to Firebase and get the URL
      final storageUrl = await _uploadPdfToFirebase(
        pdfBytes,
        widget.artworkTitle,
      );

      // Add a separate Firestore record for this download action
      await FirebaseFirestore.instance.collection('agreements').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'artworkTitle': widget.artworkTitle,
        'pdfUrl': storageUrl,
        'action': 'download',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error downloading PDF: $e')));
    }
  }

  // ✅ Share PDF
  Future<void> _sharePdf() async {
    try {
      final pdfBytes = await _generatePdf();

      // Share PDF
      await Printing.sharePdf(bytes: pdfBytes, filename: 'Agreement.pdf');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF ready to share')));

      // Upload to Firebase and get the URL
      final storageUrl = await _uploadPdfToFirebase(
        pdfBytes,
        widget.artworkTitle,
      );

      // Add a separate Firestore record for this share action
      await FirebaseFirestore.instance.collection('agreements').add({
        'userId': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
        'artworkTitle': widget.artworkTitle,
        'pdfUrl': storageUrl,
        'action': 'share',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error sharing PDF: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: const Text(
          'Preview Agreement',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agreement & Certification of Truthfulness',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Artwork Title: ${widget.artworkTitle}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Image.network(
                      widget.artworkImageUrl,
                      height: 150,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('Artwork not available'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'I hereby certify that all information provided in this form, including personal, artwork, and identification details, is true, accurate, and complete to the best of my knowledge. I understand that submitting false, misleading, or fraudulent information may result in legal action, including but not limited to civil or criminal liability.\n\n'
                      'By signing below digitally, I, ${widget.name}, acknowledge and agree to this certification and accept full responsibility for the accuracy of the information provided.',
                      textAlign: TextAlign.justify,
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 30),
                    Text('Name: ${widget.name}'),
                    Text('Email: ${widget.email}'),
                    const SizedBox(height: 10),
                    widget.signatureUrl.isNotEmpty
                        ? Image.network(
                            widget.signatureUrl,
                            height: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('Signature not available'),
                          )
                        : const Text('Signature not available'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text(
                    'Upload',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff930909),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _sharePdf,
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text(
                    'Share',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff930909),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
