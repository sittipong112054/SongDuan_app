import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/services/mock_realtime_service.dart';
import 'package:songduan_app/widgets/delivery_status_card.dart';
// import 'package:songduan_app/widgets/order_tile.dart' show OrderStatus;
import 'package:songduan_app/widgets/map_panel.dart';
import 'package:songduan_app/widgets/order_card.dart';

class ReceiverMapPage extends StatefulWidget {
  final String baseUrl;
  const ReceiverMapPage({super.key, required this.baseUrl});

  @override
  State<ReceiverMapPage> createState() => _ReceiverMapPageState();
}

class _ReceiverMapPageState extends State<ReceiverMapPage> {
  final _svc = MockRealtimeService();
  final _center = const LatLng(13.7563, 100.5018);

  static const _badgeColors = <Color>[
    Color(0xFF2C7BE5), // 1 ฟ้า
    Color(0xFF3BB54A), // 2 เขียว
    Color(0xFFE84C3D), // 3 แดง
  ];

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        n: 1,
        title: 'Incoming Delivery',
        by: 'Sender A',
        from: 'ร้านข้าวมันไก่',
        to: 'บ้านฉัน',
        status: OrderStatus.delivering,
      ),
      (
        n: 2,
        title: 'Incoming Delivery',
        by: 'Sender B',
        from: 'ร้านข้าวมันไก่',
        to: 'บ้านฉัน',
        status: OrderStatus.riderAccepted,
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        MapPanel(
          center: _center,
          svc: _svc,
          count: items.length,
          badgeColors: _badgeColors,
        ),
        const SizedBox(height: 12),

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
