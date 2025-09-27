import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';

class MockRealtimeService {
  final _random = Random();

  // สตรีมตำแหน่งไรเดอร์หลายคน (สำหรับ “หลายชิ้น/หลายไรเดอร์”)
  Stream<List<LatLng>> ridersStream({int count = 3, LatLng? center}) async* {
    final c = center ?? LatLng(13.7563, 100.5018);
    var points = List.generate(count, (_) => jitter(c));
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      points = points.map((p) => jitter(p)).toList();
      yield points;
    }
  }

  // สตรีมสถานะออเดอร์สลับ 1→2→3→3→… (เดโม่)
  Stream<int> orderStatusStream() async* {
    int s = 1;
    while (true) {
      await Future.delayed(const Duration(seconds: 4));
      s = s == 1 ? 2 : (s == 2 ? 3 : 3);
      yield s;
    }
  }

  LatLng jitter(LatLng p) {
    final dLat = (_random.nextDouble() - 0.5) * 0.002;
    final dLng = (_random.nextDouble() - 0.5) * 0.002;
    return LatLng(p.latitude + dLat, p.longitude + dLng);
  }
}
