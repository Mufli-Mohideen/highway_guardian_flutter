import 'package:flutter/material.dart';
import 'package:highway_guardian/screens/splash_screen.dart';
import 'package:highway_guardian/screens/onboard.dart';
import 'package:highway_guardian/screens/auth/login_screen.dart';
import 'package:highway_guardian/screens/auth/register_screen.dart';
import 'package:highway_guardian/screens/verification_screen.dart';
import 'package:highway_guardian/screens/userdetails_screen.dart';
import 'package:highway_guardian/screens/settingup_screen.dart';
import 'package:highway_guardian/screens/home_screen.dart';
import 'package:highway_guardian/screens/sos_emergency_screen.dart';
import 'package:highway_guardian/screens/emergency_confirmation_screen.dart';

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
          case '/settingup':
            return _createRoute(SettingUpScreen());
          case '/home':
            return _createRoute(HomeScreen());
          case '/sos-emergency':
            return _createRoute(SOSEmergencyScreen());
          case '/emergency-confirmation':
            final args = settings.arguments as Map<String, dynamic>;
            return _createRoute(EmergencyConfirmationScreen(
              emergencyId: args['emergency_id'],
              emergencyType: args['emergency_type'],
              servicesDispatched: List<String>.from(args['services_dispatched'] ?? []),
              estimatedResponseTime: args['estimated_response_time'] ?? 'Unknown',
            ));
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
        // Slide transition
        const begin = Offset(0.0, 0.1); // Slight vertical slide
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var slideTween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var slideAnimation = animation.drive(slideTween);

        // Fade transition
        var fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: Duration(milliseconds: 400), // Adjust duration
    );
  }
}
