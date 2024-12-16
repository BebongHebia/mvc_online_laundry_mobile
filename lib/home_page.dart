import 'package:flutter/material.dart';
import 'package:mvc_online_laundry_service/feature_qr_code.dart';
import 'package:mvc_online_laundry_service/feature_sms_notif.dart';
import 'package:mvc_online_laundry_service/user_edit_profile.dart';
import 'feature_wash_dry.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class HomePage extends StatefulWidget {
  final int userId;
  final String userName;

  HomePage({required this.userId, required this.userName});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _transactionFuture;
  late Future<List<Map<String, dynamic>>> _latestTransactionFuture;

  @override
  void initState() {
    super.initState();
    _transactionFuture = _fetchTransactions();
    _latestTransactionFuture = _fetchLatestTransaction();
  }

  // Fetch all transactions
  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    List<Map<String, dynamic>> transactions = [];
    try {
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      final conn = await MySqlConnection.connect(connectionSettings);
      var results = await conn.query(
          'SELECT * FROM transactions WHERE customer_id = ?', [widget.userId]);

      for (var row in results) {
        transactions.add({
          'id': row[0],
          'customer_id': row[1],
          'kilo': row[2],
          'transaction_code': row[3],
          'status': row[6],
          'date': row[7],
        });
      }

      await conn.close();
    } catch (e) {
      print('Error fetching transactions: $e');
    }

    return transactions;
  }

  // Fetch the latest transaction
  Future<List<Map<String, dynamic>>> _fetchLatestTransaction() async {
    List<Map<String, dynamic>> latestTransaction = [];
    try {
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      final conn = await MySqlConnection.connect(connectionSettings);
      var results = await conn.query(
          'SELECT * FROM transactions WHERE customer_id = ? ORDER BY date DESC LIMIT 1',
          [widget.userId]);

      for (var row in results) {
        latestTransaction.add({
          'id': row[0],
          'customer_id': row[1],
          'kilo': row[2],
          'transaction_code': row[3],
          'status': row[6],
          'date': row[7],
        });
      }

      await conn.close();
    } catch (e) {
      print('Error fetching latest transaction: $e');
    }

    return latestTransaction;
  }

  // Method to reload transactions
  void _reloadTransactions() {
    setState(() {
      _transactionFuture = _fetchTransactions();
      _latestTransactionFuture = _fetchLatestTransaction();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logged in as: ${widget.userName} (ID: ${widget.userId})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to the user edit profile page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserEditProfilePage(userId: widget.userId),
                  ),
                );
              },
              icon: Icon(
                Icons.account_circle,
                color: Colors.blue,
                size: 32.0, // Set the size of the icon (default is 24.0)
              ),
              label: Text(
                "Edit Profile",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16.0, // Optional: Adjust text size for balance
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Features:',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildFeatureCard(
                      Icons.local_laundry_service, 'Wash and Dry', context),
                  _buildFeatureCard(Icons.sms, 'SMS Notification', context),
                  _buildFeatureCard(Icons.qr_code, 'QR Code Driven', context),
                ],
              ),
            ),
            SizedBox(height: 20),
            _buildWashStatusPanel(),
            SizedBox(height: 20),
            _buildTransactionDataTable(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTransactionCodeDialog(context);
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Show transaction code dialog
  void _showTransactionCodeDialog(BuildContext context) {
    String transactionCode = _generateTransactionCode();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Transaction Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your transaction code is:'),
              SizedBox(height: 10),
              TextField(
                readOnly: true,
                controller: TextEditingController(text: transactionCode),
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                await _addTransactionToDatabase(
                    context, widget.userId, transactionCode);
                Navigator.of(context).pop();
                _reloadTransactions();
              },
              child: Text('Create'),
            ),
          ],
        );
      },
    );
  }

  // Generate transaction code
  String _generateTransactionCode() {
    DateTime now = DateTime.now();
    String year = DateFormat('yyyy').format(now);
    String month = DateFormat('MM').format(now);
    String day = DateFormat('dd').format(now);
    String timestamp = DateFormat('HHmmss').format(now);

    return '$year$month$day$timestamp';
  }

  // Add transaction to database
  Future<void> _addTransactionToDatabase(
      BuildContext context, int customerId, String transactionCode) async {
    try {
      final connectionSettings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
      );

      final conn = await MySqlConnection.connect(connectionSettings);
      String formattedDate = DateFormat('MM/dd/yyyy').format(DateTime.now());

      await conn.query(
        'INSERT INTO transactions (customer_id, kilo, transaction_code, status, date) VALUES (?, ?, ?, ?, ?)',
        [customerId, null, transactionCode, 'Pending', formattedDate],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction added successfully!')),
      );

      await conn.close();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Build wash status panel
  Widget _buildWashStatusPanel() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _latestTransactionFuture, // Use the initialized future here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No transactions found.'));
        }

        // Extract the status of the latest transaction
        var latestTransaction = snapshot.data!.first;
        String status = latestTransaction['status'] ?? 'No status';

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.local_laundry_service, size: 50, color: Colors.blue),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Your wash status: $status',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build transaction data table
  Widget _buildTransactionDataTable(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _transactionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No transactions found.'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('Kilo')),
              DataColumn(label: Text('Transaction Code')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Customer ID')),
            ],
            rows: snapshot.data!.map((transaction) {
              return DataRow(
                onSelectChanged: (selected) {
                  if (selected == true) {
                    _showQRCodeDialog(context, transaction['transaction_code']);
                  }
                },
                cells: [
                  DataCell(Text(transaction['kilo']?.toString() ?? 'N/A')),
                  DataCell(Text(transaction['transaction_code'])),
                  DataCell(Text(transaction['status'])),
                  DataCell(Text(transaction['date'].toString())),
                  DataCell(Text(transaction['id'].toString())),
                  DataCell(Text(transaction['customer_id'].toString())),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // Show QR Code dialog
  void _showQRCodeDialog(BuildContext context, String transactionCode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('QR Code'),
          content: SizedBox(
            width: 250,
            child: PrettyQr(
              data: transactionCode,
              size: 200.0,
              roundEdges: true,
              errorCorrectLevel: QrErrorCorrectLevel.H,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Build feature cards
  Widget _buildFeatureCard(IconData icon, String title, BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          if (title == 'Wash and Dry') {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => FeatureWashDryPage()));
          } else if (title == 'SMS Notification') {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => FeatureSMSNotif()));
          } else if (title == 'QR Code Driven') {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => FeatureQRCode()));
          }
        },
        child: Container(
          width: 120,
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40),
              SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
