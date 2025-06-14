import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/profile_service.dart';
import '../services/user_service.dart';
import 'auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String nic = '';
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  
  // Original values to compare for changes
  String originalName = '';
  String originalEmail = '';
  String originalAddress = '';
  String originalPhone = '';

  @override
  void initState() {
    super.initState();
    
    // Add listeners to trigger UI updates when text changes
    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _addressController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      isLoading = true;
    });

    try {
      print('ProfileScreen: Loading profile data...');
      
      // Debug current stored user data
      await UserService.debugUserData();
      
      // Try to get fresh data from API first
      final profileData = await ProfileService.getUserProfile();
      
      if (profileData != null) {
        print('ProfileScreen: Got profile data from API: ${profileData.toString()}');
        
        setState(() {
          _nameController.text = profileData['name']?.toString() ?? '';
          _emailController.text = profileData['email']?.toString() ?? '';
          _addressController.text = profileData['address']?.toString() ?? '';
          _phoneController.text = profileData['phone_number']?.toString() ?? '';
          nic = profileData['nic']?.toString() ?? '';
          
          // Store original values (trimmed)
          originalName = _nameController.text.trim();
          originalEmail = _emailController.text.trim();
          originalAddress = _addressController.text.trim();
          originalPhone = _phoneController.text.trim();
          
          isLoading = false;
        });
        
        print('ProfileScreen: Loaded from API - Name: "$originalName", Email: "$originalEmail", Address: "$originalAddress", Phone: "$originalPhone"');
      } else {
        print('ProfileScreen: API failed, falling back to local storage...');
        
        // Fallback to local storage
        final name = await UserService.getUserName();
        final email = await UserService.getUserEmail();
        final address = await UserService.getUserAddress();
        final phone = await UserService.getUserPhone();
        final userNic = await UserService.getUserNic();
        
        print('ProfileScreen: Local storage data - Name: "$name", Email: "$email", Address: "$address", Phone: "$phone", NIC: "$userNic"');
        
        setState(() {
          _nameController.text = name;
          _emailController.text = email;
          _addressController.text = address;
          _phoneController.text = phone;
          nic = userNic;
          
          // Store original values (trimmed)
          originalName = _nameController.text.trim();
          originalEmail = _emailController.text.trim();
          originalAddress = _addressController.text.trim();
          originalPhone = _phoneController.text.trim();
          
          isLoading = false;
        });
        
        print('ProfileScreen: Loaded from local storage - Name: "$originalName", Email: "$originalEmail", Address: "$originalAddress", Phone: "$originalPhone"');
      }
    } catch (e) {
      print('ProfileScreen: Error loading profile: $e');
      setState(() {
        isLoading = false;
      });
      
      String errorMessage = 'Error loading profile: ';
      if (e.toString().contains('timeout')) {
        errorMessage += 'Request timed out. Please check your internet connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage += 'No internet connection. Using cached data.';
      } else {
        errorMessage += e.toString();
      }
      
      _showErrorMessage(errorMessage);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    try {
      print('ProfileScreen: Starting profile save...');
      print('ProfileScreen: Current values - Name: "${_nameController.text.trim()}", Email: "${_emailController.text.trim()}", Address: "${_addressController.text.trim()}", Phone: "${_phoneController.text.trim()}"');
      
      final success = await ProfileService.updateUserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (success) {
        print('ProfileScreen: Profile update successful');
        
        // Update original values to match current values
        originalName = _nameController.text.trim();
        originalEmail = _emailController.text.trim();
        originalAddress = _addressController.text.trim();
        originalPhone = _phoneController.text.trim();
        
        setState(() {
          isEditing = false;
          isSaving = false;
        });
        
        // Verify the data was actually saved
        final savedName = await UserService.getUserName();
        final savedEmail = await UserService.getUserEmail();
        final savedAddress = await UserService.getUserAddress();
        final savedPhone = await UserService.getUserPhone();
        
        print('ProfileScreen: Verification after save:');
        print('ProfileScreen: - Name: "$savedName"');
        print('ProfileScreen: - Email: "$savedEmail"');
        print('ProfileScreen: - Address: "$savedAddress"');
        print('ProfileScreen: - Phone: "$savedPhone"');
        
        _showSuccessMessage('Profile updated successfully!');
        
        // Optionally refresh the UI with saved data
        await Future.delayed(Duration(milliseconds: 500));
        await _loadProfileData();
        
      } else {
        print('ProfileScreen: Profile update failed');
        setState(() {
          isSaving = false;
        });
        _showErrorMessage('Failed to update profile. Please check your internet connection and try again.');
      }
    } catch (e) {
      print('ProfileScreen: Exception during profile save: $e');
      setState(() {
        isSaving = false;
      });
      
      // Provide more specific error messages
      String errorMessage = 'Error updating profile: ';
      if (e.toString().contains('timeout')) {
        errorMessage += 'Request timed out. Please check your internet connection.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage += 'No internet connection. Please check your network.';
      } else {
        errorMessage += e.toString();
      }
      
      _showErrorMessage(errorMessage);
    }
  }

  void _cancelEditing() {
    setState(() {
      _nameController.text = originalName;
      _emailController.text = originalEmail;
      _addressController.text = originalAddress;
      _phoneController.text = originalPhone;
      isEditing = false;
    });
  }

  bool _hasChanges() {
    String currentName = _nameController.text.trim();
    String currentEmail = _emailController.text.trim();
    String currentAddress = _addressController.text.trim();
    String currentPhone = _phoneController.text.trim();
    
    bool nameChanged = currentName != originalName;
    bool emailChanged = currentEmail != originalEmail;
    bool addressChanged = currentAddress != originalAddress;
    bool phoneChanged = currentPhone != originalPhone;
    
    print('Change detection:');
    print('Name: "$currentName" vs "$originalName" = $nameChanged');
    print('Email: "$currentEmail" vs "$originalEmail" = $emailChanged');
    print('Address: "$currentAddress" vs "$originalAddress" = $addressChanged');
    print('Phone: "$currentPhone" vs "$originalPhone" = $phoneChanged');
    print('Has any changes: ${nameChanged || emailChanged || addressChanged || phoneChanged}');
    
    return nameChanged || emailChanged || addressChanged || phoneChanged;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await UserService.clearUserData();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isEditing && !isLoading)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () => setState(() => isEditing = true),
              tooltip: 'Edit Profile',
            ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Color.fromARGB(255, 20, 20, 20)],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading profile...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Header
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            // Profile Avatar
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.blue, Colors.purple],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              _nameController.text.isNotEmpty ? _nameController.text : 'Highway Guardian User',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Text(
                                'Verified Member',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Profile Fields
                      _buildProfileField(
                        label: 'Full Name',
                        controller: _nameController,
                        icon: Icons.person_outline,
                        enabled: isEditing,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      _buildProfileField(
                        label: 'Email Address',
                        controller: _emailController,
                        icon: Icons.email_outlined,
                        enabled: isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      _buildProfileField(
                        label: 'Address',
                        controller: _addressController,
                        icon: Icons.location_on_outlined,
                        enabled: isEditing,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Address is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      _buildProfileField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        enabled: isEditing,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 16),

                      // NIC Field (Read-only)
                      _buildProfileField(
                        label: 'NIC Number',
                        initialValue: nic,
                        icon: Icons.badge_outlined,
                        enabled: false,
                        readOnlyMessage: 'NIC cannot be modified',
                      ),

                      SizedBox(height: 32),

                      // Action Buttons
                      if (isEditing) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : _cancelEditing,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[700],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSaving ? null : (_hasChanges() ? _saveProfile : null),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasChanges() ? Colors.blue : Colors.grey[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isSaving
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
                                          SizedBox(width: 8),
                                          Text('Saving...'),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _hasChanges() ? Icons.save : Icons.save_outlined,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            _hasChanges() ? 'Save Changes' : 'No Changes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Refresh Profile Button
                        Container(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _loadProfileData,
                            icon: Icon(Icons.refresh),
                            label: Text('Refresh Profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 32),

                      // App Info
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Highway Guardian',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your safety companion on the road',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Version 1.0.0',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
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

  Widget _buildProfileField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
    String? readOnlyMessage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
          width: enabled ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: enabled ? Colors.blue : Colors.white60,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!enabled && readOnlyMessage != null) ...[
                  SizedBox(width: 8),
                  Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
          if (controller != null)
            TextFormField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              maxLines: maxLines ?? 1,
              validator: validator,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                hintText: enabled ? 'Enter $label' : '',
                hintStyle: TextStyle(color: Colors.white30),
              ),
            )
          else
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                initialValue ?? '',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          if (!enabled && readOnlyMessage != null)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                readOnlyMessage,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
