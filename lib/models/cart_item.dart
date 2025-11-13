class CartItem {
  final String id;        // The unique Firestore product ID
  final String name;      // Product name
  final double price;     // Product price
  int quantity;           // Quantity in the cart

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  // Helper method to calculate the total price for this item
  double get totalPrice => price * quantity;
}