import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomCart extends StatelessWidget {
  const CustomCart({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff930909),
        title: const Text('Cart', style: TextStyle(color: Colors.white)),
      ),
      body: user == null
          ? const Center(child: Text('Sign in to view your cart'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('cart')
                  .orderBy('addedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final items = snapshot.data?.docs ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('Your cart is empty'));
                }

                double subtotal = 0;
                double saleDiscount = 0;
                double shippingFee = 0;
                String currency = "USD";

                for (final item in items) {
                  final data = item.data();
                  final price = (data['price'] ?? 0).toDouble();
                  final discount = (data['discount'] ?? 0).toDouble();
                  final shipping =
                      double.tryParse(data['shippingFee']?.toString() ?? '0') ??
                      0;
                  final qty = (data['qty'] ?? 1).toInt();
                  currency = (data['currency'] ?? "USD").toString();

                  final discountedPrice = price * (1 - discount / 100);
                  subtotal += discountedPrice * qty;
                  shippingFee += shipping * qty;
                  saleDiscount += (price - discountedPrice) * qty;
                }

                final netTotal = subtotal - saleDiscount + shippingFee;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final data = item.data();
                          final qty = (data['qty'] ?? 1).toInt();
                          final price = (data['price'] ?? 0).toDouble();
                          final discount = (data['discount'] ?? 0).toDouble();
                          shippingFee +=
                              (double.tryParse(
                                    data['shippingFee']?.toString() ?? '0',
                                  ) ??
                                  0) *
                              qty;

                          final discountedPrice = price * (1 - discount / 100);
                          final currency = (data['currency'] ?? "USD")
                              .toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ), // ✅ only box
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          (data['artworkUrl'] != null &&
                                              data['artworkUrl']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? Image.network(
                                              data['artworkUrl'],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Image.asset(
                                                    '',
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                            )
                                          : Image.asset(
                                              '',
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            data['title'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (data['variant'] != null)
                                            Text(
                                              data['variant'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                '$currency ${discountedPrice.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: discount > 0
                                                      ? Colors.red
                                                      : Colors.black,
                                                ),
                                              ),
                                              if (discount > 0)
                                                Text(
                                                  '$currency ${price.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => item.reference.delete(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                      onPressed: () {
                                        final newQty = qty > 1 ? qty - 1 : 1;
                                        item.reference.update({'qty': newQty});
                                      },
                                    ),
                                    Text('$qty'),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      onPressed: () {
                                        item.reference.update({'qty': qty + 1});
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Gross Total:'),
                              Text('$currency ${subtotal.toStringAsFixed(2)}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sale Discount:'),
                              Text(
                                '$currency ${saleDiscount.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Shipping Fee:'),
                              Text(
                                '$currency ${shippingFee.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Net Total:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$currency ${netTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          SizedBox(
                            width: 200,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () {
                                // Checkout logic
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff930909),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Checkout',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
