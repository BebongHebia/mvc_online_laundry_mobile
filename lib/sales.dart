import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';

class Sales extends StatefulWidget {
  @override
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  final _settings = ConnectionSettings(
    host: 'sql12.freesqldatabase.com',
    port: 3306,
    user: 'sql12742390',
    db: 'sql12742390',
    password: 'uUufMJnN8I',
  );

  double _totalSalesToday = 0.0;
  List<Map<String, dynamic>> _salesData = [];
  bool _isLoading = true;

  // Pagination variables
  int _currentPage = 0;
  int _rowsPerPage = 5;
  DateTime? _selectedDate; // Allow this to be nullable
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _fetchSalesData(); // Load all data initially
  }

  Future<void> _fetchSalesData() async {
    final conn = await MySqlConnection.connect(_settings);
    try {
      // Get today's date in 'yyyy-MM-dd' format for total sales calculation
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Query to get the total sales amount for today
      var totalResult = await conn.query(
        'SELECT SUM(sales) as totalSales FROM sales WHERE date_paid = ?',
        [today],
      );

      if (totalResult.isNotEmpty && totalResult.first['totalSales'] != null) {
        _totalSalesToday = totalResult.first['totalSales'];
      } else {
        _totalSalesToday = 0.0; // Reset if there are no sales today
      }

      // Define query and parameters based on _selectedDate
      String query;
      List<Object> parameters;

      if (_selectedDate != null) {
        // Use selected date to filter data
        final selectedDateString = '%${DateFormat('yyyy-MM-dd').format(_selectedDate!)}%';
        query = 'SELECT transaction_code, sales, date_paid FROM sales WHERE date_paid LIKE ? ORDER BY date_paid DESC';
        parameters = [selectedDateString];
      } else {
        // Fetch all records if no specific date is selected
        query = 'SELECT transaction_code, sales, date_paid FROM sales ORDER BY date_paid DESC';
        parameters = [];
      }

      // Execute query and map results
      var salesResults = await conn.query(query, parameters);

      _salesData = salesResults.map((row) {
        return {
          'transaction_code': row['transaction_code'],
          'sales': row['sales'],
          'date_paid': row['date_paid'],
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Database error: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error retrieving sales data")),
      );
    } finally {
      await conn.close();
    }
  }

  // Method to handle filtering by search term
  List<Map<String, dynamic>> _filterSalesData() {
    return _salesData.where((sale) {
      return sale['transaction_code'].toString().contains(_searchTerm);
    }).toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _fetchSalesData(); // Fetch new data based on the selected date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSalesData = _filterSalesData();
    final pageCount = (filteredSalesData.length / _rowsPerPage).ceil();
    final startIndex = _currentPage * _rowsPerPage;
    final endIndex = startIndex + _rowsPerPage;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sales'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    color: Colors.blue.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Sales Today: ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₱${_totalSalesToday.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Selected Date: ${_selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : 'All Records'}",
                        style: TextStyle(fontSize: 16),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: Text('Select Date'),
                      ),
                    ],
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          DataColumn(label: Text('Transaction Code')),
                          DataColumn(label: Text('Sales')),
                          DataColumn(label: Text('Date Paid')),
                        ],
                        rows: filteredSalesData.isNotEmpty
                            ? filteredSalesData
                                .skip(startIndex)
                                .take(_rowsPerPage)
                                .map((sale) {
                                  final datePaid = sale['date_paid'] is DateTime
                                      ? DateFormat('yyyy-MM-dd').format(sale['date_paid'])
                                      : sale['date_paid'].toString();
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(sale['transaction_code'])),
                                      DataCell(Text('₱${sale['sales'].toStringAsFixed(2)}')),
                                      DataCell(Text(datePaid)),
                                    ],
                                  );
                                }).toList()
                            : [
                                DataRow(cells: [
                                  DataCell(Text('No transactions found')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                ]),
                              ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                        child: Text('Previous'),
                      ),
                      Text('Page ${_currentPage + 1} of $pageCount'),
                      ElevatedButton(
                        onPressed: _currentPage < pageCount - 1
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                        child: Text('Next'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
