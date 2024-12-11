import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart'; // Import mysql1 package
import 'recover_acc.dart'; // Import the recover_acc.dart page

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Function to handle password recovery
  Future<void> _recoverAccount() async {
    try {
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.9',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      final conn = await MySqlConnection.connect(connectionSettings);

      var results = await conn.query(
        'SELECT * FROM users WHERE username = ? AND phone = ?',
        [
          _usernameController.text,
          _phoneController.text,
        ],
      );

      if (results.isNotEmpty) {
        var userRow = results.first;
        var userId = userRow['id']; // Get the user's ID
        var userName = userRow['complete_name'] ?? 'Unknown User';

        // Navigate to the recovery page and pass the userId
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecoverAccountPage(userId: userId), // Pass userId to recover_acc.dart
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account not found with the provided details')),
        );
      }

      await conn.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Enter your username and phone number to recover your account:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                labelText: 'Username',
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                labelText: 'Phone Number',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _recoverAccount,
              child: Text('Recover Account'),
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
