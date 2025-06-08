import 'package:flutter/material.dart';
import '../../models/PackageItem.dart';
import '../../utils/colors.dart';
import '../screens/transporter/ScanQRCodeScreen.dart';

class DeliveryRequestTransporterCard extends StatelessWidget {
  final String id;
  final String type;
  final String cout;
  final String status;
  final String date;
  final String time;
  final Color statusColor;
  final String ?origine;
  final String ?destination;
  final List<PackageItem> packageItems;
  final bool isExpanded;
  final VoidCallback onToggleDetails;
  final VoidCallback ?onAccept;
  final VoidCallback ?onReject;
  final bool test;

  const DeliveryRequestTransporterCard({
    required this.id,
    required this.test,
    required this.cout,
    required this.type,
     this.origine,
     this.destination,
    required this.status,
    required this.statusColor,
    required this.packageItems,
    required this.isExpanded,
    required this.onToggleDetails,
     this.onAccept,
     this.onReject,
    required this.date,
    required this.time,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.delivery_dining, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Text(
                      "#$id",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            Divider(height: 24, thickness: 0.5),

            // Package Items List (Similar to the food items in the image)
            ...packageItems.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey[700]),
                      ),
                      SizedBox(width: 12),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'weight: ${item.weight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'height: ${item.height.toStringAsFixed(1)} cm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'width: ${item.width.toStringAsFixed(1)} cm',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )).toList(),

            // Route information

            Row(
              children: [
                Icon(Icons.location_on, color: primaryColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$origine',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Route visualization
            Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Container(
                width: 2,
                height: 24,
                color: Colors.grey.shade300,
              ),
            ),

            Row(
              children: [
                Icon(Icons.flag, color: Colors.red.shade700, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$destination',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Date:$date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              'Time:$time',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            // Date and price
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  Text(
                    'coût estimé:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    "7.2 TND",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: packageItems.map((item) => Container(
                    margin: EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item: ${item.title}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text('Width: ${item.width.toStringAsFixed(1)} cm',
                            style: TextStyle(color: Colors.grey[800], fontSize: 12)),
                        Text('Height: ${item.height.toStringAsFixed(1)} cm',
                            style: TextStyle(color: Colors.grey[800], fontSize: 12)),
                        Text('Weight: ${item.weight.toStringAsFixed(1)} kg',
                            style: TextStyle(color: Colors.grey[800], fontSize: 12)),
                      ],
                    ),
                  )).toList(),
                ),
              ),

            // Action Buttons (maintaining original functionality)
            if (test)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAccept,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 16,color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Accepter",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onReject,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close, size: 16,color: Colors.white,),
                            SizedBox(width: 8),
                            Text(
                              "Refuser",
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}