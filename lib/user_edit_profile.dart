import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class UserEditProfilePage extends StatefulWidget {
  final int userId;

  UserEditProfilePage({required this.userId});

  @override
  _UserEditProfilePageState createState() => _UserEditProfilePageState();
}

class _UserEditProfilePageState extends State<UserEditProfilePage> {
  late TextEditingController _completeNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  String _sex = 'Male'; // Default value for sex dropdown

  final List<String> _sexOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _completeNameController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _fetchUserData();
  }

  // Fetch user data based on userId
  Future<void> _fetchUserData() async {
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
        'SELECT * FROM users WHERE id = ?', 
        [widget.userId],
      );

      if (results.isNotEmpty) {
        var row = results.first;
        _completeNameController.text = row['complete_name'] ?? '';
        _addressController.text = row['address'] ?? '';
        _phoneController.text = row['phone'] ?? '';
        _emailController.text = row['email'] ?? '';
        _usernameController.text = row['username'] ?? '';
        _sex = row['sex'] ?? 'Male'; // Default to Male if no value
      }

      await conn.close();
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  // Update user profile data
  Future<void> _updateUserProfile() async {
    try {
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.9',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      final conn = await MySqlConnection.connect(connectionSettings);

      await conn.query(
        'UPDATE users SET complete_name = ?, sex = ?, address = ?, phone = ?, email = ?, username = ? WHERE id = ?',
        [
          _completeNameController.text,
          _sex,
          _addressController.text,
          _phoneController.text,
          _emailController.text,
          _usernameController.text,
          widget.userId,
        ],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );

      await conn.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Edit your profile details:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _completeNameController,
              decoration: InputDecoration(labelText: 'Complete Name'),
            ),
            // Dropdown for sex
            DropdownButtonFormField<String>(
              value: _sex,
              onChanged: (String? newValue) {
                setState(() {
                  _sex = newValue!;
                });
              },
              items: _sexOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Sex'),
            ),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(labelText: 'Address'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateUserProfile,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
