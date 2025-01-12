import 'package:flutter/material.dart';
import 'package:highway_guardian/screens/splash_screen.dart'; // Import splash screen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Highway Guardian',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Set primary color
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash', // Start from splash screen
      routes: {
        '/splash': (context) => SplashScreen(), // Define splash screen route
        // You can add other routes like '/home', '/history', etc.
      },
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }
}
