import 'dart:async';
import 'package:flutter/material.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:flutter_beep/flutter_beep.dart';
import 'package:flutter/services.dart';
import 'bottom_nav_bar.dart';
import 'qr_scanner_screen.dart';
import 'emergency_screen.dart';
import 'sos_emergency_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/user_service.dart';
import '../services/audio_service.dart';
import '../services/highway_logger.dart';
import '../services/emergency_service.dart';
import '../services/highway_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isFinished = false;
  int availablePoints = 150;
  int _currentIndex = 0; // Default index for Home tab
  
  // User data variables
  String userName = 'Loading...';
  String userEmail = '';
  
  // Highway tracking variables (kept for QR scanning)
  String? entryLocation;
  String? exitLocation;
  String? entryQRCode;
  String? exitQRCode;
  
  // Emergency services variables
  List<Map<String, dynamic>> unattendedEmergencies = [];
  bool isLoadingEmergencies = false;
  Timer? emergencyRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnattendedEmergencies();
    
    // Start auto-refresh for emergencies every 30 seconds
    emergencyRefreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _loadUnattendedEmergencies();
    });
    
    // Initialize audio service
    AudioService.initialize();
  }

  @override
  void dispose() {
    emergencyRefreshTimer?.cancel();
    super.dispose();
  }

  // Method to load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      // First, try to fetch fresh data from backend using stored email
      print('Attempting to fetch fresh user data from backend...');
      final fetchSuccess = await UserService.fetchAndUpdateUserData();
      
      if (fetchSuccess) {
        print('Successfully fetched fresh data from backend');
      } else {
        print('Backend fetch failed, using stored data');
      }
      
      // Now load the data (either fresh from backend or stored)
      final name = await UserService.getUserName();
      final email = await UserService.getUserEmail();
      final points = await UserService.getUserPoints();
      
      print('Loading user data:');
      print('Name: "$name" (length: ${name.length})');
      print('Email: $email');
      print('Points: $points (type: ${points.runtimeType})');
      
      // Generate display name if database name is empty
      String displayName;
      if (name.isEmpty || name == 'Highway Guardian User') {
        if (email.isNotEmpty) {
          // Extract name from email (before @ symbol)
          displayName = email.split('@')[0].replaceAll('.', ' ').replaceAll('_', ' ');
          // Capitalize first letter of each word
          displayName = displayName.split(' ').map((word) => 
            word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : word
          ).join(' ');
          print('Generated display name from email: "$displayName"');
        } else {
          displayName = 'Highway Guardian User';
        }
      } else {
        displayName = name;
      }
      
      setState(() {
        userName = displayName;
        userEmail = email;
        // Ensure points is a valid integer
        availablePoints = points.isNaN ? 150 : points.toInt();
      });
      
      print('User data loaded successfully:');
      print('Display name: $userName');
      print('Display points: $availablePoints');
      
      // Show notification about data source
      if (fetchSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User data refreshed from database'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else if (name.isEmpty && email.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch from database. Check your connection.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        userName = 'Highway Guardian User';
        userEmail = '';
        availablePoints = 150; // Default fallback points
      });
    }
  }

  // Method to refresh user data (can be called when returning to screen)
  Future<void> _refreshUserData() async {
    await _loadUserData();
  }

  // Method to update points (for future use when points change)
  Future<void> _updateUserPoints(int newPoints) async {
    try {
      await UserService.updateUserPoints(newPoints.toDouble());
      setState(() {
        availablePoints = newPoints;
      });
      print('Points updated successfully to: $newPoints');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Points updated: $newPoints'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error updating user points: $e');
    }
  }

  // Method to add points (for highway activities)
  Future<void> _addPoints(int pointsToAdd) async {
    final newTotal = availablePoints + pointsToAdd;
    await _updateUserPoints(newTotal);
  }

  // Method to load unattended emergencies
  Future<void> _loadUnattendedEmergencies() async {
    if (isLoadingEmergencies) return; // Prevent multiple simultaneous calls
    
    setState(() {
      isLoadingEmergencies = true;
    });

    try {
      final emergencies = await EmergencyService.getUnattendedEmergencies();
      setState(() {
        unattendedEmergencies = emergencies;
        isLoadingEmergencies = false;
      });
      print('Loaded ${emergencies.length} unattended emergencies');
    } catch (e) {
      print('Error loading unattended emergencies: $e');
      setState(() {
        isLoadingEmergencies = false;
      });
    }
  }

  // Method to confirm emergency services have arrived
  Future<void> _confirmEmergencyServicesArrived(String emergencyId) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: User not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.blue),
              SizedBox(width: 20),
              Text('Confirming arrival...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      final response = await EmergencyService.confirmEmergencyServicesArrived(
        emergencyId: emergencyId,
        userId: userId,
      );

      Navigator.pop(context); // Close loading dialog

      if (response['success']) {
        // Refresh the emergency list
        await _loadUnattendedEmergencies();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Thank you for confirming our emergency services have arrived'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Play success sound
        HapticFeedback.lightImpact();
        FlutterBeep.beep();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Failed to confirm arrival'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error confirming arrival: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to get points level/tier
  String _getPointsLevel() {
    if (availablePoints >= 1000) return 'Gold Member';
    if (availablePoints >= 500) return 'Silver Member';
    if (availablePoints >= 100) return 'Bronze Member';
    return 'New Member';
  }

  // Method to handle Enter Highway button tap
  Future<void> _onEnterHighway() async {
    final qrResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(action: 'enter'),
      ),
    );
    
    if (qrResult != null) {
      try {
        print('🔍 QR Code Scanned Successfully: $qrResult');
        print('🔍 QR Code Length: ${qrResult.length} characters');
        
        // Parse QR code data
        final highwayInfo = HighwayService.getHighwayInfo(qrResult);
        print('🏁 Highway Info Generated: $highwayInfo');
        
        // Show highway information dialog
        final bool? shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              'Highway Entry Information',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🏁 Toll Booth ID: ${highwayInfo['tollBoothId']}', 
                       style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('📍 Location: ${highwayInfo['location']}', 
                       style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('🕒 Time: ${DateTime.parse(highwayInfo['timestamp']).toLocal().toString().substring(0, 19)}', 
                       style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('🚗 Speed Limit: ${highwayInfo['speedLimit']} km/h', 
                       style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('🏢 Generated By: ${highwayInfo['generatedBy']}', 
                       style: TextStyle(color: Colors.white60, fontSize: 12)),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Text(
                      'ℹ️ You will be charged based on the distance traveled when you exit the highway.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: Colors.red)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('Enter Highway', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (shouldProceed == true) {
          // Show loading dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              content: Row(
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(width: 20),
                  Text('Processing highway entry...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );

          // Get current location
          final position = await HighwayService.getCurrentLocation();
          if (position == null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unable to get location. Please enable GPS and try again.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Extract toll booth name from QR code
          final tollBoothName = highwayInfo['location'];

          // Process highway entry
          final response = await HighwayService.handleHighwayEntry(
            qrCode: qrResult,
            latitude: position.latitude,
            longitude: position.longitude,
            tollBoothName: tollBoothName,
          );

          Navigator.pop(context); // Close loading dialog

          if (response['success']) {
      setState(() {
        entryQRCode = qrResult;
              entryLocation = tollBoothName;
      });
      
            // Refresh user data to show updated points
            await _loadUserData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
                content: Text('Highway entry recorded successfully!\nLocation: $tollBoothName\nSpeed Limit: ${highwayInfo['speedLimit']} km/h'),
          backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['error'] ?? 'Failed to process highway entry'),
                backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
          }
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing highway entry: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Method to handle Exit Highway button tap
  Future<void> _onExitHighway() async {
    final qrResult = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(action: 'exit'),
      ),
    );
    
    if (qrResult != null) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(width: 20),
                Text('Processing highway exit...', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );

        // Get current location
        final position = await HighwayService.getCurrentLocation();
        if (position == null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to get location. Please enable GPS and try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Extract toll booth name from QR code
        final tollBoothName = HighwayService.extractTollBoothName(qrResult);

        // Process highway exit
        final response = await HighwayService.handleHighwayExit(
          qrCode: qrResult,
          latitude: position.latitude,
          longitude: position.longitude,
          tollBoothName: tollBoothName,
        );

        Navigator.pop(context); // Close loading dialog

        if (response['success']) {
      setState(() {
        exitQRCode = qrResult;
            exitLocation = tollBoothName;
      });
      
          // Refresh user data to show updated points
          await _loadUserData();

          // Show detailed exit information
          final pointsDeducted = response['points_deducted'] ?? 0;
          final distance = response['distance_km'] ?? 0.0;
          final entryLocation = response['entry_location'] ?? 'Unknown';
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                'Highway Exit Complete',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✅ Exit processed successfully', style: TextStyle(color: Colors.green)),
                  SizedBox(height: 12),
                  Text('📍 Entry: $entryLocation', style: TextStyle(color: Colors.white70)),
                  Text('📍 Exit: $tollBoothName', style: TextStyle(color: Colors.white70)),
                  SizedBox(height: 8),
                  Text('📏 Distance: ${distance.toStringAsFixed(2)} km', style: TextStyle(color: Colors.blue)),
                  Text('💰 Points deducted: $pointsDeducted', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('🎯 New balance: ${response['new_points_balance']} points', style: TextStyle(color: Colors.green)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK', style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
      );
        } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
              content: Text(response['error'] ?? 'Failed to process highway exit'),
              backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
        }
      } catch (e) {
        Navigator.pop(context); // Close loading dialog if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing highway exit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Styled "Guardian Activated" Text
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              'GUARDIAN ACTIVATED,',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 3
                                  ..color = Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'GUARDIAN ACTIVATED,',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.0,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Name Text - Enhanced display
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                          ),
                          child: Text(
                            userName.isEmpty ? 'Loading User...' : userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification Bell Icon with circular border
                  Container(
                    width: 40, // Fixed width to prevent overflow
                    child: IconButton(
                      onPressed: () {
                        // Handle notification tap
                        print('Notification tapped');
                      },
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 20, // Reduced size
                      ),
                      constraints: BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Add some spacing below the row

              // BMW Image directly below the name
              Align(
                alignment: Alignment.centerRight, // Right-align the image
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
                  ),
                  child: Image.asset(
                    'assets/images/bmw.png',
                    fit: BoxFit.contain,
                    width: 250, // Reduced from 280
                  ),
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
                    // Import and navigate to SOS Emergency Screen
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SOSEmergencyScreen(),
                      ),
                    );

                    // Reset the button after finishing
                    setState(() {
                      isFinished = false;
                    });
                  },
                ),
              ),

              // Modern Available Points Section - Enhanced
              const SizedBox(height: 10), // Spacing between button and points
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Color.fromARGB(255, 0, 31, 85), // Dark blue
                        Color.fromARGB(255, 0, 150, 255), // Lighter blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 8,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Circular Icon with gradient background
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.yellow, Colors.orange],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$availablePoints Points',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${_getPointsLevel()} • Highway Guardian',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Refresh points button
                          IconButton(
                            onPressed: () async {
                              print('Debug: Refreshing points...');
                              await _loadUserData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Points updated: $availablePoints'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 18,
                            ),
                            constraints: BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.all(2),
                          ),
                        ],
                      ),
                      // Add a small progress bar or indicator for points level
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: Colors.white.withOpacity(0.3),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (availablePoints / 1000).clamp(0.0, 1.0), // Assuming 1000 is max
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              gradient: LinearGradient(
                                colors: [Colors.yellow, Colors.orange],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10), // Add some spacing

              // Row for Highway Boxes (Enter and Exit)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Enter Highway Box
                  Expanded(
                    child: GestureDetector(
                      onTap: _onEnterHighway,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(
                              255, 35, 47, 59), // Dark grayish blue
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(47, 47, 47, 1),
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: entryQRCode != null ? Colors.green : Colors.white,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan Entry QR',
                              style: TextStyle(
                                color: entryQRCode != null ? Colors.green : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Exit Highway Box
                  Expanded(
                    child: GestureDetector(
                      onTap: _onExitHighway,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(
                              255, 35, 47, 59), // Dark grayish blue
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(47, 47, 47, 1),
                              blurRadius: 4,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              color: exitQRCode != null ? Colors.red : Colors.white,
                              size: 30,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scan Exit QR',
                              style: TextStyle(
                                color: exitQRCode != null ? Colors.red : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15), // Add some spacing
              
              // Unattended Emergency Services Section
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.emergency,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Emergency Status',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (isLoadingEmergencies)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                              )
                            else
                              IconButton(
                                onPressed: _loadUnattendedEmergencies,
                                icon: Icon(
                                  Icons.refresh,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                padding: EdgeInsets.all(4),
                              ),
                            Text(
                              '${unattendedEmergencies.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    
                    // Emergency Services List
                    Container(
                      height: 140, // Fixed height for scrollable area
                      child: unattendedEmergencies.isEmpty
                          ? Center(
                          child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 32,
                                  ),
                                  SizedBox(height: 8),
                              Text(
                                    isLoadingEmergencies
                                        ? 'Loading emergency status...'
                                        : 'All emergencies have been attended',
                                style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                ),
                                    textAlign: TextAlign.center,
                              ),
                                  if (!isLoadingEmergencies) ...[
                                    SizedBox(height: 4),
                              Text(
                                      'Emergency services are doing great work!',
                                style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                ),
                                      textAlign: TextAlign.center,
                              ),
                            ],
                                ],
                        ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: unattendedEmergencies.length,
                              separatorBuilder: (context, index) => SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final emergency = unattendedEmergencies[index];
                                return _buildEmergencyCard(emergency);
                              },
                            ),
                    ),
                  ],
                ),
              ),
              
              // Add some bottom spacing to ensure content doesn't get cut off
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTabSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // Handle navigation based on selected tab
          switch (index) {
            case 0:
              // Home - already on home screen, do nothing
              break;
            case 1:
              // Emergency - navigate to emergency screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyScreen(),
                ),
              ).then((_) {
                // Reset to home tab when returning from emergency screen
                setState(() {
                  _currentIndex = 0;
                });
              });
              break;
            case 2:
              // History - navigate to history screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              ).then((_) {
                // Reset to home tab when returning from history screen
                setState(() {
                  _currentIndex = 0;
                });
              });
              break;
            case 3:
              // Profile - navigate to profile screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              ).then((_) {
                // Reset to home tab when returning from profile screen
                setState(() {
                  _currentIndex = 0;
                });
                // Refresh user data when returning from profile
                _loadUserData();
              });
              break;
          }
        },
      ),
    );
  }

  // Method to build emergency card
  Widget _buildEmergencyCard(Map<String, dynamic> emergency) {
    final emergencyType = emergency['type'] ?? 'Unknown';
    final severity = emergency['severity'] ?? 1;
    final userName = emergency['user_name'] ?? 'Unknown User';
    final timeAgo = _getTimeAgo(emergency['time']);
    final emergencyId = emergency['emergency_id'] ?? '';

    Color severityColor = Colors.green;
    String severityText = 'Low';
    IconData emergencyIcon = Icons.help_outline;

    // Set severity color and text
    switch (severity) {
      case 1:
        severityColor = Colors.green;
        severityText = 'Low';
        break;
      case 2:
        severityColor = Colors.orange;
        severityText = 'Medium';
        break;
      case 3:
        severityColor = Colors.red;
        severityText = 'High';
        break;
    }

    // Set emergency icon based on type
    switch (emergencyType.toLowerCase()) {
      case 'accident':
        emergencyIcon = Icons.car_crash;
        break;
      case 'medical':
        emergencyIcon = Icons.medical_services;
        break;
      case 'fire':
        emergencyIcon = Icons.local_fire_department;
        break;
      case 'crime':
        emergencyIcon = Icons.security;
        break;
      case 'vehicle breakdown':
        emergencyIcon = Icons.car_repair;
        break;
      case 'road hazard':
        emergencyIcon = Icons.warning;
        break;
      case 'sos':
        emergencyIcon = Icons.sos;
        break;
      default:
        emergencyIcon = Icons.emergency;
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Emergency Icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              emergencyIcon,
              color: severityColor,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          
          // Emergency Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      emergencyType,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        severityText,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Attend Button
          SizedBox(
            width: 70,
            height: 32,
            child: ElevatedButton(
              onPressed: () => _confirmEmergencyServicesArrived(emergencyId),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to calculate time ago
  String _getTimeAgo(String? timeString) {
    if (timeString == null) return 'Unknown time';
    
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}

