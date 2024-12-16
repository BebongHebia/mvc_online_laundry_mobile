import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:easy_send_sms/easy_sms.dart';
import 'dart:async';

// Transaction model
class Transaction {
  final int id;
  final String complete_name;
  final String phone;
  final String transactionCode;
  final int? kilo;
  final String date;
  final double sales;

  Transaction({
    required this.id,
    required this.complete_name,
    required this.phone,
    required this.transactionCode,
     this.kilo,
    required this.date,
    required this.sales,
  });
}

// Database helper for MySQL
class DatabaseHelper {
  static Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
    );
    return await MySqlConnection.connect(settings);
  }

  static Future<Transaction?> getTransactionByCode(String transactionCode) async {
    final conn = await connect();
    var result = await conn.query(
      'SELECT * FROM transactions INNER JOIN users ON users.id = transactions.customer_id INNER JOIN sales on sales.transaction_code = transactions.transaction_code WHERE transactions.transaction_code = ?',
      [transactionCode],
    );

    if (result.isNotEmpty) {
      var row = result.first;
      await conn.close();
      return Transaction(
        id: row['id'],
        complete_name: row['complete_name'],
        phone: row['phone'],
        transactionCode: row['transaction_code'],
        kilo: row['kilo'],
        date: row['date'],
        sales: row['sales'],
      );
    }
    await conn.close();
    return null;
  }

  static Future<void> updateTransactionStatus(String transactionCode) async {
    final conn = await connect();
    await conn.query(
      'UPDATE transactions SET status = ? WHERE transaction_code = ?',
      ['Finish', transactionCode],
    );
    await conn.close();
  }
}

 final _easySmsPlugin = EasySms();

  Future<void> sendSms(String phone,String msg) async {
    try {
      await _easySmsPlugin.requestSmsPermission();
      await _easySmsPlugin.sendSms(phone: phone, msg: msg);
    } catch (err) {
      if (kDebugMode) {
        print(err.toString());
      }
    }
  }


// Admin view for a single transaction
class AdminViewTransaction extends StatelessWidget {
  final String transactionCode;

  AdminViewTransaction({required this.transactionCode});

  Future<Transaction?> _fetchTransaction() async {
    return await DatabaseHelper.getTransactionByCode(transactionCode);
  }

  Future<void> _finishTransaction(BuildContext context, Transaction transaction) async {
    // Update transaction status
    await DatabaseHelper.updateTransactionStatus(transactionCode);

    // Prepare SMS message
    final message = 'Your Laundry with transaction code ${transaction.transactionCode} is now finsihed. Please visit laundry shop to pick-up your laundry. Shop is closing time is 5:00 pm';
    
    sendSms(transaction.phone, message);

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction completed and SMS sent to ${transaction.phone}')),
    );

    // Optionally refresh the UI or pop the screen
    Navigator.of(context).pop(); // or reload state if needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Transaction'),
      ),
      body: FutureBuilder<Transaction?>(
        future: _fetchTransaction(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Transaction not found.'));
          } else {
            final transaction = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction ID: ${transaction.id}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Customer Name: ${transaction.complete_name}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Phone: ${transaction.phone}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Transaction Code: ${transaction.transactionCode}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Kilos: ${transaction.kilo} kg', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Date: ${transaction.date}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Sales: ${transaction.sales}', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _finishTransaction(context, transaction),
                    child: Text('Finish'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
