import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../services/emergency_service.dart';
import '../services/user_service.dart';
import '../services/audio_service.dart';
import 'home_screen.dart';
import 'emergency_confirmation_screen.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({Key? key}) : super(key: key);

  @override
  _EmergencyScreenState createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  String selectedEmergencyType = '';
  int selectedSeverity = 1; // 1=Low, 2=Medium, 3=High
  bool policeRequired = false;
  bool ambulanceRequired = false;
  bool repairRequired = false;
  bool fireServiceRequired = false;
  
  Position? currentPosition;
  String currentAddress = 'Location not available';
  bool isSubmitting = false;
  
  final List<Map<String, dynamic>> emergencyTypes = [
    {'type': 'Accident', 'icon': Icons.car_crash, 'color': Colors.red},
    {'type': 'Medical', 'icon': Icons.medical_services, 'color': Colors.blue},
    {'type': 'Fire', 'icon': Icons.local_fire_department, 'color': Colors.orange},
    {'type': 'Crime', 'icon': Icons.security, 'color': Colors.purple},
    {'type': 'Vehicle Breakdown', 'icon': Icons.car_repair, 'color': Colors.green},
    {'type': 'Road Hazard', 'icon': Icons.warning, 'color': Colors.yellow},
    {'type': 'Weather Emergency', 'icon': Icons.storm, 'color': Colors.indigo},
    {'type': 'Other', 'icon': Icons.help_outline, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    AudioService.initialize();
  }

  // Generate shorter emergency ID
  String _generateEmergencyId() {
    final now = DateTime.now();
    // Format: EM + last 4 digits of timestamp (e.g., EM1701)
    final timeStamp = now.millisecondsSinceEpoch.toString();
    final shortId = timeStamp.substring(timeStamp.length - 4);
    return 'EM$shortId';
  }

  // Enhanced location permission handling based on geolocator best practices
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location services are disabled. Please enable the services'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are denied'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permissions are permanently denied, we cannot request permissions.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    try {
      setState(() {
        // Show loading state
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );
      
      setState(() {
        currentPosition = position;
      });
      
      print('Location obtained: ${position.latitude}, ${position.longitude}');
      
      // Get address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            currentAddress = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}'.replaceAll(RegExp(r'^,\s*|,\s*$'), '').replaceAll(RegExp(r',\s*,'), ',');
          });
          print('Address obtained: $currentAddress');
        }
      } catch (e) {
        print('Error getting address: $e');
        setState(() {
          currentAddress = 'Address lookup failed';
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location detected successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        currentAddress = 'Location detection failed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.green;
    }
  }

  String _getSeverityText(int severity) {
    switch (severity) {
      case 1: return 'Low';
      case 2: return 'Medium';
      case 3: return 'High';
      default: return 'Low';
    }
  }

  IconData _getSeverityIcon(int severity) {
    switch (severity) {
      case 1: return Icons.info_outline;
      case 2: return Icons.warning_amber;
      case 3: return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }

  List<String> _getSelectedServices() {
    List<String> services = [];
    if (policeRequired) services.add('Police');
    if (ambulanceRequired) services.add('Ambulance');
    if (repairRequired) services.add('Repair');
    if (fireServiceRequired) services.add('Fire Service');
    return services;
  }

  Future<void> _submitEmergency() async {
    if (selectedEmergencyType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an emergency type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!policeRequired && !ambulanceRequired && !repairRequired && !fireServiceRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Play emergency sound
      AudioService.playEmergencyStartSound();
      HapticFeedback.heavyImpact();

      // Get user ID
      final userId = await UserService.getUserId();
      
      // Generate unique emergency ID
      final emergencyId = _generateEmergencyId();

      // Submit emergency to backend
      final response = await EmergencyService.submitEmergency(
        userId: userId ?? 0,
        emergencyType: selectedEmergencyType,
        severity: selectedSeverity,
        description: 'Emergency reported via Highway Guardian app',
        latitude: currentPosition?.latitude ?? 0.0,
        longitude: currentPosition?.longitude ?? 0.0,
        address: currentAddress,
        servicesNeeded: _getSelectedServices(),
      );

      if (response['success']) {
        final emergencyId = response['emergency_id'];
        
        // Show success and navigate to confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency submitted successfully! Help is on the way.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate to emergency confirmation screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyConfirmationScreen(
              emergencyId: emergencyId,
              emergencyType: selectedEmergencyType,
              servicesDispatched: _getSelectedServices(),
              estimatedResponseTime: '10-15 minutes',
            ),
          ),
        );
      } else {
        throw Exception(response['error'] ?? 'Failed to submit emergency');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting emergency: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        title: Text(
          'Emergency Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.red[900]!, Colors.black, Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.red, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Assistance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Help will be dispatched to your location',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Emergency Type Selection
                Text(
                  'What type of emergency?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                  ),
                  itemCount: emergencyTypes.length,
                  itemBuilder: (context, index) {
                    final type = emergencyTypes[index];
                    final isSelected = selectedEmergencyType == type['type'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmergencyType = type['type'];
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? type['color'].withOpacity(0.3)
                            : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                              ? type['color']
                              : Colors.white.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type['icon'],
                              color: isSelected ? type['color'] : Colors.white70,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                type['type'],
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 24),

                // Severity Selection
                Text(
                  'Emergency Severity',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [1, 2, 3].map((severity) {
                    final isSelected = selectedSeverity == severity;
                    final color = _getSeverityColor(severity);
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedSeverity = severity;
                          });
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                              ? color.withOpacity(0.3)
                              : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? color : Colors.white.withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getSeverityIcon(severity),
                                color: isSelected ? color : Colors.white70,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                _getSeverityText(severity),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 24),

                // Service Selection
                Text(
                  'Required Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                
                // Police
                _buildServiceTile(
                  icon: Icons.local_police,
                  title: 'Police',
                  subtitle: 'For crimes, accidents, or security issues',
                  isSelected: policeRequired,
                  onTap: () => setState(() => policeRequired = !policeRequired),
                  color: Colors.blue,
                ),
                
                SizedBox(height: 8),
                
                // Ambulance
                _buildServiceTile(
                  icon: Icons.medical_services,
                  title: 'Ambulance',
                  subtitle: 'For medical emergencies or injuries',
                  isSelected: ambulanceRequired,
                  onTap: () => setState(() => ambulanceRequired = !ambulanceRequired),
                  color: Colors.red,
                ),
                
                SizedBox(height: 8),
                
                // Repair Service
                _buildServiceTile(
                  icon: Icons.build,
                  title: 'Repair Service',
                  subtitle: 'For vehicle breakdowns or towing',
                  isSelected: repairRequired,
                  onTap: () => setState(() => repairRequired = !repairRequired),
                  color: Colors.green,
                ),
                
                SizedBox(height: 8),
                
                // Fire Service
                _buildServiceTile(
                  icon: Icons.local_fire_department,
                  title: 'Fire Service',
                  subtitle: 'For fires or hazardous materials',
                  isSelected: fireServiceRequired,
                  onTap: () => setState(() => fireServiceRequired = !fireServiceRequired),
                  color: Colors.orange,
                ),

                SizedBox(height: 24),

                // Location Info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            currentPosition != null ? Icons.location_on : Icons.location_off,
                            color: currentPosition != null ? Colors.green : Colors.red,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  currentPosition != null
                                    ? 'Location detected: ${currentPosition!.latitude.toStringAsFixed(6)}, ${currentPosition!.longitude.toStringAsFixed(6)}'
                                    : 'Location not available - tap refresh to try again',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _getCurrentLocation,
                            icon: Icon(
                              Icons.refresh,
                              color: Colors.blue,
                              size: 20,
                            ),
                            tooltip: 'Refresh Location',
                          ),
                        ],
                      ),
                      if (currentPosition == null) ...[
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: Icon(Icons.my_location, size: 18),
                            label: Text('Get My Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // Submit Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _submitEmergency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 8,
                    ),
                    child: isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Submitting Emergency...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emergency, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'SUBMIT EMERGENCY',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                  ),
                ),

                SizedBox(height: 16),

                // Disclaimer
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.yellow.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.yellow, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will alert emergency services and share your location. Only use for real emergencies.',
                          style: TextStyle(
                            color: Colors.yellow[100],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? color.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.white70,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
