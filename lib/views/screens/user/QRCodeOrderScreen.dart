import 'package:flutter/material.dart';
import 'package:pfe/utils/api_const.dart';
import 'package:pfe/utils/colors.dart';

class Qrcodeorderscreen extends StatefulWidget {
  final String orderId;
  final String clientName;
  final String transpoteurName;
  final String date;
  final int phone;
  const Qrcodeorderscreen({super.key, required this.orderId, required this.clientName, required this.transpoteurName, required this.date, required this.phone});

  @override
  State<Qrcodeorderscreen> createState() => _QrcodeorderscreenState();
}

class _QrcodeorderscreenState extends State<Qrcodeorderscreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: primaryColor, // Blue background color
        child: Center(
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    'Order number ${widget.orderId}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // QR Code Image
                  Container(
                    width: 350,
                    height: 350,
                    color: Colors.white,
                     child: Image.network("${ApiConst.baseUrl}/api/v1/orders/${widget.orderId}/qrcode"),
                  ),
                  const SizedBox(height: 15),
                  // User Details in Grid
                  _buildInfoRow('Transporter name', 'Phone',
                      '${widget.transpoteurName}', '${widget.phone}'),
                  const SizedBox(height: 10),
                  _buildInfoRow('Customer name ', 'Time',
                      '${widget.clientName}', '${widget.date}'),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label1, String label2, String value1, String value2) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value1,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label2,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value2,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}