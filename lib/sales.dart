import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';

import 'reports.dart';

class Sales extends StatefulWidget {
  @override
  _SalesState createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  final _settings = ConnectionSettings(
    host: '192.168.1.11',
    port: 3306,
    user: 'outside',
    db: 'mvc_laundry_service_db',
    password: '12345678', // MySQL password
  );

  double _totalSalesToday = 0.0;
  double _weeklySales = 0.0;
  double _monthlySales = 0.0;
  double _yearlySales = 0.0;
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
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Calculate start of the week (Monday)
      final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
      final startOfWeekStr = DateFormat('yyyy-MM-dd').format(startOfWeek);

      // Calculate start of the month (1st of the month)
      final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
      final startOfMonthStr = DateFormat('yyyy-MM-dd').format(startOfMonth);

      // Calculate start of the year (1st of January)
      final startOfYear = DateTime(DateTime.now().year, 1, 1);
      final startOfYearStr = DateFormat('yyyy-MM-dd').format(startOfYear);

      // Query to get the total sales amount for today
      var totalResult = await conn.query(
        'SELECT SUM(sales) as totalSales FROM sales WHERE date_paid = ?',
        [today],
      );

      if (totalResult.isNotEmpty && totalResult.first['totalSales'] != null) {
        _totalSalesToday = totalResult.first['totalSales'];
      } else {
        _totalSalesToday = 0.0;
      }

      // Query to get total weekly sales
      var weeklyResult = await conn.query(
        'SELECT SUM(sales) as weeklySales FROM sales WHERE date_paid BETWEEN ? AND ?',
        [startOfWeekStr, today],
      );

      if (weeklyResult.isNotEmpty && weeklyResult.first['weeklySales'] != null) {
        _weeklySales = weeklyResult.first['weeklySales'];
      } else {
        _weeklySales = 0.0;
      }

      // Query to get total monthly sales
      var monthlyResult = await conn.query(
        'SELECT SUM(sales) as monthlySales FROM sales WHERE date_paid BETWEEN ? AND ?',
        [startOfMonthStr, today],
      );

      if (monthlyResult.isNotEmpty && monthlyResult.first['monthlySales'] != null) {
        _monthlySales = monthlyResult.first['monthlySales'];
      } else {
        _monthlySales = 0.0;
      }

      // Query to get total yearly sales
      var yearlyResult = await conn.query(
        'SELECT SUM(sales) as yearlySales FROM sales WHERE date_paid BETWEEN ? AND ?',
        [startOfYearStr, today],
      );

      if (yearlyResult.isNotEmpty && yearlyResult.first['yearlySales'] != null) {
        _yearlySales = yearlyResult.first['yearlySales'];
      } else {
        _yearlySales = 0.0;
      }

      // Query for filtered sales data
      String query;
      List<Object> parameters;

      if (_selectedDate != null) {
        final selectedDateString = '%${DateFormat('yyyy-MM-dd').format(_selectedDate!)}%';
        query = 'SELECT transaction_code, sales, date_paid FROM sales WHERE date_paid LIKE ? ORDER BY date_paid DESC';
        parameters = [selectedDateString];
      } else {
        query = 'SELECT transaction_code, sales, date_paid FROM sales ORDER BY date_paid DESC';
        parameters = [];
      }

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
                  // Total Sales Today Panel
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

                  // Weekly Sales Panel
                  Card(
                    color: Colors.green.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Weekly Sales: ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₱${_weeklySales.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Monthly Sales Panel
                  Card(
                    color: Colors.orange.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Monthly Sales: ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₱${_monthlySales.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, color: Colors.orange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Yearly Sales Panel
                  Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Yearly Sales: ',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₱${_yearlySales.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 18, color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Date Selection and Search
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

                  // Sales Data Table
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

                  // Pagination Controls
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

                  // Add navigation button
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Reports()),
                        );
                      },
                      child: Text('Go to Reports'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
