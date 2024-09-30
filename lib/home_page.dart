import 'package:flutter/material.dart';
import 'package:mvc_online_laundry_service/feature_qr_code.dart';
import 'package:mvc_online_laundry_service/feature_sms_notif.dart';
import 'feature_wash_dry.dart'; // Import the new page

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Use ListView for horizontal scrolling
            Container(
              height: 100, // Set a height for the horizontal list
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFeatureCard(Icons.local_laundry_service, 'Wash and Dry', context),
                  _buildFeatureCard(Icons.sms, 'SMS Notification', context),
                  _buildFeatureCard(Icons.qr_code, 'QR Code Driven', context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create a feature card
  Widget _buildFeatureCard(IconData icon, String title, BuildContext context) {
    // Get screen width
    double screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate card width based on the number of cards
    double cardWidth = screenWidth / 3; // Assuming 3 cards

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 4.0,
      child: InkWell(
        onTap: () {
          // Navigate to the respective feature page based on the title
          if (title == 'Wash and Dry') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FeatureWashDryPage()), // Navigate to Wash and Dry page
            );
          }

          if (title == 'SMS Notification') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FeatureSMSNotif()), // Navigate to Wash and Dry page
            );
          }

          if (title == 'QR Code Driven') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FeatureQRCode()), // Navigate to Wash and Dry page
            );
          }
          // Add other conditions here for other cards if needed
        },
        child: Container(
          width: cardWidth, // Set calculated width for each card
          padding: const EdgeInsets.all(8.0), // Adjust padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32, // Reduce icon size
                color: Colors.blue,
              ),
              SizedBox(height: 5), // Adjust spacing
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, // Reduce font size
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
