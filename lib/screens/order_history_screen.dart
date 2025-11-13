// lib/screens/order_history_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// If you use currency formatting in OrderCard, you still need this:
import 'package:intl/intl.dart';

// Assuming 'order_card.dart' is a widget you've created to display a single order
import 'package:smarthomedevices_app/widgets/order_card.dart';

// --- THEME COLORS (for consistency) ---
const Color kPrimaryGreen = Color(0xFF5E6B5A);
const Color kCreamWhite = Color(0xFFF5F3E9);
const Color kRichBlack = Color(0xFF1C1C1C); // For text
// --- END OF THEME ---


class OrderHistoryScreen extends StatefulWidget {
  final String? statusFilter;
  final String title;

  const OrderHistoryScreen({
    super.key,
    this.statusFilter,
    this.title = 'My Orders History',
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to build the Firebase query dynamically
  Stream<QuerySnapshot> _buildOrdersStream() {
    if (_currentUser == null) {
      return Stream.empty();
    }

    // Start with the base query
    Query query = _firestore
        .collection('orders')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true);

    // If a filter is provided, apply the .where clause for the status
    if (widget.statusFilter != null && widget.statusFilter!.isNotEmpty) {
      // NOTE: Index on userId + status + createdAt (desc) is required in Firestore
      query = query.where('status', isEqualTo: widget.statusFilter);
    }

    return query.snapshots();
  }

  // Function to get specific order count (used by the category grid)
  Future<int> _getOrdersCountByStatus(String status) async {
    if (_currentUser == null) return 0;
    final querySnapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: _currentUser!.uid)
        .where('status', isEqualTo: status)
        .get();
    return querySnapshot.docs.length;
  }

  // Helper function to navigate to the filtered list
  void _navigateToFilteredOrders(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderHistoryScreen(statusFilter: status, title: status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the title based on the filter
    final bool isFilteredView = widget.statusFilter != null && widget.statusFilter!.isNotEmpty;
    final String screenTitle = isFilteredView ? '${widget.statusFilter} Orders' : 'My Orders History';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, style: const TextStyle(color: kRichBlack)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: kRichBlack,
        elevation: 0.5,
      ),
      body: _currentUser == null
          ? const Center(child: Text('Please log in to see your orders.'))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            if (!isFilteredView) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                child: Text(
                  'My Purchases',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kRichBlack),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: OrderCategoryGrid(
                  getOrdersCountByStatus: _getOrdersCountByStatus,
                  onCategorySelected: _navigateToFilteredOrders,
                ),
              ),
              const Divider(height: 1, thickness: 1),

              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'All Orders', // Label for the full list below the grid
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kRichBlack),
                ),
              ),
            ],

            // StreamBuilder for the Order List
            StreamBuilder<QuerySnapshot>(
              stream: _buildOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final orderDocs = snapshot.data!.docs;

                if (orderDocs.isEmpty) {
                  final String emptyMessage = isFilteredView
                      ? 'No ${widget.statusFilter?.toLowerCase()} orders found.'
                      : 'You have not placed any orders yet.';
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(emptyMessage),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orderDocs.length,
                  itemBuilder: (context, index) {
                    final orderData = orderDocs[index].data() as Map<String, dynamic>;
                    return OrderCard(orderData: orderData);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCategoryGrid extends StatelessWidget {
  final Future<int> Function(String status) getOrdersCountByStatus;
  final Function(String status) onCategorySelected;

  const OrderCategoryGrid({
    super.key,
    required this.getOrdersCountByStatus,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container( // Use a Container for the structure instead of Card
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor, // White/Default background
        // Optional: Rounded corners if you want it to stand out
        // borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0), // Remove horizontal padding here
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => onCategorySelected(''), // Empty filter shows all orders
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: const [
                        Text('View Purchase History', style: TextStyle(color: kPrimaryGreen, fontSize: 14)),
                        Icon(Icons.arrow_forward_ios, size: 14, color: kPrimaryGreen),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // --- Category Items with Dividers ---
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Pending
                Expanded(child: _buildCategoryItem(context, 'Pending', Icons.hourglass_bottom, onCategorySelected)),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                // Processing
                Expanded(child: _buildCategoryItem(context, 'Processing', Icons.build_circle_outlined, onCategorySelected)),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                // Shipped
                Expanded(child: _buildCategoryItem(context, 'Shipped', Icons.local_shipping_outlined, onCategorySelected)),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                // Delivered
                Expanded(child: _buildCategoryItem(context, 'Delivered', Icons.check_circle_outline, onCategorySelected)),
                const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                // Cancelled
                Expanded(child: _buildCategoryItem(context, 'Cancelled', Icons.cancel_outlined, onCategorySelected)),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, String status, IconData icon, Function(String) onTap) {
    return InkWell(
      onTap: () => onTap(status),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: kRichBlack),
            const SizedBox(height: 4),
            Text(status, style: const TextStyle(fontSize: 12, color: kRichBlack)),
          ],
        ),
      ),
    );
  }
}