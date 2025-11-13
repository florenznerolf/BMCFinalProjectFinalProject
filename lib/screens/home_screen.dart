import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

// SCREEN IMPORTS
import 'package:smarthomedevices_app/screens/admin_panel_screen.dart';
import 'package:smarthomedevices_app/screens/cart_screen.dart';
import 'package:smarthomedevices_app/screens/chat_screen.dart';
import 'package:smarthomedevices_app/screens/order_history_screen.dart';
import 'package:smarthomedevices_app/screens/profile_screen.dart';
import 'package:smarthomedevices_app/screens/product_detail_screen.dart';
import 'package:smarthomedevices_app/screens/notifications_screen.dart'; // Ensure this is imported

// WIDGET/PROVIDER IMPORTS
import 'package:smarthomedevices_app/providers/cart_provider.dart';
import 'package:smarthomedevices_app/widgets/notification_icon.dart';
import 'package:smarthomedevices_app/widgets/product_card.dart';

// --- THEME COLORS ---
const Color kRichBlack = Color(0xFF1C1C1C);
const Color kPrimaryGreen = Color(0xFF5E6B5A);
const Color kCreamWhite = Color(0xFFF5F3E9);
const Color kAppBackground = Color(0xFFF8F4F0);
// --- END OF THEME ---


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userRole = 'user';
  String? _profileImageUrl;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedIndex = 0;

  // List of screens for the BottomNavigationBar
  final List<Widget> _widgetOptions = <Widget>[
    // Index 0: The complex home screen content (The main content)
    _HomeContent(),
    // Index 1: Cart Screen
    const CartScreen(),
    // Index 2: Order History Screen
    const OrderHistoryScreen(),
    // Index 3: Notifications Screen
    const NotificationsScreen(),
    // Index 4: Profile Screen
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _userRole = doc.data()!['role'];
            _profileImageUrl = doc.data()!['profileImageUrl'] as String?;
          });
        }
      }
    } catch (e) {
      print("Error fetching user role and profile image: $e");
    }
  }

  // Helper function to navigate and close the drawer
  void _navigateToScreen(BuildContext context, Widget screen) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    }
    // We navigate using push for deep links (like Admin Panel), but main navigation uses the BottomBar
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => screen),
    );
  }


  @override
  Widget build(BuildContext context) {
    final User? currentUser = _currentUser;
    final String userEmail = currentUser?.email ?? 'Menu';

    return Scaffold(
      appBar: AppBar(
        // The title/logo remains centered
        title: Image.asset(
          'assets/images/app_logo.png',
          height: 40,
        ),
        actions: [
          // If you want to keep the admin panel quick access here:
          if (_userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
                );
              },
            ),
        ],
      ),

      // --- DRAWER: SIMPLIFIED NAVIGATION (ONLY PROFILE & ADMIN PUSH) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: const Text('View Profile & Settings'),

              currentAccountPicture: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                  ? CircleAvatar(
                backgroundImage: NetworkImage(_profileImageUrl!),
                backgroundColor: Colors.white,
              )
                  : const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF5E6B5A)), // Default icon
              ),

              onDetailsPressed: () => _onItemTapped(4), // Navigate to Account/Profile tab

              decoration: const BoxDecoration(
                color: Color(0xFF5E6B5A), // Primary Green
              ),
            ),

            // Drawer items now use _onItemTapped to switch the BottomBar
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Cart'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _onItemTapped(4);
              },
            ),

            const Divider(),

            // Optional: Admin Panel remains a push navigation
            if (_userRole == 'admin')
              ListTile(
                leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                title: const Text('Admin Panel', style: TextStyle(color: Colors.red)),
                onTap: () => _navigateToScreen(context, const AdminPanelScreen()),
              ),
          ],
        ),
      ),

      floatingActionButton: _userRole == 'user' && _currentUser != null && _selectedIndex == 0 // Only show on Home tab
          ? StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('chats').doc(_currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          int unreadCount = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              unreadCount = (data as Map<String, dynamic>)['unreadByUserCount'] as int? ?? 0;
            }
          }

          return Badge(
            label: Text('$unreadCount'),
            isLabelVisible: unreadCount > 0,
            child: FloatingActionButton.extended(
              icon: const Icon(Icons.support_agent),
              label: const Text('Contact Admin'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      chatRoomId: _currentUser!.uid,
                    ),
                  ),
                );
              },
            ),
          );
        },
      )
          : null,

      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Consumer<CartProvider>( // Add Cart badge to BottomNav
              builder: (context, cart, child) {
                return Badge(
                  label: Text(cart.itemCount.toString()),
                  isLabelVisible: cart.itemCount > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            activeIcon: const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          // Using a placeholder for Notification count, since NotificationIcon widget is complex
          const BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notif',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: kPrimaryGreen,
        unselectedItemColor: kRichBlack.withOpacity(0.6),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}


class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This is the content that appears on the Home tab (index 0)
    return ListView(
      children: [
        const SearchBarWidget(),
        const SizedBox(height: 16),
        const PromoBannerWidget(),
        const SizedBox(height: 16),
        const SectionTitleWidget(title: 'All Products'),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.symmetric(vertical: 50.0),
                child: CircularProgressIndicator(),
              ));
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),

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
      ],
    );
  }
}


class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          prefixIcon: const Icon(Icons.search, color: kPrimaryGreen),
          fillColor: kCreamWhite,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryGreen, width: 2),
          ),
        ),
      ),
    );
  }
}

class PromoBannerWidget extends StatelessWidget {
  const PromoBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: kPrimaryGreen.withOpacity(0.9),
        elevation: 4,
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Deals!', style: TextStyle(color: kCreamWhite, fontSize: 16)),
                  Text('Smart Home Hub', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Upgrade your smart life today!', style: TextStyle(color: kCreamWhite)),
                ],
              ),
              Icon(Icons.lightbulb_outline, size: 50, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionTitleWidget extends StatelessWidget {
  final String title;
  const SectionTitleWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kRichBlack),
          ),
          TextButton(
            onPressed: () {
              // Action when "See all" is tapped
            },
            child: const Text('See all', style: TextStyle(color: kPrimaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}