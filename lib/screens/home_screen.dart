import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smarthomedevices_app/screens/admin_panel_screen.dart';
import 'package:smarthomedevices_app/widgets/product_card.dart';
import 'package:smarthomedevices_app/screens/product_detail_screen.dart';
import 'package:smarthomedevices_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:smarthomedevices_app/screens/cart_screen.dart'; // 2. ADD THIS
import 'package:provider/provider.dart';
// Note: This import seems redundant for 'home_screen.dart' itself, but is kept if intended for other use
import 'package:smarthomedevices_app/screens/home_screen.dart';
import 'package:smarthomedevices_app/screens/order_history_screen.dart';
// 1. ADD THIS (Module: Create Profile Screen - Part A)
import 'package:smarthomedevices_app/screens/profile_screen.dart';
import 'package:smarthomedevices_app/widgets/notification_icon.dart';

// 1. ADD THIS IMPORT for the new chat screen
import 'package:smarthomedevices_app/screens/chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  // 2. Add instances for FireAuth and FireStore
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final User? user = FirebaseAuth.instance.currentUser;

    // This check is now reliable.
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid) // <-- Use the local 'user' variable
          .get();

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _userRole = doc.data()!['role'];
          });
        }
      }
    } catch (e) {
      print("Error fetching user role: $e");
    }
  }

  // DELETED: We no longer need the _signOut function here. It is moved to ProfileScreen.
  // Future<void> _signOut() async { ... }

  @override
  Widget build(BuildContext context) {
    // 3. Use the local _currentUser variable
    final User? currentUser = _currentUser;

    return Scaffold(
      appBar: AppBar(

        // 1. --- THIS IS THE CHANGE ---
        //    DELETE your old title:
        /*
        // Use the local 'currentUser' variable
        title: Text(currentUser != null ? 'Welcome, ${currentUser.email}' : 'Home'),
        */

        // 2. ADD this new title:
        title: Image.asset(
          'assets/images/app_logo.png', // 3. The path to your logo
          height: 40, // 4. Set a fixed height
        ),
        // 5. 'centerTitle' is now handled by our global AppBarTheme

        // --- END OF CHANGE ---

        actions: [
          // All your icons (Cart, Bell, Orders, Admin, Profile)
          // will now be 'kRichBlack' (black) because of our theme.

          // 1. Cart Icon
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // 2. Notification Bell (Unchanged)
          const NotificationIcon(),

          // 3. "My Orders" Icon (Unchanged)
          // --- NEW: MY ORDERS ICON (Module 11 - Part D) ---
          // 2. --- ADD THIS NEW BUTTON ---
          IconButton(
            icon: const Icon(Icons.receipt_long), // A "receipt" icon
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          // --- END NEW ICON ---

          // 4. Admin Icon (Unchanged)
          // This "if" statement will now work correctly
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen(),
                  ),
                );
              },
            ),

          // 5. DELETED the old "Logout" IconButton (Module: Create Profile Screen - Part A)
          /*
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _signOut,
          ),
          */

          // 6. ADD this new "Profile" IconButton (Module: Create Profile Screen - Part A)
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),

      drawer: Drawer(
        // ... (Drawer content is unchanged)
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                currentUser?.email ?? 'Menu',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              // FIX: Changed onPressed to onTap for ListTile
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Divider(),
            // DELETED the old "Logout" ListTile (Module: Create Profile Screen - Part A)
            /*
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _signOut,
            ),
            */
          ],
        ),
      ),

      // 6. --- NEW: FLOATING ACTION BUTTON WITH CHAT BADGE (Part D) ---
      floatingActionButton: _userRole == 'user' && _currentUser != null
          ? StreamBuilder<DocumentSnapshot>(
        // Listen to *this user's* chat document
        stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
        builder: (context, snapshot) {

          int unreadCount = 0;
          // Check if the document exists and has the count field
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              // Safely get the count
              unreadCount = (data as Map<String, dynamic>)['unreadByUserCount'] as int? ?? 0;
            }
          }

          // Wrap the FAB in the Badge widget
          return Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0, // Only show if count > 0

            // The FAB is the *child* of the Badge
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Admin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: _currentUser!.uid, // Chat room is the User's UID
                    ),
                  ),
                );
              },
            ),
          );
        },
      )
          : null, // If admin or not logged in, don't show the FAB
      // --- END NEW FAB ---

      body: StreamBuilder<QuerySnapshot>(
        // ... (Product listing StreamBuilder remains the same)
        stream: FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No products found. Add some in the Admin Panel!'),
            );
          }

          final products = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(10.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 4,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final productDoc = products[index];
              final productData = productDoc.data() as Map<String, dynamic>;

              return ProductCard(
                productName: productData['name'],
                // Handle potential null or incorrect types from Firestore
                price: (productData['price'] ?? 0).toDouble(),
                imageUrl: productData['imageUrl'],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        productData:productData,
                        productId:productDoc.id,
                      ),
                    ),
                  );
                },


              );
            },
          );
        },
      ),
    );
  }
}