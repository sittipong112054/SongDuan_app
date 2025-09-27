import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/widgets/order_card.dart' show OrderStatus;

class MockRealtimeService {
  final _random = Random();

  // สตรีมตำแหน่งไรเดอร์หลายคน (สำหรับแผนที่รวม)
  Stream<List<LatLng>> ridersStream({int count = 3, LatLng? center}) async* {
    final c = center ?? const LatLng(13.7563, 100.5018);
    var points = List.generate(count, (_) => _jitter(c));
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      points = points.map((p) => _jitter(p)).toList();
      yield points;
    }
  }

  // สตรีมสถานะออเดอร์: 1→2→3→4→4…
  Stream<OrderStatus> orderStatusStream() async* {
    var s = OrderStatus.waitingPickup;
    while (true) {
      await Future.delayed(const Duration(seconds: 4));
      s = switch (s) {
        OrderStatus.waitingPickup => OrderStatus.riderAccepted,
        OrderStatus.riderAccepted => OrderStatus.delivering,
        OrderStatus.delivering => OrderStatus.delivered,
        OrderStatus.delivered => OrderStatus.delivered,
      };
      yield s;
    }
  }

  LatLng _jitter(LatLng p) {
    final dLat = (_random.nextDouble() - 0.5) * 0.002;
    final dLng = (_random.nextDouble() - 0.5) * 0.002;
    return LatLng(p.latitude + dLat, p.longitude + dLng);
  }
}
