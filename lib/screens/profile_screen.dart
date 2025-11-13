// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Added for web checks

// --- THEME COLORS (for consistency, keeping existing where appropriate) ---
const Color kPrimaryGreen = Color(0xFF5E6B5A);
const Color kCreamWhite = Color(0xFFF5F3E9);
const Color kRedError = Color(0xFFD32F2F);
const Color kRichBlack = Color(0xFF1C1C1C); // For text
// --- END OF THEME ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userRole = 'user';
  String? _profileImageUrl;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // STATE VARIABLES FOR LOADING CONTROL
  bool _isInitialDataLoaded = false;
  bool _isImageUploading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndProfile();
  }

  Future<void> _fetchUserRoleAndProfile() async {
    final User? user = _currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _userRole = doc.data()!['role'] ?? 'user';
            _profileImageUrl = doc.data()!['profileImageUrl'] as String?;
            _isInitialDataLoaded = true;
          });
        }
      } else if (mounted) {
        setState(() {
          _isInitialDataLoaded = true;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _isInitialDataLoaded = true;
        });
      }
    }
  }

  // UPDATED: Function to pick and upload image (Web/Mobile compatible with better state handling)
  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      // 1. START LOADING STATE
      setState(() {
        _isImageUploading = true;
        _profileImageUrl = null; // Clear image to show spinner
      });

      bool uploadSuccess = false;

      try {
        String fileName = 'profile_pictures/${_currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Read the file as bytes (universal method for web/mobile)
        final data = await pickedFile.readAsBytes();

        // Upload to Firebase Storage using putData
        UploadTask uploadTask = FirebaseStorage.instance.ref().child(fileName).putData(data);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Update Firestore user document with the new URL
        await _firestore.collection('users').doc(_currentUser!.uid).update({
          'profileImageUrl': downloadUrl,
        });

        // 2. SUCCESS: Update local state and show success
        if (mounted) {
          setState(() {
            _profileImageUrl = downloadUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated!', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        uploadSuccess = true;

      } on FirebaseException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading picture: ${e.message}', style: const TextStyle(color: Colors.white)),
              backgroundColor: kRedError,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurred: ${e.toString()}', style: const TextStyle(color: Colors.white)),
              backgroundColor: kRedError,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        // 3. END LOADING STATE AND REFRESH IF FAILED
        if (mounted) {
          setState(() {
            _isImageUploading = false;
          });
          // If the upload failed to update the image URL, re-fetch the old one to stop the spinner.
          if (!uploadSuccess) {
            _fetchUserRoleAndProfile();
          }
        }
      }
    }
  }

  Future<void> _logOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final String userEmail = _currentUser?.email ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: kRichBlack,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Profile Picture and Upload Button ---
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: kPrimaryGreen.withOpacity(0.1),
                  backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: (_isImageUploading || !_isInitialDataLoaded) // Check both loading states
                      ? const CircularProgressIndicator(color: kPrimaryGreen) // Show spinner
                      : const Icon(Icons.person, size: 60, color: kPrimaryGreen), // Default icon
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _isImageUploading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isImageUploading ? Colors.grey : kPrimaryGreen, // Disable button visually while loading
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Email and Role Card (Styled neutrally) ---
            Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Email:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(userEmail, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: kRichBlack)),
                    const Divider(height: 30, color: Colors.grey),
                    const Text('Role:', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(_userRole.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _userRole == 'admin' ? kRedError : kRichBlack,
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Change Password Form (Fixed to Red Button) ---
            const ChangePasswordForm(),

            const SizedBox(height: 40),

            // --- Log Out Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRedError,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.currentUser!.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _formKey.currentState!.reset();

    } on FirebaseAuthException catch (e) {
      String message = 'Failed to change password.';
      if (e.code == 'requires-recent-login') {
        message = 'Re-login required for security. Please log out, log back in, then try again.';
      } else {
        message = e.message ?? message;
      }

      setState(() {
        _errorMessage = message;
      });

    } catch (e) {
      setState(() {
        _errorMessage = 'An unknown error occurred.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Change Password',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kRichBlack),
        ),
        const Divider(color: Colors.grey),

        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: kRedError, fontWeight: FontWeight.bold),
            ),
          ),

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Min 6 characters',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  fillColor: Colors.white,
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password.';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset),
                  fillColor: Colors.white,
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new password.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRedError,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text(
                    'Change Password',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}