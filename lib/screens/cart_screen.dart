// lib/screens/cart_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarthomedevices_app/providers/cart_provider.dart';
import 'package:smarthomedevices_app/screens/payment_screen.dart'; // 1. Import PaymentScreen
// We no longer need OrderSuccessScreen here, it will be called from PaymentScreen
// import 'package:smarthomedevices_app/screens/order_success_screen.dart';

// 2. It's a StatelessWidget again!
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. We listen: true, so the list and total update
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          // 2. The ListView
          Expanded(
            // Show a message if the cart is empty
            child: cart.items.isEmpty
                ? const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(fontSize: 18),
              ),
            )
                : ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final cartItem = cart.items[i];
                return ListTile(
                  leading: CircleAvatar(
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: FittedBox(
                        child: Text('₱${cartItem.price.toStringAsFixed(0)}'),
                      ),
                    ),
                  ),
                  title: Text(cartItem.name),
                  subtitle: Text('Total: ₱${(cartItem.price * cartItem.quantity).toStringAsFixed(2)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Qty: ${cartItem.quantity}'),
                      // Add a remove button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Call the remove function from the provider
                          // Use listen: false because we are in a function
                          Provider.of<CartProvider>(context, listen: false)
                              .removeItem(cartItem.id);
                        },
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. --- THIS IS THE NEW PRICE BREAKDOWN CARD ---
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column( // 4. Use a Column for multiple rows
                children: [

                  // 5. ROW 1: Subtotal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal:',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '₱${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 6. ROW 2: VAT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'VAT (12%):',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '₱${cart.vat.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  const Divider(height: 20, thickness: 1),

                  // 7. ROW 3: Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '₱${cart.totalPriceWithVat.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // --- END OF NEW CARD ---


          // 6. --- THIS IS THE MODIFIED BUTTON ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // Wide button
              ),
              // 7. Disable if cart is empty, otherwise navigate
              onPressed: cart.items.isEmpty ? null : () {
                // 8. Navigate to our new PaymentScreen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      // 9. Pass the final VAT-inclusive total
                      totalAmount: cart.totalPriceWithVat,
                    ),
                  ),
                );
              },
              // 10. No more spinner!
              child: const Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }
}