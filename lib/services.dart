import 'package:flutter/material.dart';
import 'package:mysql1/mysql1.dart';

class Services extends StatefulWidget {
  @override
  _ServicesState createState() => _ServicesState();
}

class _ServicesState extends State<Services> {
  List<Map<String, dynamic>> _servicesList = [];
  final TextEditingController _serviceController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // Database connection settings
  final ConnectionSettings _connectionSettings = ConnectionSettings(
    host: '192.168.1.9',
    port: 3306,
    user: 'outside',
    db: 'mvc_laundry_service_db',
    password: '12345678', // MySQL password
  );

  // Fetch services from the database
  Future<void> _fetchServices() async {
    final conn = await MySqlConnection.connect(_connectionSettings);
    var results = await conn.query('SELECT * FROM services');
    setState(() {
      _servicesList = results
          .map((row) => {'id': row[0], 'service': row[1], 'price': row[2]})
          .toList();
    });
    await conn.close();
  }

  // Add a new service to the database
  Future<void> _addService() async {
    final String service = _serviceController.text;
    final String price = _priceController.text;

    if (service.isNotEmpty && price.isNotEmpty) {
      final conn = await MySqlConnection.connect(_connectionSettings);
      await conn.query('INSERT INTO services (service, price) VALUES (?, ?)', [service, price]);
      await conn.close();

      // Clear input fields
      _serviceController.clear();
      _priceController.clear();

      // Refresh the services list
      _fetchServices();
    }
  }

  // Update a service
  Future<void> _updateService(int id) async {
    final String service = _serviceController.text;
    final String price = _priceController.text;

    if (service.isNotEmpty && price.isNotEmpty) {
      final conn = await MySqlConnection.connect(_connectionSettings);
      await conn.query('UPDATE services SET service = ?, price = ? WHERE id = ?', [service, price, id]);
      await conn.close();

      // Clear input fields
      _serviceController.clear();
      _priceController.clear();

      // Refresh the services list
      _fetchServices();
    }
  }

  // Delete a service
  Future<void> _deleteService(int id) async {
    final conn = await MySqlConnection.connect(_connectionSettings);
    await conn.query('DELETE FROM services WHERE id = ?', [id]);
    await conn.close();

    // Refresh the services list
    _fetchServices();
  }

  // Open the modal to add or update a service
  void _openServiceModal(int? serviceId) {
    if (serviceId != null) {
      // If serviceId is provided, it's an edit action
      final service = _servicesList.firstWhere((service) => service['id'] == serviceId);
      _serviceController.text = service['service'];
      _priceController.text = service['price'].toString();
    } else {
      _serviceController.clear();
      _priceController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(serviceId != null ? 'Update Service' : 'Add Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _serviceController,
                decoration: InputDecoration(labelText: 'Service Name'),
              ),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Price'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (serviceId != null) {
                  _updateService(serviceId);
                } else {
                  _addService();
                }
                Navigator.of(context).pop();
              },
              child: Text(serviceId != null ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _openServiceModal(null),
              child: Text('Add Service'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
          _servicesList.isNotEmpty
              ? Expanded(
                  child: SingleChildScrollView(
                    child: PaginatedDataTable(
                      header: Text('Service List'),
                      columns: [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Service')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Actions')),
                      ],
                      source: _DataSource(
                        services: _servicesList,
                        onUpdate: _openServiceModal,
                        onDelete: _deleteService,
                      ),
                      rowsPerPage: 5,
                      showFirstLastButtons: true,
                    ),
                  ),
                )
              : Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _DataSource extends DataTableSource {
  final List<Map<String, dynamic>> services;
  final Function(int) onUpdate;
  final Function(int) onDelete;

  _DataSource({
    required this.services,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    final service = services[index];
    return DataRow(
      cells: [
        DataCell(Text(service['id'].toString())),
        DataCell(Text(service['service'])),
        DataCell(Text(service['price'].toString())),
        DataCell(Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => onUpdate(service['id']),
            ),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => onDelete(service['id']),
            ),
          ],
        )),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => services.length;

  @override
  int get selectedRowCount => 0;
}
