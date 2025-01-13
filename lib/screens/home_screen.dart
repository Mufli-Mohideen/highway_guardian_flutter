import 'dart:async';
import 'package:flutter/material.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isFinished = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20), // Add some spacing from the top

              // Top Row with Guardian Activated and Notification Bell
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Guardian Activated and Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Styled "Guardian Activated" Text
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Text(
                            'GUARDIAN ACTIVATED,',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.0,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = Colors.white,
                            ),
                          ),
                          const Text(
                            'GUARDIAN ACTIVATED,',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3.0,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Name Text
                      const Text(
                        'Mufli Mohideen', // Replace with dynamic name if needed
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Notification Bell Icon with circular border
                  IconButton(
                    onPressed: () {
                      // Handle notification tap
                      print('Notification tapped');
                    },
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Add some spacing below the row

              // BMW Image directly below the name
              Align(
                alignment: Alignment.centerRight, // Right-align the image
                child: Image.asset(
                  'assets/images/bmw.png',
                  fit: BoxFit.contain,
                  width: 280, // Adjust the size as needed
                ),
              ),
              const SizedBox(height: 20), // Add some spacing below the image

              // Swipeable Button for SOS functionality
              Center(
                child: SwipeableButtonView(
                  buttonText: 'SLIDE TO SOS',
                  buttonWidget: Container(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black,
                    ),
                  ),
                  activeColor: Colors.red,
                  isFinished: isFinished,
                  onWaitingProcess: () {
                    Future.delayed(const Duration(seconds: 2), () {
                      setState(() {
                        isFinished = true;
                      });
                    });
                  },
                  onFinish: () async {
                    // Show SOS screen or action here (you can navigate to a new screen if needed)
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );

                    // Reset the button after finishing
                    setState(() {
                      isFinished = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.red,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Text(
              'SOS Activated!',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: _colorAnimation.value,
              ),
            );
          },
        ),
      ),
    );
  }
}
