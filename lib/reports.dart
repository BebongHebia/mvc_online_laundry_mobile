import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class Reports extends StatefulWidget {
  @override
  _ReportsState createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final _settings = ConnectionSettings(
    host: '192.168.1.11',
    port: 3306,
    user: 'outside',
    db: 'mvc_laundry_service_db',
    password: '12345678',
  );

  List<Map<String, dynamic>> _salesData = [];
  List<Map<String, dynamic>> _weeklySummary = [];
  List<Map<String, dynamic>> _monthlySummary = [];
  List<Map<String, dynamic>> _yearlySummary = [];
  bool _isLoading = true;

  // Search and pagination
  String _searchTerm = '';
  int _currentPage = 0;
  int _rowsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    final conn = await MySqlConnection.connect(_settings);
    try {
      // Fetch all sales data
      var salesResult = await conn.query(
        'SELECT transaction_code, sales, date_paid FROM sales ORDER BY date_paid DESC',
      );
      _salesData = salesResult.map((row) {
        return {
          'transaction_code': row['transaction_code'],
          'sales': row['sales'],
          'date_paid': row['date_paid'],
        };
      }).toList();

      // Fetch weekly summary
      var weeklyResult = await conn.query('''
        SELECT 
          YEAR(date_paid) as year,
          MONTH(date_paid) as month,
          WEEK(date_paid) as week,
          SUM(sales) as total_sales
        FROM sales
        GROUP BY YEAR(date_paid), MONTH(date_paid), WEEK(date_paid)
        ORDER BY YEAR(date_paid) DESC, MONTH(date_paid) DESC, WEEK(date_paid) DESC
      ''');
      _weeklySummary = weeklyResult.map((row) {
        return {
          'year': row['year'],
          'month': row['month'],
          'week': row['week'],
          'total_sales': row['total_sales'],
        };
      }).toList();

      // Fetch monthly summary
      var monthlyResult = await conn.query('''
        SELECT 
          YEAR(date_paid) as year,
          MONTH(date_paid) as month,
          SUM(sales) as total_sales
        FROM sales
        GROUP BY YEAR(date_paid), MONTH(date_paid)
        ORDER BY YEAR(date_paid) DESC, MONTH(date_paid) DESC
      ''');
      _monthlySummary = monthlyResult.map((row) {
        return {
          'year': row['year'],
          'month': row['month'],
          'total_sales': row['total_sales'],
        };
      }).toList();

      // Fetch yearly summary
      var yearlyResult = await conn.query('''
        SELECT 
          YEAR(date_paid) as year,
          SUM(sales) as total_sales
        FROM sales
        GROUP BY YEAR(date_paid)
        ORDER BY YEAR(date_paid) DESC
      ''');
      _yearlySummary = yearlyResult.map((row) {
        return {
          'year': row['year'],
          'total_sales': row['total_sales'],
        };
      }).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("Database error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error retrieving data")),
      );
    } finally {
      await conn.close();
    }
  }

  // Filter sales data based on search term
  List<Map<String, dynamic>> _filterSalesData() {
    return _salesData.where((sale) {
      return sale['transaction_code']
          .toString()
          .toLowerCase()
          .contains(_searchTerm.toLowerCase());
    }).toList();
  }

  Future<void> _requestStoragePermission() async {
    if (await Permission.storage.isGranted) return;

    if (Platform.isAndroid && await Permission.manageExternalStorage.isGranted) return;

    var result = await Permission.storage.request();
    if (result.isDenied || result.isPermanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Storage permission is required to download the PDF')),
      );
      openAppSettings();
    }
  }

  Future<void> _downloadPdfReport() async {
  await _requestStoragePermission();

  try {
    // Open a directory picker
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    // If the user cancels or no directory is selected
    if (selectedDirectory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No directory selected')),
      );
      return;
    }

    // Generate the PDF content
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                headers: ['Transaction Code', 'Sales', 'Date Paid'],
                data: _salesData.map((sale) {
                  return [
                    sale['transaction_code'],
                    '₱${sale['sales'].toStringAsFixed(2)}',
                    sale['date_paid'],
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );

    // Save the file in the selected directory
    String filePath = '$selectedDirectory/SalesReport.pdf';
    File file = File(filePath);

    // Write the PDF content to the file
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF downloaded to: $filePath')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save PDF: $e')),
    );
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
        title: Text('Reports'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    DataTable(
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
                              DateTime? datePaid;
                              try {
                                datePaid = DateTime.parse(sale['date_paid']);
                              } catch (e) {
                                datePaid = null;
                              }

                              return DataRow(
                                cells: [
                                  DataCell(Text(sale['transaction_code'])),
                                  DataCell(Text(
                                      '₱${sale['sales'].toStringAsFixed(2)}')),
                                  DataCell(Text(
                                    datePaid != null
                                        ? DateFormat('yyyy-MM-dd')
                                            .format(datePaid)
                                        : 'Invalid Date',
                                  )),
                                ],
                              );
                            }).toList()
                          : [
                              DataRow(
                                cells: [
                                  DataCell(Text('No transactions found')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                ],
                              ),
                            ],
                    ),
                    SizedBox(height: 16),
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
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _downloadPdfReport,
                      child: Text('Download Report as PDF'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
