import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smarthomedevices_app/providers/cart_provider.dart';

// --- THEME COLORS (Match the HomeScreen) ---
const Color kRichBlack = Color(0xFF1C1C1C);
const Color kPrimaryGreen = Color(0xFF5E6B5A);
const Color kCreamWhite = Color(0xFFF5F3E9);
const Color kAppBackground = Color(0xFFF8F4F0);
// --- END OF THEME ---

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> productData;
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productData,
    required this.productId,
  });

  @override
  Widget build(BuildContext context) {
    // Safely extract product details, providing fallback values if data is missing
    final String name = productData['name'] ?? 'Unknown Product';
    final double price = (productData['price'] as num?)?.toDouble() ?? 0.0;
    final String imageUrl = productData['imageUrl'] ?? 'https://placehold.co/600x400/CCCCCC/1C1C1C?text=No+Image';
    final String description = productData['description'] ?? 'No description available for this product.';
    final int stock = productData['stock'] ?? 0;
    
    // Determine availability and cart button text
    final bool isAvailable = stock > 0;
    final String buttonText = isAvailable ? 'Add to Cart' : 'Out of Stock';

    return Scaffold(
      backgroundColor: kAppBackground,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: kPrimaryGreen,
        foregroundColor: kCreamWhite,
      ),
      
      // Use SingleChildScrollView to prevent overflow errors if content is long
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Product Image ---
            Hero(
              tag: productId, // Required for smooth navigation transition
              child: Image.network(
                imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 50, color: kRichBlack),
                    ),
                  );
                },
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. Name and Price ---
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kRichBlack,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 3. Stock Status ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? 'In Stock ($stock)' : 'Out of Stock',
                      style: TextStyle(
                        color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- 4. Description ---
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kRichBlack,
                    ),
                  ),
                  const Divider(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: kRichBlack,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // --- 5. Bottom Action Bar (Add to Cart) ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: kCreamWhite,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea( // Ensures buttons don't overlap home indicator
          child: ElevatedButton.icon(
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryGreen, // Green button background
              foregroundColor: kCreamWhite,    // White text/icon
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: isAvailable
                ? () {
                    // Access the CartProvider and add the item
                    Provider.of<CartProvider>(context, listen: false).addItem(
                      productId,
                      name,
                      price,
                      imageUrl,
                    );

                    // Show confirmation message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name added to cart!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                : null, // Disable button if not available
          ),
        ),
      ),
    );
  }
}
