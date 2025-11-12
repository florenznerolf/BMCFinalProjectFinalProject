import 'package:flutter/material.dart';

// 1. This is a simple StatelessWidget
class ProductCard extends StatelessWidget {

  // 2. We'll require the data we need to display
  final String productName;
  final double price;
  final String imageUrl;
  final VoidCallback onTap;

  // 3. The constructor takes this data
  const ProductCard({
    super.key,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the Card in an InkWell widget
    return InkWell(
      onTap: onTap, // 2. Call the function we passed in
      // 1. The Card will get its style from our new 'cardTheme'
      child: Card(
        // 2. The theme's 'clipBehavior' will handle the clipping
        // 3. The rest of your Column code is UNCHANGED
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 3. This Expanded makes the image take up most of the space
            Expanded(
              flex: 3, // Give the image 3 "parts" of the space
              child: Image.network(
                imageUrl, // 3. This loads the image from the URL!
                fit: BoxFit.cover, // 4. This makes the image fill its box

                // 5. Show a loading spinner while the image downloads
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },

                // 6. Show an error icon if the URL is bad
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),

            // 4. This Expanded holds the text
            Expanded(
              flex: 2, // Give the text 2 "parts" of the space
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      productName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2, // Allow two lines for the name
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(), // 5. Pushes the price to the bottom

                    // Price
                    Text(
                      // 12. Format the number to 2 decimal places
                      '₱${price.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}