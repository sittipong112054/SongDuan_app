import 'package:flutter/material.dart';

class OrderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int status; // 1,2,3
  final VoidCallback? onTap;
  const OrderTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.onTap,
  });

  String get statusText => switch (status) {
    1 => 'รอไรเดอร์มารับสินค้า',
    2 => 'ไรเดอร์รับงาน (กำลังมารับ)',
    _ => 'ไรเดอร์รับสินค้าแล้ว (กำลังไปส่ง)',
  };

  IconData get statusIcon => switch (status) {
    1 => Icons.hourglass_bottom,
    2 => Icons.directions_bike,
    _ => Icons.local_shipping_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(statusIcon),
        title: Text(title),
        subtitle: Text('$subtitle\nสถานะ: $statusText'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
