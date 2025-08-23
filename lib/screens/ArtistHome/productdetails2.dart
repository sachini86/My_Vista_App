import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:signature/signature.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';

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
  ByteData? _signatureData;

  final _picker = ImagePicker();
  final _signatureKey = GlobalKey<SignatureState>();

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final Color _labelColor = Colors.black;
  final Color _focusColor = const Color(0xff930909);

  Future<String> _uploadFile(XFile file, String folder) async {
    File f = File(file.path);
    final ref = FirebaseStorage.instance.ref('$folder/${file.name}');
    await ref.putFile(f);
    return await ref.getDownloadURL();
  }

  Future<void> _pickImage(bool isFront) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
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

    // 1️⃣ Upload artwork & additional files
    String artworkUrl = await _uploadFile(widget.artwork, 'artworks');
    List<String> additionalUrls = [];
    for (var file in widget.additionalFiles) {
      additionalUrls.add(await _uploadFile(file, 'artworks_additional'));
    }

    String? nicFrontUrl;
    String? nicBackUrl;
    if (_nicFront != null) nicFrontUrl = await _uploadFile(_nicFront!, 'nic');
    if (_nicBack != null) nicBackUrl = await _uploadFile(_nicBack!, 'nic');

    // 2️⃣ Convert signature to File & upload
    String? signatureUrl;
    if (_signatureData != null) {
      final tempFile = File('${Directory.systemTemp.path}/signature.png');
      await tempFile.writeAsBytes(_signatureData!.buffer.asUint8List());

      final user = FirebaseAuth.instance.currentUser;
      final ref = FirebaseStorage.instance.ref().child(
        "signatures/${user!.uid}.png",
      );

      await ref.putFile(tempFile);
      signatureUrl = await ref.getDownloadURL();
    }

    // 3️⃣ Save artwork details to Firestore
    await FirebaseFirestore.instance.collection('artworks').add({
      'title': widget.title,
      'artistName': widget.artistName,
      'description': widget.description,
      'category': widget.category,
      'style': widget.style,
      'material': widget.material,
      'size': widget.sizes,
      'yearCreated': widget.yearCreated,
      'price': double.parse(_priceController.text),
      'currency': _selectedCurrency,
      'discount': _discountController.text.isEmpty
          ? 0
          : double.parse(_discountController.text),
      'quantity': int.parse(_quantityController.text),
      'shippingFee': double.parse(_shippingController.text),
      'artworkUrl': artworkUrl,
      'additionalFiles': additionalUrls,
      'nicFrontUrl': nicFrontUrl,
      'nicBackUrl': nicBackUrl,
      'signatureUrl': signatureUrl,
      'agreeLegal': _agreeLegal,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;

    // 4️⃣ Navigate to PreviewAgreementPage if signature exists
    if (signatureUrl != null) {
      final user = FirebaseAuth.instance.currentUser;
      final userDoc = await FirebaseFirestore.instance
          .collection("artists")
          .doc(user!.uid)
          .get();

      final userName = userDoc["name"];
      final userEmail = userDoc["email"];
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewAgreementPage(
            name: userName,
            email: userEmail,
            signatureUrl: signatureUrl!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a digital signature.')),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _focusColor,
      ),
      body: SingleChildScrollView(
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
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value)! < 0) {
                          return 'Cannot be negative';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      items: ['USD', 'LKR', 'EUR']
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCurrency = val!;
                        });
                      },
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
                  if (double.tryParse(value)! < 0) return 'Cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Quantity
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: 250, // adjust width if needed
                      height: 65,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        focusNode: _quantityFocus,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly, // only digits
                        ],
                        decoration: InputDecoration(
                          labelText: "Quantity",
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
                                      int.tryParse(_quantityController.text) ??
                                      0;
                                  currentValue++;
                                  setState(() {
                                    _quantityController.text = currentValue
                                        .toString();
                                  });
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
                                      int.tryParse(_quantityController.text) ??
                                      0;
                                  if (currentValue > 0) {
                                    currentValue--;
                                    setState(() {
                                      _quantityController.text = currentValue
                                          .toString();
                                    });
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
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value)! < 0) {
                            return 'Cannot be negative';
                          }
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
                  if (double.tryParse(value)! < 0) return 'Cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // NIC Upload (Front & Back)
              // NIC Upload (Front & Back) with Close Button
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
                                        style: TextStyle(color: Colors.black),
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
                              onPressed: () {
                                setState(() {
                                  _nicFront = null;
                                });
                              },
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
                                        style: TextStyle(color: Colors.black),
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
                              onPressed: () {
                                setState(() {
                                  _nicBack = null;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              // Legal agreement
              CheckboxListTile(
                value: _agreeLegal,
                onChanged: (val) {
                  setState(() {
                    _agreeLegal = val!;
                  });
                },
                title: const Text(
                  'I certify the truthfulness of data and accept legal actions for false data.',
                ),
              ),
              const SizedBox(height: 20),
              // Signature
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
                    onPressed: () {
                      _signatureController.clear();
                      setState(() {
                        _signatureData = null;
                      });
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
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

// Dummy PreviewAgreementPage

class PreviewAgreementPage extends StatefulWidget {
  final String name;
  final String email;
  final String signatureUrl;

  const PreviewAgreementPage({
    super.key,
    required this.name,
    required this.email,
    required this.signatureUrl,
  });

  @override
  State<PreviewAgreementPage> createState() => _PreviewAgreementPageState();
}

class _PreviewAgreementPageState extends State<PreviewAgreementPage> {
  final pdf = pw.Document();

  Future<Uint8List> _generatePdf() async {
    final netImage = await networkImage(widget.signatureUrl);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Agreement & Certification of Truthfulness",
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "I hereby certify that all information provided in this form, including personal, artwork, and identification details, is true, accurate, and complete to the best of my knowledge. I understand that submitting false, misleading, or fraudulent information may result in legal action, including but not limited to civil or criminal liability.\n\n"
              "By signing below digitally, I acknowledge and agree to this certification and accept full responsibility for the accuracy of the information provided.",
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 30),
            pw.Text("Name: ${widget.name}", style: pw.TextStyle(fontSize: 12)),
            pw.Text(
              "Email: ${widget.email}",
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Digital Signature:", style: pw.TextStyle(fontSize: 12)),
            pw.Image(netImage, height: 80),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  Future<void> _uploadPdfToFirebase(Uint8List pdfBytes) async {
    final storageRef = FirebaseStorage.instance.ref().child(
      "agreements/${widget.email}_agreement.pdf",
    );

    await storageRef.putData(
      pdfBytes,
      SettableMetadata(contentType: "application/pdf"),
    );
    final downloadUrl = await storageRef.getDownloadURL();

    await FirebaseFirestore.instance
        .collection("agreements")
        .doc(widget.email)
        .set({
          "name": widget.name,
          "email": widget.email,
          "pdfUrl": downloadUrl,
          "timestamp": FieldValue.serverTimestamp(),
        });
  }

  void _downloadPdf() async {
    final pdfBytes = await _generatePdf();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("PDF downloaded")));
    await _uploadPdfToFirebase(pdfBytes);
  }

  void _sharePdf() async {
    final pdfBytes = await _generatePdf();
    await Printing.sharePdf(bytes: pdfBytes, filename: "Agreement.pdf");
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("PDF ready to share")));
    await _uploadPdfToFirebase(pdfBytes);
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
          children: [
            const Text(
              "Agreement & Certification of Truthfulness",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            const Text(
              "I hereby certify that all information provided in this form, including personal, artwork, and identification details, is true, accurate, and complete to the best of my knowledge. I understand that submitting false, misleading, or fraudulent information may result in legal action, including but not limited to civil or criminal liability.\n\n"
              "By signing below digitally, I acknowledge and agree to this certification and accept full responsibility for the accuracy of the information provided.",
            ),
            const SizedBox(height: 20),
            Text("Name: ${widget.name}"),
            Text("Email: ${widget.email}"),
            const SizedBox(height: 10),
            Image.network(widget.signatureUrl, height: 80),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _downloadPdf,
                  icon: const Icon(Icons.download),
                  label: const Text("Download"),
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
                  icon: const Icon(Icons.share),
                  label: const Text("Share"),
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
