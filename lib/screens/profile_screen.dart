// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Assuming you have this screen from a previous module
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String _userEmail = 'Loading...';
  String _userRole = 'user';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) return;

    try {
      // 1. Fetch user data from 'users' collection
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _userEmail = doc.data()!['email'] ?? 'No Email';
            _userRole = doc.data()!['role'] ?? 'user';
          });
        }
      } else {
        // Fallback to Firebase Auth email if document is missing
        if (mounted) {
          setState(() {
            _userEmail = _currentUser!.email ?? 'Guest User';
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _userEmail = _currentUser!.email ?? 'Error fetching data';
        });
      }
    }
  }

  // 1. --- THIS IS THE LOGOUT BUTTON FIX (Part A) ---
  Future<void> _signOut() async {
    // 2. Get the Navigator *before* the async call
    final navigator = Navigator.of(context);

    // 3. Perform the actual sign out
    await _auth.signOut();

    // 4. --- THIS IS THE FIX ---
    // After signing out, pop all screens until we are back at the AuthWrapper.
    // This prevents the "stuck screen" bug.
    navigator.popUntil((route) => route.isFirst);
  }
  // --- END OF FIX ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(
                  Icons.person_pin,
                  size: 100,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 20),

              const Text('Email:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_userEmail, style: const TextStyle(fontSize: 18)),
              const Divider(height: 30),

              const Text('Role:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(_userRole.toUpperCase(), style: const TextStyle(fontSize: 18, color: Colors.blue)),
              const Divider(height: 30),

              // ... (You can add more user info fields here)

              const SizedBox(height: 40),

              // The Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}