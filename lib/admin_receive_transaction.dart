import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';

class AdminReceiveTransaction extends StatefulWidget {
  final String transactionCode;

  AdminReceiveTransaction({required this.transactionCode});

  @override
  _AdminReceiveTransactionState createState() => _AdminReceiveTransactionState();
}

class _AdminReceiveTransactionState extends State<AdminReceiveTransaction> {
  final _settings = ConnectionSettings(
      host: 'sql12.freesqldatabase.com',
      port: 3306,
      user: 'sql12742390',
      db: 'sql12742390',
      password: 'uUufMJnN8I',
  );

  Map<String, dynamic>? transactionData;
  bool isLoading = true;

  // Checkbox states
  bool withSoap = false;
  bool withFabricConditioner = false;

  // Controllers
  final TextEditingController kiloController = TextEditingController();
  double amount = 0.0;

  final double pricePerKilo = 40.0;
  final double soapPricePerKilo = 10.0;
  final double fabricConditionerPricePerKilo = 10.0;

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
    kiloController.addListener(_calculateAmount);
  }

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

  // Add fixed costs if soap and fabric conditioner are selected
  if (withSoap) {
    totalAmount += 10.0;
  }
  if (withFabricConditioner) {
    totalAmount += 10.0;
  }

  setState(() {
    amount = totalAmount;
  });
}

  Future<void> _updateTransaction() async {
    final conn = await MySqlConnection.connect(_settings);
    try {
      await conn.query(
        '''
        UPDATE transactions 
        SET kilo = ?, with_soap = ?, with_fabric_con = ?, status = 'Received'
        WHERE transaction_code = ?
        ''',
        [
          double.tryParse(kiloController.text) ?? 0.0,
          withSoap ? 1 : 0,
          withFabricConditioner ? 1 : 0,
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
  }

  Future<void> _add_Sales() async {
    final conn = await MySqlConnection.connect(_settings);
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      await conn.query(
        '''
        insert into sales (transaction_code, sales, date_paid) value(?, ?, ?)

        ''',
        [
          widget.transactionCode,
          amount,
          currentDate
        ],
      );

    } catch (e) {
      print("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating transaction")),
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
              ? Padding(
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
                      CheckboxListTile(
                        title: Text("With Soap"),
                        value: withSoap,
                        onChanged: (value) {
                          setState(() {
                            withSoap = value ?? false;
                          });
                          _calculateAmount();
                        },
                      ),
                      CheckboxListTile(
                        title: Text("With Fabric Conditioner"),
                        value: withFabricConditioner,
                        onChanged: (value) {
                          setState(() {
                            withFabricConditioner = value ?? false;
                          });
                          _calculateAmount();
                        },
                      ),
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
                        onPressed: (){
                          _add_Sales();
                          _updateTransaction();
                        },
                        child: Text("Receive"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        ),
                      ),
                    ],
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
