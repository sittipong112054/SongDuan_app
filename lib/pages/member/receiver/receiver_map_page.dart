import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/services/mock_realtime_service.dart';

class ReceiverMapPage extends StatefulWidget {
  final String baseUrl;
  const ReceiverMapPage({super.key, required this.baseUrl});

  @override
  State<ReceiverMapPage> createState() => _ReceiverMapPageState();
}

class _ReceiverMapPageState extends State<ReceiverMapPage> {
  final _svc = MockRealtimeService();
  final _home = const LatLng(13.7563, 100.5018); // จุดบ้านผู้รับ (mock)

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(initialCenter: _home, initialZoom: 13.8),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'net.songduan.app',
        ),
        // จุดบ้าน/ปลายทาง
        MarkerLayer(
          markers: [
            Marker(
              point: _home,
              child: const Icon(Icons.home, color: Colors.green, size: 28),
            ),
          ],
        ),
        // ไรเดอร์หลายคนวิ่งเข้าหาเรา
        StreamBuilder<List<LatLng>>(
          stream: _svc.ridersStream(count: 3, center: _home),
          builder: (context, snap) {
            final riders = snap.data ?? const <LatLng>[];
            return MarkerLayer(
              markers: riders
                  .map(
                    (p) => Marker(
                      point: p,
                      child: const Icon(
                        Icons.delivery_dining,
                        color: Colors.deepOrange,
                        size: 28,
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
