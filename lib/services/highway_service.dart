import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'user_service.dart';

class HighwayService {
  static const String baseUrl = 'http://192.168.8.118:5002/api/highway';
  
  // Handle highway entry
  static Future<Map<String, dynamic>> handleHighwayEntry({
    required String qrCode,
    required double latitude,
    required double longitude,
    required String tollBoothName,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not found');
      }

      print('🛣️ Highway Entry Request:');
      print('User ID: $userId');
      print('QR Code: $qrCode');
      print('Location: $latitude, $longitude');
      print('Toll Booth: $tollBoothName');

      final response = await http.post(
        Uri.parse('$baseUrl/entry'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'qr_code': qrCode,
          'latitude': latitude,
          'longitude': longitude,
          'toll_booth_name': tollBoothName,
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('📡 Highway Entry Response: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('✅ Highway entry successful');
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to enter highway');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error entering highway: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Handle highway exit
  static Future<Map<String, dynamic>> handleHighwayExit({
    required String qrCode,
    required double latitude,
    required double longitude,
    required String tollBoothName,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        throw Exception('User not found');
      }

      print('🛣️ Highway Exit Request:');
      print('User ID: $userId');
      print('QR Code: $qrCode');
      print('Location: $latitude, $longitude');
      print('Toll Booth: $tollBoothName');

      final response = await http.post(
        Uri.parse('$baseUrl/exit'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'qr_code': qrCode,
          'latitude': latitude,
          'longitude': longitude,
          'toll_booth_name': tollBoothName,
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('📡 Highway Exit Response: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('✅ Highway exit successful');
          print('💰 Points deducted: ${responseData['points_deducted']}');
          print('📏 Distance: ${responseData['distance_km']}km');
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to exit highway');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error exiting highway: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get active highway session
  static Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/active/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          return responseData['active_session'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting active session: $e');
      return null;
    }
  }

  // Get highway history
  static Future<List<Map<String, dynamic>>> getHighwayHistory() async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/history/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          return List<Map<String, dynamic>>.from(responseData['sessions'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting highway history: $e');
      return [];
    }
  }

  // Get current location
  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  // Parse QR code JSON data
  static Map<String, dynamic>? parseQRData(String qrCode) {
    try {
      print('📱 Raw QR Code Content: $qrCode');
      print('📱 QR Code Length: ${qrCode.length} characters');
      
      final Map<String, dynamic> qrData = json.decode(qrCode);
      print('✅ Successfully parsed QR JSON:');
      print('   - tollBoothId: ${qrData['tollBoothId']}');
      print('   - location: ${qrData['location']}');
      print('   - coordinates: ${qrData['coordinates']}');
      print('   - timestamp: ${qrData['timestamp']}');
      print('   - generatedBy: ${qrData['generatedBy']}');
      print('📱 Full Parsed QR Data: $qrData');
      return qrData;
    } catch (e) {
      print('❌ Error parsing QR code JSON: $e');
      print('📱 Raw QR Code Content was: "$qrCode"');
      print('🔍 QR Code Type: ${qrCode.runtimeType}');
      return null;
    }
  }

  // Extract toll booth name from QR code JSON
  static String extractTollBoothName(String qrCode) {
    final qrData = parseQRData(qrCode);
    if (qrData != null && qrData.containsKey('location')) {
      return qrData['location'] ?? 'Unknown Location';
    }
    
    // Fallback to old method if JSON parsing fails
    if (qrCode.contains('entry')) {
      return 'Entry Toll Booth ${qrCode.substring(qrCode.length - 4)}';
    } else if (qrCode.contains('exit')) {
      return 'Exit Toll Booth ${qrCode.substring(qrCode.length - 4)}';
    } else {
      return 'Highway Toll Booth ${qrCode.substring(qrCode.length - 4)}';
    }
  }

  // Get highway information from QR code
  static Map<String, dynamic> getHighwayInfo(String qrCode) {
    final qrData = parseQRData(qrCode);
    final currentTime = DateTime.now().toIso8601String();
    
    if (qrData != null) {
      return {
        'tollBoothId': qrData['tollBoothId'] ?? 'Unknown',
        'location': qrData['location'] ?? 'Unknown Location',
        'coordinates': qrData['coordinates'] ?? {'lat': 0.0, 'lon': 0.0},
        'timestamp': currentTime, // Use device time
        'speedLimit': 100, // Set speed limit to 100
        'generatedBy': qrData['generatedBy'] ?? 'Highway Guardian System',
        'originalQR': qrCode,
      };
    } else {
      // Fallback for non-JSON QR codes
      return {
        'tollBoothId': 'Unknown',
        'location': extractTollBoothName(qrCode),
        'coordinates': {'lat': 0.0, 'lon': 0.0},
        'timestamp': currentTime,
        'speedLimit': 100,
        'generatedBy': 'Highway Guardian System',
        'originalQR': qrCode,
      };
    }
  }
} 