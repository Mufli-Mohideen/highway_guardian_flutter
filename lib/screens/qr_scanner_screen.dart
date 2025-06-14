import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class QRScannerScreen extends StatefulWidget {
  final String action; // "enter" or "exit"
  
  const QRScannerScreen({Key? key, required this.action}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? result;
  bool hasScanned = false;
  bool isProcessing = false;
  bool showingDetails = false;
  Map<String, dynamic>? highwayDetails;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          '${widget.action.toUpperCase()} Highway - Scan QR',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          // Instructions - only show when not processing or showing details
          if (!isProcessing && !showingDetails)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Scan the QR code at the highway ${widget.action} point',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // QR Scanner View - only show when not processing or showing details
          if (!isProcessing && !showingDetails)
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                    overlay: QrScannerOverlayShape(
                      borderColor: widget.action == 'enter' ? Colors.green : Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 280,
                    ),
                  ),
                ),
              ),
            ),
          
          // Content Area - Shows different states
          Expanded(
            flex: isProcessing || showingDetails ? 4 : 2,
            child: Container(
              padding: EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Processing State - QR Code detected, analyzing
                    if (isProcessing)
                      Container(
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.action == 'enter' ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            LoadingAnimationWidget.fourRotatingDots(
                              color: widget.action == 'enter' ? Colors.green : Colors.red,
                              size: 60,
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Analyzing QR Code...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Fetching highway information',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20),
                            // Progress indicators
                            _buildProgressStep('Reading QR Code', true),
                            SizedBox(height: 8),
                            _buildProgressStep('Verifying Location', true),
                            SizedBox(height: 8),
                            _buildProgressStep('Loading Highway Data', false),
                          ],
                        ),
                      )
                    
                    // Highway Details State - Show processed information
                    else if (showingDetails && highwayDetails != null)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.action == 'enter' ? Colors.green : Colors.red,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Success Icon
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (widget.action == 'enter' ? Colors.green : Colors.red).withOpacity(0.2),
                              ),
                              child: Icon(
                                widget.action == 'enter' ? Icons.login : Icons.logout,
                                color: widget.action == 'enter' ? Colors.green : Colors.red,
                                size: 40,
                              ),
                            ),
                            
                            SizedBox(height: 20),
                            
                            Text(
                              '✅ Highway ${widget.action.toUpperCase()} Confirmed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            
                            SizedBox(height: 24),
                            
                            // Highway Information Cards
                            _buildInfoCard('Highway Name', highwayDetails!['name'], Icons.route),
                            SizedBox(height: 12),
                            _buildInfoCard('Location', highwayDetails!['location'], Icons.location_on),
                            SizedBox(height: 12),
                            _buildInfoCard('Time', highwayDetails!['time'], Icons.access_time),
                            SizedBox(height: 12),
                            _buildInfoCard('Speed Limit', '${highwayDetails!['speedLimit']} km/h', Icons.speed),
                            
                            if (widget.action == 'enter') ...[
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.green, size: 24),
                                    SizedBox(height: 8),
                                    Text(
                                      'Safety Tips for Highway Entry',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '• Check mirrors and blind spots\n• Maintain safe following distance\n• Observe speed limits\n• Stay alert for other vehicles',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.exit_to_app, color: Colors.red, size: 24),
                                    SizedBox(height: 8),
                                    Text(
                                      'Highway Exit Complete',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Thank you for using Highway Guardian.\nDrive safely on local roads.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            SizedBox(height: 24),
                            
                            // Confirm Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _confirmAndReturn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: widget.action == 'enter' ? Colors.green : Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Confirm ${widget.action.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    
                    // Initial Scanning State
                    else
                      Column(
                        children: [
                          LoadingAnimationWidget.waveDots(
                            color: Colors.grey[600]!,
                            size: 50,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Position the QR code within the frame',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isCompleted) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isCompleted ? Colors.green : Colors.grey[400],
          size: 16,
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: isCompleted ? Colors.white : Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!hasScanned && scanData.code != null && !isProcessing) {
        setState(() {
          result = scanData.code;
          isProcessing = true;
        });
        controller.pauseCamera();
        
        // Process the QR code and show highway details
        _processQRCode(scanData.code!);
      }
    });
  }

  void _processQRCode(String qrData) {
    // Simulate processing time and parse highway information
    Future.delayed(Duration(milliseconds: 2500), () {
      if (mounted) {
        // Parse QR code data and generate highway information
        final details = _parseHighwayData(qrData);
        
        setState(() {
          isProcessing = false;
          showingDetails = true;
          highwayDetails = details;
        });
      }
    });
  }

  Map<String, dynamic> _parseHighwayData(String qrData) {
    print('🔍 QR Scanner: Processing QR Data: $qrData');
    print('🔍 QR Scanner: QR Data Length: ${qrData.length} characters');
    
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    try {
      // Try to parse as JSON first
      final Map<String, dynamic> qrJson = Map<String, dynamic>.from(
        const JsonDecoder().convert(qrData)
      );
      
      print('✅ QR Scanner: Successfully parsed JSON:');
      print('   - tollBoothId: ${qrJson['tollBoothId']}');
      print('   - location: ${qrJson['location']}');
      print('   - coordinates: ${qrJson['coordinates']}');
      print('   - timestamp: ${qrJson['timestamp']}');
      print('   - generatedBy: ${qrJson['generatedBy']}');
      
      // Extract data from JSON
      final tollBoothId = qrJson['tollBoothId']?.toString() ?? 'Unknown';
      final location = qrJson['location']?.toString() ?? 'Unknown Location';
      final coordinates = qrJson['coordinates'] as Map<String, dynamic>? ?? {'lat': 0, 'lon': 0};
      final timestamp = qrJson['timestamp']?.toString() ?? now.toIso8601String();
      final generatedBy = qrJson['generatedBy']?.toString() ?? 'Highway Guardian System';
      
      // Build highway name based on location or use a default
      String highwayName;
      if (location.toLowerCase().contains('pinnaduwa')) {
        highwayName = 'Southern Expressway E01';
      } else if (location.toLowerCase().contains('colombo')) {
        highwayName = 'Colombo-Katunayake Expressway E03';
      } else if (location.toLowerCase().contains('kandy')) {
        highwayName = 'Colombo-Kandy Highway A1';
      } else if (location.toLowerCase().contains('galle')) {
        highwayName = 'Southern Expressway E01';
      } else {
        highwayName = 'Highway Guardian Zone';
      }
      
      final result = {
        'name': highwayName,
        'location': location,
        'time': timeString,
        'speedLimit': 100, // Default speed limit as requested
        'qrCode': qrData,
        'tollBoothId': tollBoothId,
        'coordinates': coordinates,
        'timestamp': timestamp,
        'generatedBy': generatedBy,
        'jsonParsed': true,
      };
      
      print('🏁 QR Scanner: Final highway data: $result');
      return result;
      
    } catch (e) {
      print('❌ QR Scanner: JSON parsing failed: $e');
      print('📱 QR Scanner: Falling back to text-based parsing');
      
      // Fallback for non-JSON QR codes
      String highwayName = 'Highway Guardian Zone';
      String location = widget.action == 'enter' ? 'Entry Point' : 'Exit Point';
      
      // Try to extract some info from text-based QR codes
      if (qrData.toLowerCase().contains('highway') || qrData.toLowerCase().contains('expressway')) {
        highwayName = 'Southern Expressway E01';
        location = 'Highway Interchange';
      } else if (qrData.toLowerCase().contains('colombo')) {
        highwayName = 'Colombo-Katunayake Expressway';
        location = 'Colombo Junction';
      }
      
      final result = {
        'name': highwayName,
        'location': location,
        'time': timeString,
        'speedLimit': 100,
        'qrCode': qrData.length > 20 ? qrData.substring(0, 20) + '...' : qrData,
        'tollBoothId': 'Unknown',
        'coordinates': {'lat': 0, 'lon': 0},
        'timestamp': now.toIso8601String(),
        'generatedBy': 'Highway Guardian System',
        'jsonParsed': false,
      };
      
      print('🔄 QR Scanner: Fallback highway data: $result');
      return result;
    }
  }

  void _confirmAndReturn() {
    setState(() {
      hasScanned = true;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('Highway ${widget.action} recorded successfully!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    
    // Return the highway details to the previous screen
    Navigator.pop(context, result);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
} 