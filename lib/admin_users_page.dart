import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart'; // Import mysql1 package

class AdminUsersPage extends StatefulWidget {
  @override
  _AdminUsersPageState createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> users = []; // List to store fetched users data
  bool isLoading = true; // Loading indicator
  bool isFetchingMore = false; // Indicator for fetching more data
  int rowsPerPage = 10; // Rows per page for pagination
  int currentPage = 0; // Current page index
  String searchQuery = ''; // Search query string
  bool sortAscending = true; // Sorting order

  @override
  void initState() {
    super.initState();
    fetchUsers(); // Fetch users when the widget is initialized
  }

  // Method to fetch users from the database with pagination
  Future<void> fetchUsers({int offset = 0}) async {
    try {
      setState(() {
        isFetchingMore = true; // Indicate that more data is being fetched
      });

      // Define the connection settings
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      // Establish a connection
      final conn = await MySqlConnection.connect(connectionSettings);

      // Query to fetch users with pagination, skipping Admin users
      var results = await conn.query(
        'SELECT id, complete_name, sex, address, phone, status, role, email, username '
        'FROM users WHERE role != "Admin" '
        'LIMIT $rowsPerPage OFFSET $offset',
      );

      // Store the fetched data in the users list
      List<Map<String, dynamic>> fetchedUsers = [];
      for (var row in results) {
        fetchedUsers.add({
          'id': row['id'],
          'complete_name': row['complete_name'],
          'sex': row['sex'],
          'address': row['address'],
          'phone': row['phone'],
          'status': row['status'],
          'role': row['role'],
          'email': row['email'],
          'username': row['username'],
        });
      }

      // Update the state with the fetched data
      setState(() {
        users.addAll(fetchedUsers);
        isLoading = false;
        isFetchingMore = false;
      });

      // Close the connection
      await conn.close();
    } catch (e) {
      // Handle the error and stop the loading indicator
      setState(() {
        isLoading = false;
        isFetchingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Method to handle search
  void handleSearch(String query) {
    setState(() {
      searchQuery = query;
      users.clear();
      currentPage = 0;
      fetchUsers(); // Re-fetch users with search query
    });
  }

  // Method to handle sorting
  void sortByName() {
    setState(() {
      sortAscending = !sortAscending;
      users.sort((a, b) {
        return sortAscending
            ? a['complete_name'].compareTo(b['complete_name'])
            : b['complete_name'].compareTo(a['complete_name']);
      });
    });
  }

  // Method to load more data (pagination)
  void loadMore() {
    if (!isFetchingMore) {
      setState(() {
        currentPage++;
      });
      fetchUsers(offset: currentPage * rowsPerPage);
    }
  }

  // Method to show the edit user dialog
  void _showEditUserDialog(Map<String, dynamic> user) {
  final TextEditingController nameController = TextEditingController(text: user['complete_name']);
  final TextEditingController sexController = TextEditingController(text: user['sex']);
  final TextEditingController addressController = TextEditingController(text: user['address']);
  final TextEditingController phoneController = TextEditingController(text: user['phone']);
  final TextEditingController emailController = TextEditingController(text: user['email']);
  final TextEditingController usernameController = TextEditingController(text: user['username']);

  // Dropdown value
  String selectedStatus = user['status'];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit User'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Complete Name')),
              TextField(controller: sexController, decoration: InputDecoration(labelText: 'Sex')),
              TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone')),
              
              // Dropdown for status
              DropdownButtonFormField<String>(
                value: selectedStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue!; // Update the selected status
                  });
                },
                items: <String>['Pending', 'Active']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                decoration: InputDecoration(labelText: 'Status'),
              ),

              TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Username')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateUser(
                user['id'],
                nameController.text,
                sexController.text,
                addressController.text,
                phoneController.text,
                selectedStatus, // Use the selected status
                user['role'], // Keep the existing role
                emailController.text,
                usernameController.text,
              );
              Navigator.of(context).pop();
            },
            child: Text('Update'),
          ),
        ],
      );
    },
  );
}

  // Method to update user data in the database
  Future<void> _updateUser(int id, String completeName, String sex, String address, String phone, String status, String role, String email, String username) async {
    try {
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      final conn = await MySqlConnection.connect(connectionSettings);
      
      await conn.query(
        'UPDATE users SET complete_name = ?, sex = ?, address = ?, phone = ?, status = ?, role = ?, email = ?, username = ? WHERE id = ?',
        [completeName, sex, address, phone, status, role, email, username, id]
      );

      await conn.close();

      // Update the local users list
      setState(() {
        final index = users.indexWhere((user) => user['id'] == id);
        if (index != -1) {
          users[index] = {
            'id': id,
            'complete_name': completeName,
            'sex': sex,
            'address': address,
            'phone': phone,
            'status': status,
            'role': role,
            'email': email,
            'username': username,
          };
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Method to show the delete user confirmation dialog
  void _showDeleteUserDialog(int userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete User'),
          content: Text('Are you sure you want to delete this user?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteUser(userId);
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Method to delete user from the database
  Future<void> _deleteUser(int userId) async {
    try {
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      final conn = await MySqlConnection.connect(connectionSettings);
      
      await conn.query(
        'DELETE FROM users WHERE id = ?',
        [userId],
      );

      await conn.close();

      // Remove the user from the local list
      setState(() {
        users.removeWhere((user) => user['id'] == userId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
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
        title: Text('Admin Users Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: handleSearch,
              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
  child: isLoading
      ? Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Actions')), // Move Actions column here
              DataColumn(label: Text('Complete Name'), onSort: (columnIndex, ascending) => sortByName()),
              DataColumn(label: Text('Sex')),
              DataColumn(label: Text('Address')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Username')),
            ],
            rows: users.map((user) {
              return DataRow(
                cells: [
                  DataCell(Row( // Move the actions cell here
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditUserDialog(user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _showDeleteUserDialog(user['id']),
                      ),
                    ],
                  )),
                  DataCell(Text(user['complete_name'])),
                  DataCell(Text(user['sex'])),
                  DataCell(Text(user['address'])),
                  DataCell(Text(user['phone'])),
                  DataCell(Text(user['status'])),
                  DataCell(Text(user['role'])),
                  DataCell(Text(user['email'])),
                  DataCell(Text(user['username'])),
                ],
              );
            }).toList(),
          ),
        ),
),
            if (isFetchingMore) CircularProgressIndicator(),
            if (!isFetchingMore && users.isNotEmpty)
              ElevatedButton(
                onPressed: loadMore,
                child: Text('Load More'),
              ),
          ],
        ),
      ),
    );
  }
}
