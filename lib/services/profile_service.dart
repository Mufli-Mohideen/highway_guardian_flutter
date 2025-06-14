import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user_service.dart';

class ProfileService {
  static const String baseUrl = 'http://192.168.8.118:5002/api/auth';
  
  // Get user profile data
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final email = await UserService.getUserEmail();
      if (email == null || email.isEmpty) {
        print('ProfileService: No email found for profile lookup');
        return null;
      }

      print('ProfileService: Fetching profile for email: $email...');
      
      final response = await http.post(
        Uri.parse('$baseUrl/get-user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'email': email}),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('ProfileService: Profile response status: ${response.statusCode}');
      print('ProfileService: Profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['user'] != null) {
          print('ProfileService: Successfully retrieved user profile');
          return responseData['user'];
        } else {
          print('ProfileService: No user data in response');
          return null;
        }
      } else {
        print('ProfileService: Failed to get profile: ${response.body}');
        return null;
      }
    } catch (e) {
      print('ProfileService: Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile({
    required String name,
    required String email,
    required String address,
    required String phoneNumber,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId == null || userId <= 0) {
        print('ProfileService: No valid user ID found');
        return false;
      }

      print('ProfileService: Updating profile for user $userId...');
      print('ProfileService: Update data - Name: "$name", Email: "$email", Address: "$address", Phone: "$phoneNumber"');
      
      // Get current NIC since backend requires it
      final currentNic = await UserService.getUserNic();
      
      final requestBody = {
        'email': email,
        'name': name,
        'phone': phoneNumber,
        'address': address,
        'nic': currentNic,
      };
      
      print('ProfileService: Request body: ${json.encode(requestBody)}');
      
      // Use the correct endpoint from backend
      final response = await http.post(
        Uri.parse('$baseUrl/update-user'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(
        Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection.');
        },
      );

      print('ProfileService: Update response status: ${response.statusCode}');
      print('ProfileService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Backend returns success message, not success boolean
        if (responseData['message'] != null && responseData['message'].contains('successfully')) {
          print('ProfileService: Backend update successful');
          
          // Use the updated user data returned from backend if available
          Map<String, dynamic> updatedUserData;
          if (responseData['user'] != null) {
            print('ProfileService: Using updated user data from backend response');
            final backendUser = responseData['user'];
            updatedUserData = {
              'name': backendUser['name']?.toString() ?? name,
              'email': backendUser['email']?.toString() ?? email,
              'address': backendUser['address']?.toString() ?? address,
              'phone_number': backendUser['phone_number']?.toString() ?? phoneNumber,
              'nic': backendUser['nic']?.toString() ?? currentNic,
              'id': backendUser['id'] ?? userId,
              'points': backendUser['points'] ?? 0.0,
            };
          } else {
            print('ProfileService: Using local user data for storage');
            // Fallback to local data if backend doesn't return user
            updatedUserData = {
              'name': name,
              'email': email,
              'address': address,
              'phone_number': phoneNumber,
              'nic': currentNic,
              'id': userId,
            };
          }
          
          // Update local storage with new data
          print('ProfileService: Updating local storage...');
          await UserService.saveUserData(updatedUserData);
          
          // Verify the data was saved correctly
          final savedName = await UserService.getUserName();
          final savedEmail = await UserService.getUserEmail();
          final savedAddress = await UserService.getUserAddress();
          final savedPhone = await UserService.getUserPhone();
          
          print('ProfileService: Verification - Saved Name: "$savedName"');
          print('ProfileService: Verification - Saved Email: "$savedEmail"');
          print('ProfileService: Verification - Saved Address: "$savedAddress"');
          print('ProfileService: Verification - Saved Phone: "$savedPhone"');
          
          return true;
        } else {
          final errorMessage = responseData['error'] ?? responseData['message'] ?? 'Unknown error';
          print('ProfileService: Backend returned error: $errorMessage');
          return false;
        }
      } else if (response.statusCode == 400) {
        print('ProfileService: Bad request - checking required fields...');
        final responseData = json.decode(response.body);
        final errorMessage = responseData['error'] ?? 'Invalid request data';
        print('ProfileService: Backend validation error: $errorMessage');
        return false;
      } else if (response.statusCode == 404) {
        print('ProfileService: User not found in backend, updating locally only...');
        
        // If user not found in backend, update locally
        final updatedUserData = {
          'name': name,
          'email': email,
          'address': address,
          'phone_number': phoneNumber,
          'nic': currentNic,
          'id': userId,
        };
        await UserService.saveUserData(updatedUserData);
        return true;
      } else {
        print('ProfileService: HTTP Error ${response.statusCode}: ${response.body}');
        
        // Try to parse error message
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error'] ?? errorData['message'] ?? 'HTTP ${response.statusCode}';
          print('ProfileService: Parsed error: $errorMessage');
        } catch (e) {
          print('ProfileService: Could not parse error response');
        }
        
        return false;
      }
    } catch (e) {
      print('ProfileService: Exception during profile update: $e');
      
      // In case of network issues, still try to update local storage
      // This allows offline functionality
      try {
        print('ProfileService: Attempting local-only update due to network error...');
        final userId = await UserService.getUserId();
        final currentNic = await UserService.getUserNic();
        final updatedUserData = {
          'name': name,
          'email': email,
          'address': address,
          'phone_number': phoneNumber,
          'nic': currentNic,
          'id': userId,
        };
        await UserService.saveUserData(updatedUserData);
        print('ProfileService: Local update completed. Changes will sync when online.');
        return true; // Return success for local update
      } catch (localError) {
        print('ProfileService: Local update also failed: $localError');
        return false;
      }
    }
  }
} 