import 'package:flutter/material.dart';
import 'package:mvc_online_laundry_service/admin_rec_scan_qr.dart';
import 'package:mvc_online_laundry_service/admin_transaction_list.dart';
import 'package:mvc_online_laundry_service/sales.dart';
import 'package:mvc_online_laundry_service/services.dart'; // Import the Services page
import 'package:mysql1/mysql1.dart';
import 'admin_users_page.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List<List<dynamic>> _tableData = [];

  @override
  void initState() {
    super.initState();
    fetchTableData();
  }

  Future<void> fetchTableData() async {
    final conn = await MySqlConnection.connect(ConnectionSettings(
        host: '192.168.1.11',
        port: 3306,
        user: 'outside',
        db: 'mvc_laundry_service_db',
        password: '12345678', // MySQL password
    ));

    var results = await conn.query(
        'SELECT * FROM transactions INNER JOIN users ON transactions.customer_id = users.id');

    setState(() {
      _tableData = results.map((row) => row.toList()).toList();
    });

    await conn.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView( // Use SingleChildScrollView
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                children: <Widget>[
                  _buildDashboardCard(Icons.people, 'Number of Users', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminUsersPage()),
                    );
                  }),
                  _buildDashboardCard(Icons.shopping_cart, 'Transaction List', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminTransactionList()),
                    );
                  }),
                  _buildDashboardCard(Icons.attach_money, 'Sales', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Sales()),
                    );
                  }),
                  _buildDashboardCard(Icons.design_services, 'Services', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Services()), // Navigate to Services page
                    );
                  }),
                ],
              ),
            ),
            _tableData.isNotEmpty
                ? PaginatedDataTable(
                    header: Text('Latest Transactions'),
                    columns: [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Transaction Code')),
                      DataColumn(label: Text('Name')),
                    ],
                    source: _DataSource(_tableData),
                    rowsPerPage: 5,
                    showFirstLastButtons: true,
                  )
                : Center(child: CircularProgressIndicator()),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminRecScanQr()),
                    );
                  },
                  child: Text('Receive Transaction'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Full width button
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(IconData icon, String title, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 40.0, color: Colors.blue),
              SizedBox(height: 20.0),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataSource extends DataTableSource {
  final List<List<dynamic>> _data;
  _DataSource(this._data);

  @override
  DataRow? getRow(int index) {
    if (index >= _data.length) return null;
    final row = _data[index];
    return DataRow(
      cells: [
        DataCell(Text(row[0].toString())),  // ID
        DataCell(Text(row[3].toString())),  // Transaction Code
        DataCell(Text(row[10].toString())), // Name
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => _data.length;
  @override
  int get selectedRowCount => 0;
}
