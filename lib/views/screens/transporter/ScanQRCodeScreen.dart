import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../widgets/SuccessDialog.dart';
import 'DeliveryTrackTransporterScreen.dart';

class Scanqrcodescreen extends StatefulWidget {
  final String orderId;
  const Scanqrcodescreen({super.key, required this.orderId});

  @override
  State<Scanqrcodescreen> createState() => _ScanqrcodescreenState();
}

class _ScanqrcodescreenState extends State<Scanqrcodescreen> {
  String? qrText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner un QR Code")),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() {
                    qrText = barcodes.first.rawValue;
                    print(qrText);
                  });

                  if (_validateQRCode(qrText!)) {

                  }
                }
              },
            ),
          ),

          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                qrText != null
                    ? _validateQRCode(qrText!)
                    ? "QR Code Valide ✅"
                    : "QR Code Invalide ❌"
                    : "Scannez un QR Code",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateQRCode(String code) {
    print("Order ID: ${widget.orderId}");
    return code=="Order ID: ${widget.orderId}";
  }
}
