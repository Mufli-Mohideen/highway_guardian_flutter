import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyService {
  // Use your actual backend IP address instead of localhost
  // Replace this with your actual computer's IP address
  static const String baseUrl = 'http://192.168.8.118:5002/api/emergency';
  
  // Submit SOS Emergency (priority)
  static Future<Map<String, dynamic>> submitSOSEmergency({
    required int userId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      print('🚨 Submitting SOS Emergency for user $userId');
      print('📍 Location: $latitude, $longitude');
      print('📫 Address: $address');

      final response = await http.post(
        Uri.parse('$baseUrl/sos'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'emergency_type': 'SOS',
          'severity': 3, // High severity
          'description': 'Emergency SOS activated - immediate assistance required',
          'services_needed': ['Police', 'Ambulance'],
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('SOS submission timeout. Please try again.');
        },
      );

      print('📡 SOS Response status: ${response.statusCode}');
      print('📋 SOS Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('✅ SOS Emergency submitted successfully: ${responseData['emergency_id']}');
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to submit SOS emergency');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting SOS emergency: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Submit regular emergency
  static Future<Map<String, dynamic>> submitEmergency({
    required int userId,
    required String emergencyType,
    required int severity,
    required String description,
    required double latitude,
    required double longitude,
    required String address,
    required List<String> servicesNeeded,
  }) async {
    try {
      print('📢 Submitting emergency: $emergencyType');
      
      final response = await http.post(
        Uri.parse('$baseUrl/submit'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'emergency_type': emergencyType,
          'severity': severity,
          'description': description,
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'services_needed': servicesNeeded,
        }),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('✅ Emergency submitted successfully: ${responseData['emergency_id']}');
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to submit emergency');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error submitting emergency: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get emergency status
  static Future<Map<String, dynamic>?> getEmergencyStatus(String emergencyId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status/$emergencyId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting emergency status: $e');
      return null;
    }
  }

  // Get user's emergency history
  static Future<List<Map<String, dynamic>>> getUserEmergencies(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          return List<Map<String, dynamic>>.from(responseData['emergencies'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('Error getting user emergencies: $e');
      return [];
    }
  }

  // Update emergency status (for emergency services)
  static Future<bool> updateEmergencyStatus(String emergencyId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update-status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'emergency_id': emergencyId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        print('Emergency status updated successfully');
        return true;
      } else {
        print('Failed to update emergency status: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating emergency status: $e');
      return false;
    }
  }

  // Get unattended emergencies for users to help
  static Future<List<Map<String, dynamic>>> getUnattendedEmergencies() async {
    try {
      print('📡 Fetching unattended emergencies...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/unattended'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('📋 Unattended emergencies response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('✅ Found ${responseData['emergencies'].length} unattended emergencies');
          return List<Map<String, dynamic>>.from(responseData['emergencies'] ?? []);
        } else {
          print('❌ Failed to get unattended emergencies: ${responseData['error']}');
          return [];
        }
      } else {
        print('❌ Server error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error getting unattended emergencies: $e');
      return [];
    }
  }

  // Confirm emergency services have arrived
  static Future<Map<String, dynamic>> confirmEmergencyServicesArrived({
    required String emergencyId,
    required int userId,
  }) async {
    try {
      print('🚑 User $userId confirming emergency services arrived for: $emergencyId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/attend'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'emergency_id': emergencyId,
          'user_id': userId,
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your connection.');
        },
      );

      print('📋 Confirm arrival response: ${response.statusCode}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          print('✅ Successfully confirmed emergency services arrival');
          return responseData;
        } else {
          throw Exception(responseData['error'] ?? 'Failed to confirm arrival');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Emergency not found or already marked as attended');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error confirming emergency services arrival: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Keep the old method for backward compatibility but deprecated
  @deprecated
  static Future<Map<String, dynamic>> attendEmergency({
    required String emergencyId,
    required int userId,
  }) async {
    return confirmEmergencyServicesArrived(
      emergencyId: emergencyId,
      userId: userId,
    );
  }
} 