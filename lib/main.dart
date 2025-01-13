import 'package:flutter/material.dart';
import 'package:highway_guardian/screens/splash_screen.dart';
import 'package:highway_guardian/screens/onboard.dart';
import 'package:highway_guardian/screens/auth/login_screen.dart';
import 'package:highway_guardian/screens/auth/register_screen.dart';
import 'package:highway_guardian/screens/verification_screen.dart';
import 'package:highway_guardian/screens/userdetails_screen.dart';

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
      initialRoute: '/splash',
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
          case '/verification':
            final email = settings.arguments as String;
            return _createRoute(VerificationPage(email: email));
          case '/userdetails':
            final email = settings.arguments as String;
            return _createRoute(UserDetailsPage(email: email));

          default:
            return _createRoute(SplashScreen());
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
          reverseCurve: Curves.easeOut,
        );

        return SlideTransition(
          position: curvedAnimation.drive(tween),
          child: child,
        );
      },
    );
  }
}
