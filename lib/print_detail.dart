import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Add this package for QR code generation
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PrintDetails extends StatefulWidget {
  final String transactionCode;
  final String customerName;

  PrintDetails({required this.transactionCode, required this.customerName});

  @override
  _PrintDetailsState createState() => _PrintDetailsState();
}

class _PrintDetailsState extends State<PrintDetails> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool _connected = false;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    initBluetooth();
  }

  // Initialize Bluetooth and get the connected devices
  void initBluetooth() async {
    bool isConnected = await bluetooth.isConnected ?? false;
    List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
    setState(() {
      _connected = isConnected;
      _devices = devices;
    });
  }

  // Connect to selected Bluetooth device
  void connectToDevice(BluetoothDevice device) async {
    await bluetooth.connect(device);
    setState(() {
      _connected = true;
      _selectedDevice = device;
    });
  }

  // Disconnect the Bluetooth printer
  void disconnect() async {
    await bluetooth.disconnect();
    setState(() {
      _connected = false;
      _selectedDevice = null;
    });
  }

void _printDetails() {
    if (_connected) {
      
      bluetooth.printCustom("________________________________", 1, 1);


      bluetooth.paperCut();
    }
  }


  // Show Bluetooth device selection dialog
  void showDeviceList() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Bluetooth Printer'),
          content: Container(
            height: 200,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_devices[index].name ?? 'Unknown Device'),
                  onTap: () {
                    connectToDevice(_devices[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Print Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.bluetooth),
            onPressed: showDeviceList,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PrettyQr(
              data: widget.transactionCode,
              size: 200.0,
            ),
            SizedBox(height: 20),
            Text('${widget.transactionCode}'),
            Text('${widget.customerName}'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connected ? _printDetails : null,
              child: Text('Print'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
            ),
            SizedBox(height: 20),
            DropdownButton<BluetoothDevice>(
              items: _devices
                  .map((device) => DropdownMenuItem(
                        child: Text(device.name ?? ''),
                        value: device,
                      ))
                  .toList(),
              onChanged: (device) {
                setState(() {
                  _selectedDevice = device;
                });
                connectToDevice(device!);
              },
              hint: Text('Select Printer'),
              value: _selectedDevice,
            ),
          ],
        ),
      ),
    );
  }
}
