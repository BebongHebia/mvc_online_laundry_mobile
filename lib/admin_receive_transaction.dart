import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvc_online_laundry_service/print_detail.dart';
import 'package:mysql1/mysql1.dart';

class AdminReceiveTransaction extends StatefulWidget {
  final String transactionCode;

  AdminReceiveTransaction({required this.transactionCode});

  @override
  _AdminReceiveTransactionState createState() => _AdminReceiveTransactionState();
}

class _AdminReceiveTransactionState extends State<AdminReceiveTransaction> {
  final _settings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
  );

  Map<String, dynamic>? transactionData;
  bool isLoading = true;

  // List of services fetched from the database
  List<Map<String, dynamic>> servicesList = [];

  // Controllers
  final TextEditingController kiloController = TextEditingController();
  double amount = 0.0;

  final double pricePerKilo = 40.0;

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
    _fetchServices();  // Fetch services data from database
    kiloController.addListener(_calculateAmount);
  }

  // Fetch services from the database
  Future<void> _fetchServices() async {
    final conn = await MySqlConnection.connect(_settings);
    try {
      var results = await conn.query('SELECT * FROM services');
      setState(() {
        servicesList = results
            .map((row) => {'id': row[0], 'service': row[1], 'price': row[2]})
            .toList();
      });
    } catch (e) {
      print("Error fetching services: $e");
    } finally {
      await conn.close();
    }
  }

  // Fetch transaction details from the database
  Future<void> _fetchTransactionDetails() async {
    final conn = await MySqlConnection.connect(_settings);
    try {
      var results = await conn.query(
        '''
        SELECT * 
        FROM transactions 
        INNER JOIN users ON users.id = transactions.customer_id 
        WHERE transactions.transaction_code = ? 
        ''',
        [widget.transactionCode],
      );

      if (results.isNotEmpty) {
        setState(() {
          transactionData = results.first.fields;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Transaction not found")),
        );
      }
    } catch (e) {
      print("Database error: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error retrieving transaction details")),
      );
    } finally {
      await conn.close();
    }
  }

  // Calculate total amount based on selected services and kilos
  void _calculateAmount() {
    final kilos = double.tryParse(kiloController.text) ?? 0.0;
    double totalAmount = 0.0;

    if (kilos > 0 && kilos <= 8) {
      totalAmount = 100.0;
    } else if (kilos > 8 && kilos <= 13) {
      totalAmount = 200.0;
    } else if (kilos > 13) {
      totalAmount = 200.0 + ((kilos - 13) * 30.0);
    }

    // Add prices from selected services
    for (var service in servicesList) {
      if (service['isSelected'] == true) {
        totalAmount += service['price'];
      }
    }

    setState(() {
      amount = totalAmount;
    });
  }

  // Update transaction details
  Future<void> _updateTransaction() async {
    final conn = await MySqlConnection.connect(_settings);
    try {
      await conn.query(
        '''
        UPDATE transactions 
        SET kilo = ?, status = 'Received'
        WHERE transaction_code = ?
        ''',
        [
          double.tryParse(kiloController.text) ?? 0.0,
          widget.transactionCode,
        ],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transaction updated successfully")),
      );
    } catch (e) {
      print("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating transaction")),
      );
    } finally {
      await conn.close();
    }

    Navigator.pop(context);
  }

  // Add sales entry
  Future<void> _add_Sales() async {
    final conn = await MySqlConnection.connect(_settings);
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await conn.query(
        '''
        INSERT INTO sales (transaction_code, sales, date_paid) 
        VALUES (?, ?, ?)
        ''',
        [
          widget.transactionCode,
          amount,
          currentDate
        ],
      );
    } catch (e) {
      print("Sales insert error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error adding sales record")),
      );
    } finally {
      await conn.close();
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Transaction Details'),
    ),
    body: isLoading
        ? Center(child: CircularProgressIndicator())
        : transactionData != null
            ? SingleChildScrollView(  // Wrap the Column with a SingleChildScrollView
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: transactionData!['transaction_code'].toString(),
                        decoration: InputDecoration(labelText: 'Transaction Code'),
                        readOnly: true,
                      ),
                      TextFormField(
                        initialValue: transactionData!['complete_name'] ?? '',
                        decoration: InputDecoration(labelText: 'Customer Name'),
                        readOnly: true,
                      ),
                      TextFormField(
                        initialValue: transactionData!['email'] ?? '',
                        decoration: InputDecoration(labelText: 'Customer Email'),
                        readOnly: true,
                      ),
                      TextFormField(
                        initialValue: transactionData!['phone'] ?? '',
                        decoration: InputDecoration(labelText: 'Customer Phone'),
                        readOnly: true,
                      ),
                      TextFormField(
                        controller: kiloController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: 'Kilo'),
                      ),
                      TextFormField(
                        initialValue: transactionData!['date'].toString(),
                        decoration: InputDecoration(labelText: 'Transaction Date'),
                        readOnly: true,
                      ),
                      // Display services dynamically with checkboxes
                      ...servicesList.map((service) {
                        return CheckboxListTile(
                          title: Text("${service['service']} - ₱${service['price']}"),
                          value: service['isSelected'] ?? false,
                          onChanged: (value) {
                            setState(() {
                              service['isSelected'] = value;
                            });
                            _calculateAmount();
                          },
                        );
                      }).toList(),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Text(
                              'Amount: ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₱${amount.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _add_Sales();
                          _updateTransaction();
                        },
                        child: Text("Receive"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          String customerName = transactionData!['complete_name'] ?? 'Unknown';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrintDetails(
                                transactionCode: widget.transactionCode,
                                customerName: customerName,
                              ),
                            ),
                          );
                        },
                        child: Text("Print QR Code"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Center(child: Text("No transaction data found")),
  );
}


  @override
  void dispose() {
    kiloController.dispose();
    super.dispose();
  }
}
