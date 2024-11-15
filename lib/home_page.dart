import 'package:flutter/material.dart';
import 'package:mvc_online_laundry_service/feature_qr_code.dart';
import 'package:mvc_online_laundry_service/feature_sms_notif.dart';
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

  @override
  void initState() {
    super.initState();
    _transactionFuture = _fetchTransactions();
  }

  // Method to reload the transactions
  void _reloadTransactions() {
    setState(() {
      _transactionFuture = _fetchTransactions();
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
                  _buildFeatureCard(Icons.local_laundry_service, 'Wash and Dry', context),
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
                await _addTransactionToDatabase(context, widget.userId, transactionCode);
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

  String _generateTransactionCode() {
    DateTime now = DateTime.now();
    String year = DateFormat('yyyy').format(now);
    String month = DateFormat('MM').format(now);
    String day = DateFormat('dd').format(now);
    String timestamp = DateFormat('HHmmss').format(now);

    return '$year$month$day$timestamp';
  }

  Future<void> _addTransactionToDatabase(BuildContext context, int customerId, String transactionCode) async {
    try {
      final connectionSettings = ConnectionSettings(
        host: 'sql12.freesqldatabase.com',
        port: 3306,
        user: 'sql12742390',
        db: 'sql12742390',
        password: 'uUufMJnN8I',
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

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    List<Map<String, dynamic>> transactions = [];
    try {
      final connectionSettings = ConnectionSettings(
        host: 'sql12.freesqldatabase.com',
        port: 3306,
        user: 'sql12742390',
        db: 'sql12742390',
        password: 'uUufMJnN8I',
      );

      final conn = await MySqlConnection.connect(connectionSettings);
      var results = await conn.query('SELECT * FROM transactions WHERE customer_id = ?', [widget.userId]);

      for (var row in results) {
        transactions.add({
          'id': row[0],
          'customer_id': row[1],
          'kilo': row[2],
          'transaction_code': row[3],
          'status': row[4],
          'date': row[5],
        });
      }

      await conn.close();
    } catch (e) {
      print('Error fetching transactions: $e');
    }

    return transactions;
  }

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

  Widget _buildFeatureCard(IconData icon, String title, BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          if (title == 'Wash and Dry') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FeatureWashDryPage()));
          } else if (title == 'SMS Notification') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FeatureSMSNotif()));
          } else if (title == 'QR Code Driven') {
            Navigator.push(context, MaterialPageRoute(builder: (context) => FeatureQRCode()));
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

  Widget _buildWashStatusPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.local_laundry_service, size: 50, color: Colors.blue),
            SizedBox(width: 20),
            Expanded(
              child: Text(
                'Your wash status: In Progress',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
