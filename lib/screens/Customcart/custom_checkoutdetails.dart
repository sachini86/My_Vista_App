import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String id;
  final String name;
  final int quantity;
  final double price;

  CartItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'quantity': quantity, 'price': price};
  }
}

class CheckoutPage extends StatefulWidget {
  final List<CartItem> cartItems;

  const CheckoutPage({super.key, required this.cartItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Shipping controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String selectedPayment = 'Cash on Delivery';
  bool isPlacingOrder = false;

  double get subtotal => widget.cartItems.fold(
    0,
    (total, item) => total + item.price * item.quantity,
  );
  double shipping = 300;
  double get total => subtotal + shipping;

  void _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isPlacingOrder = true);

    Map<String, dynamic> orderData = {
      'customer': {
        'name': nameController.text,
        'address': addressController.text,
        'city': cityController.text,
        'phone': phoneController.text,
      },
      'payment_method': selectedPayment,
      'items': widget.cartItems.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'total': total,
      'order_time': FieldValue.serverTimestamp(),
      'status': 'pending',
    };

    try {
      await FirebaseFirestore.instance.collection('orders').add(orderData);
      if (!mounted) return;
      setState(() => isPlacingOrder = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('🎉 Order Placed!'),
          content: const Text('Your order has been placed successfully.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => isPlacingOrder = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error placing order: $e')));
    }
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    cityController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xff930909),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shipping Details
              const Text(
                'Shipping Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter your name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Enter your address' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter your city' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Enter your phone' : null,
                    ),
                  ],
                ),
              ),

              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildCard(
                child: Column(
                  children: [
                    RadioListTile(
                      title: const Text('Cash on Delivery'),
                      value: 'Cash on Delivery',
                      groupValue: selectedPayment,
                      onChanged: (v) => setState(() => selectedPayment = v!),
                    ),
                    RadioListTile(
                      title: const Text('Credit / Debit Card'),
                      value: 'Card',
                      groupValue: selectedPayment,
                      onChanged: (v) => setState(() => selectedPayment = v!),
                    ),
                    RadioListTile(
                      title: const Text('Google Pay'),
                      value: 'Google Pay',
                      groupValue: selectedPayment,
                      onChanged: (v) => setState(() => selectedPayment = v!),
                    ),
                  ],
                ),
              ),

              // Order Summary
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              _buildCard(
                child: Column(
                  children: [
                    ...widget.cartItems.map(
                      (item) => _SummaryItemRow(item: item),
                    ),
                    const Divider(thickness: 1.2),
                    _SummaryRow(
                      label: 'Subtotal',
                      value: 'LKR ${subtotal.toStringAsFixed(2)}',
                    ),
                    _SummaryRow(
                      label: 'Shipping',
                      value: 'LKR ${shipping.toStringAsFixed(2)}',
                    ),
                    _SummaryRow(
                      label: 'Total',
                      value: 'LKR ${total.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff930909),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isPlacingOrder
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Place Order',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Individual cart item row
class _SummaryItemRow extends StatelessWidget {
  final CartItem item;
  const _SummaryItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${item.name} x${item.quantity}'),
          Text('LKR ${(item.price * item.quantity).toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

// Total summary row
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
