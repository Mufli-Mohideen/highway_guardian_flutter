import 'package:flutter/material.dart';
import 'package:highway_guardian/screens/splash_screen.dart';
import 'package:highway_guardian/screens/onboard.dart';
import 'package:highway_guardian/screens/auth/login_screen.dart';
import 'package:highway_guardian/screens/auth/register_screen.dart';

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
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return _createRoute(SplashScreen());
          case '/onboard':
            return _createRoute(OnboardingPage());
          case '/login':
            return _createRoute(LoginPage());
          case '/register':
            return _createRoute(RegisterPage());
          default:
            return null;
        }
      },
      debugShowCheckedModeBanner: false, // Disable the debug banner
    );
  }

  // Custom Route with Smoother Transition
  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use a smoother curve and adjust the duration for the animation
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        // Duration of the transition (increased for smoother effect)
        var duration = const Duration(milliseconds: 500);

        // Animation controller driving the transition with smoother timing
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: Curves.easeOut,
        );

        // Return SlideTransition with smoothed out animation
        return SlideTransition(
          position: curvedAnimation.drive(tween),
          child: child,
        );
      },
    );
  }
}
