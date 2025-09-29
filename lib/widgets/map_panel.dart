import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/services/mock_realtime_service.dart';

class MapPanel extends StatelessWidget {
  final LatLng center;
  final MockRealtimeService svc;
  final int count;
  final List<Color> badgeColors;

  const MapPanel({
    super.key,
    required this.center,
    required this.svc,
    required this.count,
    required this.badgeColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: StreamBuilder<List<LatLng>>(
        stream: svc.ridersStream(count: count, center: center),
        builder: (context, snap) {
          final pts =
              snap.data ??
              List.generate(
                count,
                (i) => LatLng(
                  center.latitude + i * 0.002,
                  center.longitude + i * 0.002,
                ),
              );

          return FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 13.3),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=0b03b55da9a64adab5790c1c9515b15a',
                userAgentPackageName: 'net.songduan.app',
              ),
              MarkerLayer(
                markers: List.generate(pts.length, (i) {
                  final n = i + 1;
                  final c = badgeColors[i % badgeColors.length];
                  return Marker(
                    point: pts[i],
                    child: _NumberBadge(n: n, color: c),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int n;
  final Color color;
  const _NumberBadge({required this.n, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Positioned(
          bottom: -6,
          child: Container(
            width: 4,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}
