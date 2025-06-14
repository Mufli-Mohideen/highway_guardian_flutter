import 'dart:convert';
import 'package:http/http.dart' as http;

class UserLogsService {
  static const String baseUrl = 'http://192.168.8.118:5002/api/logs';
  
  // Get all user logs (simplified, no pagination)
  static Future<List<Map<String, dynamic>>> getUserLogs({
    required int userId,
  }) async {
    try {
      print('🔄 Fetching all user logs for user $userId...');
      print('🌐 Requesting: $baseUrl/user/$userId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout after 15 seconds. Please check your internet connection.');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response headers: ${response.headers}');
      print('📋 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          final logs = List<Map<String, dynamic>>.from(responseData['logs'] ?? []);
          print('✅ Successfully loaded ${logs.length} logs');
          return logs;
        } else {
          print('❌ Backend returned success: false');
          print('❌ Error: ${responseData['error']}');
          print('❌ Details: ${responseData['details']}');
          return [];
        }
      } else if (response.statusCode == 500) {
        print('❌ Server error (500):');
        try {
          final errorData = json.decode(response.body);
          print('❌ Error message: ${errorData['error']}');
          print('❌ Error details: ${errorData['details']}');
          print('❌ Error code: ${errorData['errorCode']}');
        } catch (e) {
          print('❌ Could not parse error response: ${response.body}');
        }
        return [];
      } else {
        print('❌ HTTP error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception in getUserLogs: $e');
      print('❌ Exception type: ${e.runtimeType}');
      return [];
    }
  }

  // Test connection to backend
  static Future<Map<String, dynamic>> testConnection() async {
    try {
      print('🔄 Testing connection to backend...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'), // We might need to create this endpoint
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: 10),
      );

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'body': response.body,
      };
    } catch (e) {
      print('❌ Connection test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Get recent activity
  static Future<List<Map<String, dynamic>>> getRecentActivity({
    required int userId,
    int days = 7,
  }) async {
    try {
      print('🔄 Fetching recent activity for user $userId...');
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId/recent?days=$days'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success']) {
          return List<Map<String, dynamic>>.from(responseData['recent_activity'] ?? []);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error getting recent activity: $e');
      return [];
    }
  }

  // Log points change
  static Future<bool> logPointsChange({
    required int userId,
    required int pointsChange,
    required String activityType,
    String? details,
  }) async {
    try {
      print('🔄 Logging points change: $pointsChange for user $userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/points'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'points_change': pointsChange,
          'activity_type': activityType,
          'details': details,
        }),
      );

      print('📡 Points logging response: ${response.statusCode}');
      print('📋 Points logging body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error logging points change: $e');
      return false;
    }
  }

  // Log highway activity
  static Future<bool> logHighwayActivity({
    required int userId,
    required String activity,
    required String location,
    int? pointsEarned,
  }) async {
    try {
      print('🔄 Logging highway activity: $activity for user $userId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/highway'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'user_id': userId,
          'activity': activity,
          'location': location,
          'points_earned': pointsEarned,
        }),
      );

      print('📡 Highway activity response: ${response.statusCode}');
      print('📋 Highway activity body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error logging highway activity: $e');
      return false;
    }
  }
} 