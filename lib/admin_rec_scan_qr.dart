import 'package:flutter/material.dart';
import 'package:mvc_online_laundry_service/admin_receive_transaction.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:mysql1/mysql1.dart';

class AdminRecScanQr extends StatefulWidget {
  @override
  _AdminRecScanQrState createState() => _AdminRecScanQrState();
}

class _AdminRecScanQrState extends State<AdminRecScanQr> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrResult;
  bool isProcessing = false; // Flag to prevent multiple navigations

  // MySQL connection settings
  final _settings = ConnectionSettings(
      host: 'sql12.freesqldatabase.com',
      port: 3306,
      user: 'sql12742390',
      db: 'sql12742390',
      password: 'uUufMJnN8I',
  );

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Transactions'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                qrResult != null ? 'Result: $qrResult' : 'Scan a QR code',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!isProcessing) {
        setState(() {
          isProcessing = true; // Set flag to true to prevent multiple scans
          qrResult = scanData.code;
        });

        await _checkQrCode(qrResult!);
        controller.pauseCamera(); // Pause the camera after scanning
      }
    });
  }

Future<void> _checkQrCode(String code) async {
  final conn = await MySqlConnection.connect(_settings);
  
  try {
    var result = await conn.query(
      'SELECT * FROM transactions WHERE transaction_code = ?',
      [code],
    );

    if (result.isNotEmpty) {
      // Pass the scanned transaction code to AdminReceiveTransaction
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminReceiveTransaction(transactionCode: code),
        ),
      ).then((_) {
        // Resume the camera and reset the flag when returning to this page
        setState(() {
          isProcessing = false;
        });
        controller?.resumeCamera();
      });
    } else {
      setState(() {
        isProcessing = false;
      });
      controller?.resumeCamera();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("QR Code not found in database")),
      );
    }
  } catch (e) {
    print("Database error: $e");
    setState(() {
      isProcessing = false;
    });
    controller?.resumeCamera();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error connecting to database")),
    );
  } finally {
    await conn.close();
  }
}

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
