import 'package:flutter/material.dart';
import 'package:highway_guardian/screens/splash_screen.dart';
import 'package:highway_guardian/screens/onboard.dart';

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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash', // Start from splash screen
      routes: {
        '/splash': (context) => SplashScreen(), // Splash screen route
        '/onboard': (context) => OnboardingPage(), // Onboarding page route
      },
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }
}
