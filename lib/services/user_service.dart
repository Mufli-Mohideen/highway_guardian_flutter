import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserService {
  static const String _userDataKey = 'userData';
  static const String _userNameKey = 'userName';
  static const String _userEmailKey = 'userEmail';
  static const String _userPhoneKey = 'userPhone';
  static const String _userAddressKey = 'userAddress';
  static const String _userNicKey = 'userNic';
  static const String _userPointsKey = 'userPoints';
  static const String _userIdKey = 'userId';

  // Save complete user data
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    
    print('UserService: Saving user data...');
    print('Original response: ${jsonEncode(userData)}');
    
    // Save the complete user data as JSON
    await prefs.setString(_userDataKey, jsonEncode(userData));
    
    String nameToSave = '';
    String emailToSave = '';
    String phoneToSave = '';
    String addressToSave = '';
    String nicToSave = '';
    double pointsToSave = 0.0;
    int idToSave = 0;
    
    // Also save individual fields for easier access
    if (userData.containsKey('user')) {
      final user = userData['user'];
      print('UserService: Found user object in response');
      print('User data: ${jsonEncode(user)}');
      
      nameToSave = user['name']?.toString() ?? '';
      emailToSave = user['email']?.toString() ?? '';
      phoneToSave = user['phone_number']?.toString() ?? '';
      addressToSave = user['address']?.toString() ?? '';
      nicToSave = user['nic']?.toString() ?? '';
      pointsToSave = (user['points'] ?? 0.0).toDouble();
      idToSave = user['id'] ?? 0;
      
      print('UserService: Parsed name field: "${nameToSave}" (length: ${nameToSave.length})');
      print('UserService: Name is null? ${user['name'] == null}');
      print('UserService: Name is empty? ${user['name']?.toString().isEmpty ?? true}');
      
    } else {
      // Fallback if the response structure is different
      print('UserService: No user object found, using direct fields');
      
      nameToSave = userData['name']?.toString() ?? '';
      emailToSave = userData['email']?.toString() ?? '';
      phoneToSave = userData['phone_number']?.toString() ?? '';
      addressToSave = userData['address']?.toString() ?? '';
      nicToSave = userData['nic']?.toString() ?? '';
      pointsToSave = (userData['points'] ?? 0.0).toDouble();
      idToSave = userData['id'] ?? 0;
      
      print('UserService: Parsed name field: "${nameToSave}" (length: ${nameToSave.length})');
      print('UserService: Name is null? ${userData['name'] == null}');
      print('UserService: Name is empty? ${userData['name']?.toString().isEmpty ?? true}');
    }
    
    // Save all fields
    await prefs.setString(_userNameKey, nameToSave);
    await prefs.setString(_userEmailKey, emailToSave);
    await prefs.setString(_userPhoneKey, phoneToSave);
    await prefs.setString(_userAddressKey, addressToSave);
    await prefs.setString(_userNicKey, nicToSave);
    await prefs.setDouble(_userPointsKey, pointsToSave);
    await prefs.setInt(_userIdKey, idToSave);
    
    print('UserService: User data saved successfully');
    print('UserService: Final saved name: "${nameToSave}"');
  }

  // Get user name
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'Highway Guardian User';
  }

  // Get user email
  static Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey) ?? '';
  }

  // Get user points
  static Future<double> getUserPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_userPointsKey) ?? 150.0;
  }

  // Get user ID
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey) ?? 0;
  }

  // Get user phone
  static Future<String> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPhoneKey) ?? '';
  }

  // Get user address
  static Future<String> getUserAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAddressKey) ?? '';
  }

  // Get user NIC
  static Future<String> getUserNic() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNicKey) ?? '';
  }

  // Update user points
  static Future<void> updateUserPoints(double points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_userPointsKey, points);
  }

  // Get complete user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Clear user data (for logout)
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPhoneKey);
    await prefs.remove(_userAddressKey);
    await prefs.remove(_userNicKey);
    await prefs.remove(_userPointsKey);
    await prefs.remove(_userIdKey);
  }

  // Fetch fresh user data from backend using email
  static Future<bool> fetchAndUpdateUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString(_userEmailKey);
      
      if (email == null || email.isEmpty) {
        print('UserService: No email found, cannot fetch user data');
        return false;
      }
      
      print('UserService: Fetching user data for email: $email');
      
      // Try multiple endpoints in case one doesn't exist
      final endpoints = [
        {'url': 'http://192.168.8.118:5002/api/auth/get-user', 'method': 'POST'},
        {'url': 'http://192.168.8.118:5002/api/user/profile', 'method': 'POST'},
        {'url': 'http://192.168.8.118:5002/api/users/$email', 'method': 'GET'},
        {'url': 'http://192.168.8.118:5002/api/auth/profile', 'method': 'POST'},
      ];
      
      for (final endpoint in endpoints) {
        try {
          print('UserService: Trying ${endpoint['method']} ${endpoint['url']}');
          
          http.Response response;
          
          if (endpoint['method'] == 'POST') {
            response = await http.post(
              Uri.parse(endpoint['url']!),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email}),
            );
          } else {
            response = await http.get(
              Uri.parse(endpoint['url']!),
              headers: {'Content-Type': 'application/json'},
            );
          }
          
          print('UserService: Response status: ${response.statusCode}');
          print('UserService: Response body: ${response.body}');
          
          if (response.statusCode == 200) {
            final userData = jsonDecode(response.body);
            
            // Save the fresh user data
            await saveUserData(userData);
            
            print('UserService: Successfully fetched and updated user data from ${endpoint['url']}');
            return true;
          }
          
        } catch (e) {
          print('UserService: Error with ${endpoint['url']}: $e');
          continue; // Try next endpoint
        }
      }
      
      print('UserService: All endpoints failed');
      return false;
      
    } catch (e) {
      print('UserService: Error fetching user data: $e');
      return false;
    }
  }

  // Debug method to check all stored user data
  static Future<void> debugUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('=== DEBUG: All stored user data ===');
    print('Raw userData JSON: ${prefs.getString(_userDataKey)}');
    print('Stored userName: "${prefs.getString(_userNameKey)}"');
    print('Stored userEmail: "${prefs.getString(_userEmailKey)}"');
    print('Stored userPhone: "${prefs.getString(_userPhoneKey)}"');
    print('Stored userPoints: ${prefs.getDouble(_userPointsKey)}');
    print('Stored userId: ${prefs.getInt(_userIdKey)}');
    print('=== END DEBUG ===');
  }

  // Check if user is logged in
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userDataKey) != null;
  }
} 