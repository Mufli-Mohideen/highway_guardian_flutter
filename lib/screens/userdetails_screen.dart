import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserDetailsPage extends StatefulWidget {
  final String email;
  const UserDetailsPage({Key? key, required this.email}) : super(key: key);

  @override
  _UserDetailsPageState createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();

  int _currentStep = 1;

  void _onNextStep() async {
    if (_currentStep == 1 && _phoneController.text.isNotEmpty) {
      setState(() {
        _currentStep = 2; // Proceed to next step
      });
    } else if (_currentStep == 2 && _addressController.text.isNotEmpty) {
      setState(() {
        _currentStep = 3; // Proceed to next step
      });
    } else if (_currentStep == 3 && _nicController.text.isNotEmpty) {
      _submitUserDetails(); // Submit the details when all steps are completed
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please fill out the required fields."),
      ));
    }
  }

  void _onGoToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  Future<void> _submitUserDetails() async {
    String apiUrl = "http://192.168.8.118:5001/api/auth/update-user";
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': widget.email,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'nic': _nicController.text,
      }),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      Navigator.pushReplacementNamed(context, '/verification',
          arguments: widget.email);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Response Status: ${response.statusCode}\nResponse Body: ${response.body}',
          ),
        ),
      );
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: "Phone Number",
                hintStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color.fromRGBO(47, 47, 47, 1.0),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 12.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            const Text(
              "Keep Going!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              keyboardType: TextInputType.streetAddress,
              decoration: InputDecoration(
                hintText: "Address",
                hintStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color.fromRGBO(47, 47, 47, 1.0),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 12.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            const Text(
              "We're almost there!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nicController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                hintText: "NIC",
                hintStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color.fromRGBO(47, 47, 47, 1.0),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 12.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        );
      case 4:
        return Column(
          children: [
            const Text(
              "Thank you for providing your details!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _onGoToDashboard,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Go to Dashboard",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5.0,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Colors.white,
                    ),
                  ),
                  const Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 5.0,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/onboard.jpg',
                width: 250,
                height: 250,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              _buildStepContent(),
              const SizedBox(height: 30),
              if (_currentStep < 4)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onNextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _currentStep == 1 ? "Next" : "Confirm",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 120),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(
                  'Highway Guardian © 2025 All rights reserved',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
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
