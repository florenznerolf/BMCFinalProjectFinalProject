import 'package:flutter/material.dart';

// 1. Import the Firebase core package
import 'package:firebase_core/firebase_core.dart';
// 2. Import the auto-generated Firebase options file
import 'firebase_options.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:smarthomedevices_app/screens/auth_wrapper.dart';

import 'package:smarthomedevices_app/providers/cart_provider.dart'; // 1. ADD THIS
import 'package:provider/provider.dart'; // 2. Need this
import 'package:firebase_auth/firebase_auth.dart'; // Import for Persistence
import 'package:google_fonts/google_fonts.dart'; // 1. ADD THIS IMPORT


const Color kRichBlack = Color(0xFF1C1C1C); // A very dark, rich black for text
const Color kPrimaryGreen = Color(0xFF5E6B5A); // The muted sage/olive green from your logo
const Color kCreamWhite = Color(0xFFF5F3E9); // The warm, off-white from your logo's circle
const Color kAppBackground = Color(0xFFF8F4F0); // A clean, warm off-white for the app background
// --- END OF COLOR PALETTE ---


void main() async {

  // 1. Preserve the splash screen (Unchanged)
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Initialize Firebase (Unchanged)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Set web persistence (Unchanged)
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  // 4. --- THIS IS THE FIX ---
  // We manually create the CartProvider instance *before* runApp
  final cartProvider = CartProvider();

  // 5. We call our new initialize method *before* runApp
  cartProvider.initializeAuthListener();

  // 6. This is the old, buggy code we are replacing:
  /*
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(), // <-- This was the problem

      child: const MyApp(),
    ),
  );
  */

  // 7. This is the NEW code for runApp
  runApp(
    // 8. We use ChangeNotifierProvider.value
    ChangeNotifierProvider.value(
      value: cartProvider, // 9. We provide the instance we already created
      child: const MyApp(),
    ),
  );

  // 10. Remove the splash screen after app is ready (Unchanged)
  FlutterNativeSplash.remove();
}


class MyApp extends StatelessWidget {
  // ... (const MyApp)
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Home Devices',

      // 1. --- (UPDATED) THIS IS THE NEW, COMPLETE THEME ---
      theme: ThemeData(
        // 2. Set the main color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryGreen, // Our new primary color
          brightness: Brightness.light,
          primary: kPrimaryGreen,
          onPrimary: Colors.white, // Text on top of the green (e.g., in buttons)
          secondary: kCreamWhite,
          background: kAppBackground, // Our new app background
        ),
        useMaterial3: true,

        // 3. Set the background color for all screens
        scaffoldBackgroundColor: kAppBackground,

        // 4. --- (FIX) APPLY THE GOOGLE FONT ---
        // This applies "Lato" to all text in the app
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ),

        // 5. --- (FIX) GLOBAL BUTTON STYLE ---
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryGreen, // Use our new green
            foregroundColor: Colors.white, // Text color
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
          ),
        ),

        // 6. --- (FIX) GLOBAL TEXT FIELD STYLE ---
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          labelStyle: TextStyle(color: kPrimaryGreen.withOpacity(0.8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kPrimaryGreen, width: 2.0),
          ),
        ),

        // 7. --- (FIX) GLOBAL CARD STYLE ---
        cardTheme: CardThemeData(
          elevation: 1, // A softer shadow
          color: kCreamWhite, // Use cream for cards
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          // 8. This ensures the images inside the card are rounded
          clipBehavior: Clip.antiAlias,
        ),

        // 9. --- (NEW) GLOBAL APPBAR STYLE ---
        appBarTheme: AppBarTheme(
          backgroundColor: kCreamWhite, // Clean cream AppBar
          foregroundColor: kRichBlack, // Black icons and text
          elevation: 0, // No shadow, modern look
          centerTitle: true,
        ),
      ),
      // --- END OF NEW THEME ---

      // 1. Change this line
      home: const AuthWrapper(), // 2. Set LoginScreen as the home
    );
  }
}