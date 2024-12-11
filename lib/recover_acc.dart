import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart'; // Import mysql1 package
import 'login.dart'; // Import your login page

class RecoverAccountPage extends StatefulWidget {
  final int userId; // Received userId

  // Constructor to accept the userId
  RecoverAccountPage({required this.userId});

  @override
  _RecoverAccountPageState createState() => _RecoverAccountPageState();
}

class _RecoverAccountPageState extends State<RecoverAccountPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Function to handle password reset
  Future<void> _resetPassword() async {
    if (_newPasswordController.text == _confirmPasswordController.text) {
      try {
        // Establish a connection to the database
        final connectionSettings = ConnectionSettings(
          host: '192.168.1.9', // Your database host
          port: 3306,
          user: 'outside', // Your database user
          db: 'mvc_laundry_service_db', // Your database name
          password: '12345678', // Your database password
        );
        
        final conn = await MySqlConnection.connect(connectionSettings);

        // Encrypt the password if needed
        String encryptedPassword = _newPasswordController.text; // Use your preferred encryption method if needed
        
        // Update the password for the user in the database
        var result = await conn.query(
          'UPDATE users SET password = ? WHERE id = ?',
          [encryptedPassword, widget.userId],
        );

        if (result.affectedRows != null && result.affectedRows! > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Password has been successfully updated')),
          );

          // Navigate to the login page after successful password reset
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()), // Replace with your LoginPage widget
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: Unable to update password')),
          );
        }

        await conn.close();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Enter your new password and confirm it to reset your account password:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
                labelText: 'New Password',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
                labelText: 'Confirm Password',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _resetPassword,
              child: Text('Reset Password'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
