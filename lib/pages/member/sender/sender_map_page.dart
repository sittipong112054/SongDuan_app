import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/services/mock_realtime_service.dart';

class SenderMapPage extends StatefulWidget {
  final String baseUrl;
  const SenderMapPage({super.key, required this.baseUrl});

  @override
  State<SenderMapPage> createState() => _SenderMapPageState();
}

class _SenderMapPageState extends State<SenderMapPage> {
  final _svc = MockRealtimeService();
  final _center = const LatLng(13.7563, 100.5018);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LatLng>>(
      stream: _svc.ridersStream(count: 4, center: _center),
      builder: (context, snap) {
        final riders = snap.data ?? const <LatLng>[];
        return FlutterMap(
          options: MapOptions(initialCenter: _center, initialZoom: 13.5),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'net.songduan.app',
            ),
            MarkerLayer(
              markers: riders
                  .map(
                    (p) => Marker(
                      point: p,
                      child: const Icon(
                        Icons.pedal_bike,
                        size: 28,
                        color: Colors.blue,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}
