import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:mysql1/mysql1.dart';

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

      static Future<void> updateTransactionStatus(String transactionCode) async {
        final conn = await connect();
        await conn.query(
          'UPDATE transactions SET status = ? WHERE transaction_code = ?',
          ['Picked-Up', transactionCode],
        );
        await conn.close();
      }
    }


class ScanPickupLaundry extends StatefulWidget {
  @override
  _ScanPickupLaundryState createState() => _ScanPickupLaundryState();
}

class _ScanPickupLaundryState extends State<ScanPickupLaundry> {
    final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
    QRViewController? controller;
    String? qrResult;
    bool isProcessing = false;


          // MySQL connection settings
    final _settings = ConnectionSettings(
      host: '192.168.1.11',
      port: 3306,
      user: 'outside',
      db: 'mvc_laundry_service_db',
      password: '12345678', // MySQL password
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
            title: Text('Scan QR To Pickup Laundry'),
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
          await DatabaseHelper.updateTransactionStatus(code);
          Navigator.pop(context);
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
