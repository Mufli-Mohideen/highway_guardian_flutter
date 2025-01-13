import 'package:flutter/material.dart';

class SettingUpScreen extends StatefulWidget {
  @override
  _SettingUpScreenState createState() => _SettingUpScreenState();
}

class _SettingUpScreenState extends State<SettingUpScreen> {
  @override
  void initState() {
    super.initState();

    // Redirect to the home screen after 7 seconds
    Future.delayed(const Duration(seconds: 7), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'SETTING UP',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5.0,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Colors.white,
                    ),
                  ),
                  const Text(
                    'SETTING UP',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // GIF Image
              Image.asset(
                'assets/images/gauge.gif',
                width: 350,
                height: 350,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              // "Please Wait..." Text
              const Text(
                'PLEASE WAIT...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 160),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Highway Guardian © 2025 All rights reserved',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
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
