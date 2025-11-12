// lib/screens/order_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderDetailScreen extends StatelessWidget {
  // 1. We'll pass in the full order data map from the previous screen
  final Map<String, dynamic> orderData;

  const OrderDetailScreen({
    super.key,
    required this.orderData,
  });

  // Helper function to format the Timestamp
  String _formatDate(Timestamp timestamp) {
    final DateTime date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // 2. Extract all the data from the map for easier use
    final String status = orderData['status'];
    final double totalPrice = orderData['totalPrice'];
    final Timestamp createdAt = orderData['createdAt'];
    // This is our List<Map<String, dynamic>>
    final List<dynamic> items = orderData['items'];

    return Scaffold(
      appBar: AppBar(
        // 3. Show the date in the title
        title: Text('Order from ${_formatDate(createdAt)}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4. --- Order Summary Section ---
            Text(
              'Order Summary',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Status: $status',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Price: ₱${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Placed On: ${_formatDate(createdAt)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),

            // 5. --- Items List Section ---
            Text(
              'Items (${items.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // 6. We use a Column with .map() to display the list
            //    (This avoids nested scrolling errors)
            Column(
              children: items.map((itemData) {
                // itemData is a Map<String, dynamic>
                // from our CartItem.toJson() method
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ListTile(
                    title: Text(
                      itemData['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'Price: ₱${itemData['price'].toStringAsFixed(2)}'),
                    trailing: Text(
                      'Qty: ${itemData['quantity']}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }).toList(), // Convert the mapped items into a list of widgets
            ),
          ],
        ),
      ),
    );
  }
}