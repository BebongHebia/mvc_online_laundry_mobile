import 'package:flutter/material.dart';

class FeatureWashDryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wash and Dry'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Icon(
              Icons.local_laundry_service, // Icon representing wash and dry
              size: 100, // Set a size for the icon
              color: Colors.blue, // Icon color
            ),
            SizedBox(height: 20), // Space between icon and text
            Text(
              'Wash and Dry Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10), // Space between title and details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Our wash and dry service ensures your clothes are cleaned and dried with utmost care. We use high-quality detergents and softeners to give your clothes a fresh and soft finish.',
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
