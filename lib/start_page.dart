import 'package:flutter/material.dart';
import 'login.dart';  // Import the LoginPage

class StartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Logo
              Image.asset(
                'assets/image/logo.png',  // Replace with your actual logo path
                height: 150,  // Adjust the size of the logo
              ),
              SizedBox(height: 30),  // Add space between the logo and text

              // Main Title
              Text(
                'MVC Online Laundry Services',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Roboto',  // Optional: Use your desired font
                ),
                textAlign: TextAlign.center,
              ),

              // Subtitle
              SizedBox(height: 10),
              Text(
                'A sum of efficiency, quality and savings for your laundry',
                style: TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 40),  // Add space between text and button

              // Continue Button
              ElevatedButton(
                onPressed: () {
                  // Navigate to LoginPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15), backgroundColor: Colors.blue, // Button background color
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
