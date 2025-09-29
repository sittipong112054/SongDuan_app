import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:songduan_app/services/mock_realtime_service.dart';

import 'package:songduan_app/widgets/delivery_status_card.dart';
import 'package:songduan_app/widgets/map_panel.dart';
import 'package:songduan_app/widgets/order_card.dart';

class SenderMapPage extends StatefulWidget {
  final String baseUrl;
  const SenderMapPage({super.key, required this.baseUrl});

  @override
  State<SenderMapPage> createState() => _SenderMapPageState();
}

class _SenderMapPageState extends State<SenderMapPage> {
  final _svc = MockRealtimeService();
  final _center = const LatLng(13.7563, 100.5018);

  // Badge สีตามลำดับงานบนแผนที่/การ์ด
  static const _badgeColors = <Color>[
    Color(0xFF3BB54A), // 1 เขียว
    Color(0xFF2C7BE5), // 2 ฟ้า
    Color(0xFFE84C3D), // 3 แดง
    Color(0xFF7C4DFF), // 4 ม่วง (เผื่ออนาคต)
  ];

  @override
  Widget build(BuildContext context) {
    // mock 3 งานให้เหมือนภาพ
    final items = [
      (
        n: 1,
        title: 'Food Delivery',
        by: 'John Cena',
        from: 'ร้านข้าวมันไก่',
        to: 'หอมีชัยแมนชั่น',
        status: OrderStatus.riderAccepted,
      ),
      (
        n: 2,
        title: 'Document Delivery',
        by: 'John Cetwo',
        from: 'ร้านข้าวมันไก่',
        to: 'หอมีชัยแมนชั่น',
        status: OrderStatus.delivering,
      ),
      (
        n: 3,
        title: 'Document Delivery',
        by: 'John Cethree',
        from: 'ร้านข้าวมันไก่',
        to: 'หอมีชัยแมนชั่น',
        status: OrderStatus.delivered,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        // แผนที่โค้ง+เงา พร้อมหมุดลำดับสี
        MapPanel(
          center: _center,
          svc: _svc,
          count: items.length,
          badgeColors: _badgeColors,
        ),
        const SizedBox(height: 12),

        // การ์ดสถานะงานตามลำดับ
        ...items.map(
          (it) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DeliveryStatusCard(
              number: it.n,
              badgeColor: _badgeColors[(it.n - 1) % _badgeColors.length],
              title: it.title,
              by: it.by,
              from: it.from,
              to: it.to,
              status: it.status,
            ),
          ),
        ),
      ],
    );
  }
}
