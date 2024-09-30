import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart'; // Import mysql1 package
import 'create_account.dart';
import 'home_page.dart'; // Import the home page or the next page after login

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      // Define the connection settings
      final connectionSettings = ConnectionSettings(
        host: '192.168.0.32', // Your MySQL host IP
        port: 3306, // Default MySQL port
        user: 'outside', // Your MySQL username
        db: 'mvc_laundry_service_db', // Your database name
        password: '12345678', // Your MySQL password
      );

      // Establish a connection
      final conn = await MySqlConnection.connect(connectionSettings);

      // Query to check if the user exists with the given username and password
      var results = await conn.query(
        'SELECT * FROM users WHERE username = ? AND password = ?',
        [
          _usernameController.text,
          _passwordController.text, // You should hash the password before sending in production
        ],
      );

      if (results.isNotEmpty) {
        var userRow = results.first;
        var userStatus = userRow['status']; // Assuming 'status' is the column name

        if (userStatus == 'Active') {
          // Login successful and status is Active
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login successful')),
          );

          // Navigate to the HomePage or the desired page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()), // Replace with your HomePage or Dashboard
          );
        } else if (userStatus == 'Pending') {
          // Account is still pending
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Your account is still pending. Wait within 1 to 2 hours for admin to approve your account.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          // Handle other statuses if needed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your account status is: $userStatus'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Login failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid username or password')),
        );
      }

      // Close the connection
      await conn.close();
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 50),

                // Illustration Image
                Image.asset(
                  'assets/image/login_image.png',
                  height: 150,
                ),
                SizedBox(height: 30),

                // Login Title
                Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                ),

                // Phone/Username TextField
                SizedBox(height: 20),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    labelText: 'Enter Phone number or Username',
                  ),
                ),

                // Password TextField
                SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    labelText: 'Enter Password',
                  ),
                ),

                // Login Button
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.blue,
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                // Create Account Link
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateAccountPage()),
                    );
                  },
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                // Forgot Password Link
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    // Navigate to Forgot Password page or functionality
                    print('Navigate to Forgot Password');
                  },
                  child: Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
