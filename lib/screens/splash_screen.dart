import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Import loading animation package

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        // Make the container fill the whole screen
        child: Container(
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Adding padding to create margin above the title
              Padding(
                padding: const EdgeInsets.only(top: 100.0),
                child: Text(
                  'HIGHWAY GUARDIAN',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // White text
                  ),
                ),
              ),
              SizedBox(height: 50),

              // Preloader GIF with border radius
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(10.0), // Adjust radius as needed
                child: Image.asset(
                  'assets/images/preloader.gif',
                  width: 275, // Adjust width
                  height: 275,
                  fit: BoxFit
                      .cover, // Optional: makes sure the image is fitted within the container
                ),
              ),

              SizedBox(height: 40),

              // Add the "LOADING..." text
              Text(
                'LOADING...',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.white, // White text for the loading message
                ),
              ),

              SizedBox(
                  height: 20), // Add some spacing before the loading animation

              // Loading animation widget
              LoadingAnimationWidget.threeArchedCircle(
                color: Colors.white,
                size: 50, // Adjust the size of the loader
              ),

              Spacer(), // Push the footer text to the bottom

              // Footer Text
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 20.0), // Add spacing at the bottom
                child: Text(
                  '© 2025 All Rights Reserved',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 14, // Small footer text
                    color: Colors.white54, // Slightly transparent white
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
