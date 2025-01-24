import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QrCodeScanner extends StatefulWidget {
  @override
  _QrCodeScannerState createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  final MobileScannerController _cameraController = MobileScannerController();
  String? _scannedData;

  @override
  void initState() {
    super.initState();
    // empezar lectura
    _cameraController.barcodes.listen((capture) {
      final List<Barcode> barcodes = capture.barcodes;
      for (final barcode in barcodes) {
        final String? code = barcode.rawValue; //leer el texto del qr
        if (code != null && code.isNotEmpty) {
          sendDataToApi(code);
          break; // parar despues de detectar el primer qr
        }
      }
    });
  }

  Future<void> sendDataToApi(String code) async {
    final response = await http.post(
      Uri.parse('http://app.cableaereomanizales.gov.co:28011/univiaje/estado_ticket'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'ticket': code}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _scannedData = response.body; 
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('QR Code Scanner')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _cameraController,
              onDetect: (BarcodeCapture capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final String? code = barcode.rawValue;
                  if (code != null && code.isNotEmpty) {
                    sendDataToApi(code);
                    break; //parar
                  }
                }
              },
            ),
          ),
          if (_scannedData != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Response: $_scannedData'),
            ),
        ],
      ),
    );
  }
}
