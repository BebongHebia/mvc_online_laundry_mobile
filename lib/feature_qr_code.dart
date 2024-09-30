import 'package:flutter/material.dart';

class FeatureQRCode extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('QR Code Driven'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Icon(
              Icons.qr_code, // Icon representing wash and dry
              size: 100, // Set a size for the icon
              color: Colors.blue, // Icon color
            ),
            SizedBox(height: 20), // Space between icon and text
            Text(
              'QR Code Driven',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10), // Space between title and details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'The QR Code-driven feature in the MVC Online Laundry Service app allows customers to easily access and manage their laundry orders. Each order is assigned a unique QR code, which can be scanned to quickly view order details, track the status, and confirm pickup or delivery. This feature streamlines the process, reduces errors, and enhances security by ensuring that each order is accurately identified and managed.',
                textAlign: TextAlign.center, // Center-align text
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
