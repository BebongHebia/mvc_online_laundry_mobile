import 'package:flutter/material.dart';
import 'package:mvc_online_laundry_service/admin_view_transaction.dart';
import 'package:mvc_online_laundry_service/scan_pickup_laundry.dart';
import 'package:mvc_online_laundry_service/view_transaction_via_qr.dart';
import 'package:mysql1/mysql1.dart';

// Transaction model
class Transaction {
  final int id;
  final String complete_name;
  final int? kilo; // Made kilo nullable
  final String transactionCode;
  final String status;
  final String date;
  final bool withSoap;
  final bool withFabricCon;

  Transaction({
    required this.id,
    required this.complete_name,
    this.kilo, // Allowing null values for kilo
    required this.transactionCode,
    required this.status,
    required this.date,
    required this.withSoap,
    required this.withFabricCon,
  });
}

// Database helper class
class DatabaseHelper {
  static Future<MySqlConnection> connect() async {
    final settings = ConnectionSettings(
      host: 'sql12.freesqldatabase.com',
      port: 3306,
      user: 'sql12742390',
      db: 'sql12742390',
      password: 'uUufMJnN8I',
    );
    return await MySqlConnection.connect(settings);
  }

  static Future<List<Transaction>> getTransactions() async {
    final conn = await connect();
    var results = await conn.query(
      'SELECT *, transactions.status as trans_status FROM transactions INNER JOIN users ON transactions.customer_id = users.id'
    );

    List<Transaction> transactions = [];

    for (var row in results) {
      transactions.add(Transaction(
        id: row['id'],
        complete_name: row['complete_name'],
        kilo: row['kilo'] as int?, // Safely cast kilo as int?
        transactionCode: row['transaction_code'],
        status: row['trans_status'],
        date: row['date'],
        withSoap: row['with_soap'] == 1,
        withFabricCon: row['with_fabric_con'] == 1,
      ));
    }

    await conn.close();
    return transactions;
  }
}

// AdminTransactionList Widget
class AdminTransactionList extends StatefulWidget {
  @override
  _AdminTransactionListState createState() => _AdminTransactionListState();
}

class _AdminTransactionListState extends State<AdminTransactionList> {
  late Future<List<Transaction>> _futureTransactions;
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  int _currentPage = 0;
  final int _rowsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureTransactions = DatabaseHelper.getTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      String query = _searchController.text.toLowerCase();
      _filteredTransactions = _allTransactions.where((transaction) {
        return transaction.transactionCode.toLowerCase().contains(query) ||
            transaction.status.toLowerCase().contains(query) ||
            transaction.date.contains(query) ||
            (transaction.kilo?.toString().contains(query) ?? false);
      }).toList();
      _currentPage = 0; // Reset to first page on search
    });
  }

  void _nextPage() {
    setState(() {
      if ((_currentPage + 1) * _rowsPerPage < _filteredTransactions.length) {
        _currentPage++;
      }
    });
  }

  void _previousPage() {
    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Transactions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            // Transaction list
            Expanded(
              child: FutureBuilder<List<Transaction>>(
                future: _futureTransactions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No transactions found.'));
                  } else {
                    _allTransactions = snapshot.data!;
                    // Apply filter only if there is a search query
                    _filteredTransactions = _searchController.text.isEmpty
                        ? _allTransactions
                        : _filteredTransactions;

                    int startIndex = _currentPage * _rowsPerPage;
                    int endIndex = startIndex + _rowsPerPage;
                    endIndex = endIndex > _filteredTransactions.length
                        ? _filteredTransactions.length
                        : endIndex;
                    List<Transaction> paginatedTransactions = _filteredTransactions
                        .sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        // List of transactions
                        Expanded(
                          child: ListView.builder(
                            itemCount: paginatedTransactions.length,
                            itemBuilder: (context, index) {
                              Transaction transaction = paginatedTransactions[index];
                              return Card(
                                child: ListTile(
                                  title: Text('Transaction Code: ${transaction.transactionCode}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Customer: ${transaction.complete_name}'),
                                      Text('Kilos: ${transaction.kilo != null ? transaction.kilo.toString() : 'N/A'} kg'),
                                      Text('Status: ${transaction.status}'),
                                      Text('Date: ${transaction.date}'),
                                      Text('With Soap: ${transaction.withSoap ? 'Yes' : 'No'}'),
                                      Text('With Fabric Conditioner: ${transaction.withFabricCon ? 'Yes' : 'No'}'),
                                    ],
                                  ),
                                  trailing: Text('ID: ${transaction.id}'),
                                  onTap: () {
                                    // Navigate to the detail screen
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminViewTransaction(transactionCode: transaction.transactionCode),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        // Pagination controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Page ${_currentPage + 1} of ${( _filteredTransactions.length / _rowsPerPage).ceil()}',
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_back),
                                  onPressed: _currentPage > 0 ? _previousPage : null,
                                ),
                                IconButton(
                                  icon: Icon(Icons.arrow_forward),
                                  onPressed: (_currentPage + 1) * _rowsPerPage < _filteredTransactions.length ? _nextPage : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              ),
            ),

            SizedBox(height: 5),

            // Additional buttons
            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewTransactionViaQr()),
                );
              },
              child: Text("Finish Transaction via QR Code"),
            ),

            SizedBox(height: 1),

            ElevatedButton(
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanPickupLaundry()),
                );
              },
              child: Text("Pickup Laundry"),
            ),
          ],
        ),
      ),
    );
  }
}
