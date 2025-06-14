import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/emergency_service.dart';
import '../services/user_service.dart';
import '../services/audio_service.dart';
import 'emergency_confirmation_screen.dart';

class SOSEmergencyScreen extends StatefulWidget {
  const SOSEmergencyScreen({Key? key}) : super(key: key);

  @override
  _SOSEmergencyScreenState createState() => _SOSEmergencyScreenState();
}

class _SOSEmergencyScreenState extends State<SOSEmergencyScreen>
    with TickerProviderStateMixin {
  
  // Countdown variables
  int _countdown = 10;
  bool _isCountdownActive = true;
  bool _isEmergencyActivated = false;
  bool _isCancelled = false;
  Timer? _countdownTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  // Location variables
  Position? _currentPosition;
  String _currentAddress = 'Getting location...';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
    _startCountdown();
    AudioService.initialize();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _pulseController.repeat(reverse: true);
    _scaleController.forward();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentPosition = position;
          _currentAddress = '${place.street ?? ''}, ${place.locality ?? ''}'.replaceAll(RegExp(r'^,\s*|,\s*$'), '');
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Location unavailable';
      });
    }
  }

  void _startCountdown() {
    AudioService.playEmergencyStartSound();
    
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0 && !_isCancelled) {
        AudioService.playCountdownBeep();
        HapticFeedback.mediumImpact();
        
        setState(() {
          _countdown--;
        });
        
      } else {
        timer.cancel();
        if (!_isCancelled) {
          _activateEmergency();
        }
      }
    });
  }

  void _activateEmergency() async {
    setState(() {
      _isCountdownActive = false;
      _isEmergencyActivated = true;
    });

    HapticFeedback.heavyImpact();
    AudioService.playEmergencyActiveSound();

    await _submitSOSEmergency();
  }

  Future<void> _submitSOSEmergency() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        _showErrorMessage('User not found. Please login again.');
        return;
      }

      final response = await EmergencyService.submitSOSEmergency(
        userId: userId,
        latitude: _currentPosition?.latitude ?? 0.0,
        longitude: _currentPosition?.longitude ?? 0.0,
        address: _currentAddress,
      );

      if (response['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyConfirmationScreen(
              emergencyId: response['emergency_id'] ?? 'Unknown',
              emergencyType: 'SOS Emergency',
              servicesDispatched: List<String>.from(response['services_dispatched'] ?? []),
              estimatedResponseTime: response['estimated_response_time'] ?? '5-8 minutes',
            ),
          ),
        );
      } else {
        _showErrorMessage(response['error'] ?? 'Failed to submit SOS emergency');
      }
    } catch (e) {
      _showErrorMessage('Error submitting SOS emergency: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _cancelEmergency() {
    setState(() {
      _isCancelled = true;
      _isEmergencyActivated = false;
      _countdown = 10;
    });

    _pulseController.stop();
    _pulseController.reset();
    _countdownTimer?.cancel();

    AudioService.stopAllAudio();
    AudioService.playCancellationSound();
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SOS Emergency cancelled'),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _scaleController.dispose();
    AudioService.stopAllAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isCountdownActive && !_isCancelled) {
          _cancelEmergency();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: () {
            if (_isCountdownActive && !_isCancelled) {
              _cancelEmergency();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isEmergencyActivated 
                  ? [
                      Color(0xFF1B5E20),
                      Color(0xFF2E7D32),
                      Color(0xFF388E3C),
                      Color(0xFF1B5E20),
                    ]
                  : [
                      Color(0xFF8B0000),
                      Color(0xFFB71C1C),
                      Color(0xFFD32F2F),
                      Color(0xFF8B0000),
                    ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    
                    // Modern Header
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Column(
                            children: [
                              Text(
                                _isEmergencyActivated ? 'SOS ACTIVATED' : 'SOS EMERGENCY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Colors.black.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!_isEmergencyActivated) ...[
                                SizedBox(height: 8),
                                Text(
                                  'Emergency activation in progress',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Modern Main Circle
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 280,
                                    height: 280,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: _isEmergencyActivated 
                                          ? [
                                              Color(0xFF4CAF50),
                                              Color(0xFF2E7D32),
                                              Color(0xFF1B5E20),
                                            ]
                                          : [
                                              Color(0xFFFF5252),
                                              Color(0xFFD32F2F),
                                              Color(0xFFB71C1C),
                                            ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isEmergencyActivated 
                                            ? Color(0xFF4CAF50) 
                                            : Color(0xFFFF5252)).withOpacity(0.4),
                                          blurRadius: 40,
                                          spreadRadius: 0,
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Container(
                                      margin: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.1),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: _isEmergencyActivated
                                          ? Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white.withOpacity(0.2),
                                                  ),
                                                  child: Icon(
                                                    Icons.check_circle_outline,
                                                    color: Colors.white,
                                                    size: 60,
                                                  ),
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'SUCCESS',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 3,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Text(
                                              '$_countdown',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 100,
                                                fontWeight: FontWeight.w300,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0, 4),
                                                    blurRadius: 8,
                                                    color: Colors.black.withOpacity(0.3),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            SizedBox(height: 50),
                            
                            // Modern Status Card
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 30),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Column(
                                    children: [
                                      if (_isCountdownActive && !_isEmergencyActivated) ...[
                                        Icon(
                                          Icons.touch_app_outlined,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 24,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'TAP TO CANCEL',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Tap anywhere or press back',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                      
                                      if (_isEmergencyActivated) ...[
                                        Icon(
                                          Icons.emergency_outlined,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 24,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Emergency Services Notified',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Help is on the way',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 