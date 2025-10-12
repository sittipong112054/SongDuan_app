import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:songduan_app/services/session_service.dart';
import 'package:songduan_app/widgets/delivery_status_card.dart';
import 'package:songduan_app/widgets/order_card.dart';

class SenderMapPage extends StatefulWidget {
  final String baseUrl;
  const SenderMapPage({super.key, required this.baseUrl});

  @override
  State<SenderMapPage> createState() => _SenderMapPageState();
}

class _SenderMapPageState extends State<SenderMapPage> {
  final MapController _map = MapController();
  bool _mapReady = false;

  bool _loading = true;
  String? _error;

  List<_Incoming> _items = [];
  final Map<int, LatLng> _riderPos = {};
  final Map<int, List<LatLng>> _routes = {};
  final Map<int, LatLng> _lastRoutedFrom = {};
  Timer? _pollTimer;

  int? _focusedIndex;

  static const _palette = <Color>[
    Color(0xFF2C7BE5),
    Color(0xFF3BB54A),
    Color(0xFFE84C3D),
    Color(0xFF8E44AD),
    Color(0xFFF39C12),
    Color(0xFF16A085),
  ];

  static const double _rerouteMetersThreshold = 30.0;
  final Map<int, DateTime> _lastRouteAt = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _fetchShipments();
      _startPollingRiders();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchShipments() async {
    final me = Get.find<SessionService>().currentUserId;
    if (me == null) throw Exception('ไม่พบ sender_id ใน SessionService');

    final uri = Uri.parse(
      '${widget.baseUrl}/shipments?sender_id=$me&pageSize=100',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('โหลดข้อมูลงานไม่สำเร็จ: HTTP ${resp.statusCode}');
    }

    final json =
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final list = (json['data'] as List? ?? []).whereType<Map>().toList();

    final parsed = <_Incoming>[];
    for (final r in list) {
      final status = (r['status'] ?? '').toString();
      if (status != 'RIDER_ACCEPTED' && status != 'PICKED_UP_EN_ROUTE') {
        continue;
      }

      final sender = r['sender'] as Map<String, dynamic>?;
      final pickup = r['pickup'] as Map<String, dynamic>?;
      final dropoff = r['dropoff'] as Map<String, dynamic>?;
      final assignment = r['assignment'] as Map<String, dynamic>?;
      final rider =
          assignment?['rider'] as Map<String, dynamic>? ??
          r['rider'] as Map<String, dynamic>?;
      final riderId = (assignment?['rider_id'] ?? r['rider_id']);
      final riderName = (rider?['name'] ?? 'ไรเดอร์').toString();

      parsed.add(
        _Incoming(
          shipmentId: (r['id'] as num).toInt(),
          title: (r['title'] ?? 'Incoming Delivery').toString(),
          status: status,
          senderAvatar: sender?['avatar_path'] as String?,
          riderName: riderName,
          pickupText: (pickup?['label'] ?? pickup?['address_text'] ?? 'จุดรับ')
              .toString(),
          dropoffText:
              (dropoff?['label'] ?? dropoff?['address_text'] ?? 'จุดส่ง')
                  .toString(),
          pickupLatLng: _toLatLng(pickup),
          dropoffLatLng: _toLatLng(dropoff),
          riderId: riderId is num ? riderId.toInt() : null,
          cover: r['cover_file_path'] as String?,
        ),
      );
    }

    parsed.sort((a, b) => b.shipmentId.compareTo(a.shipmentId));
    setState(() => _items = parsed);

    final validIds = _items.map((e) => e.shipmentId).toSet();
    _routes.keys
        .where((k) => !validIds.contains(k))
        .toList()
        .forEach(_routes.remove);

    _fitToAll();
  }

  void _startPollingRiders() {
    _pollTimer?.cancel();
    if (_items.isEmpty) return;

    Future<void> tick() async {
      try {
        final futures = <Future<void>>[];
        for (final it in _items) {
          final rid = it.riderId;
          if (rid != null) futures.add(_fetchRiderLocation(rid));
        }
        await Future.wait(futures);

        final now = DateTime.now();
        for (var i = 0; i < _items.length; i++) {
          await _ensureRouteFor(i, now: now);
        }

        if (!mounted) return;
        setState(() {});

        if (_focusedIndex != null && _focusedIndex! < _items.length) {
          _fitShipment(_focusedIndex!);
        } else {
          _fitToAll();
        }
      } catch (_) {}
    }

    tick();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => tick());
  }

  Future<void> _fetchRiderLocation(int riderId) async {
    final uri = Uri.parse(
      '${widget.baseUrl}/rider_locations/$riderId/location',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return;
    final j = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final d = j['data'] as Map<String, dynamic>?;
    if (d == null) return;
    final lat = (d['lat'] as num?)?.toDouble();
    final lng = (d['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    _riderPos[riderId] = LatLng(lat, lng);
  }

  LatLng? _toLatLng(Map<String, dynamic>? m) {
    if (m == null) return null;
    final lat = (m['lat'] as num?)?.toDouble();
    final lng = (m['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<void> _ensureRouteFor(int index, {DateTime? now}) async {
    if (index < 0 || index >= _items.length) return;
    final it = _items[index];
    if (it.riderId == null) return;

    final rp = _riderPos[it.riderId!];
    if (rp == null) return;

    LatLng? target;
    if (it.status == 'RIDER_ACCEPTED') {
      target = it.pickupLatLng;
    } else if (it.status == 'PICKED_UP_EN_ROUTE') {
      target = it.dropoffLatLng;
    } else {
      return;
    }
    if (target == null) return;

    final sid = it.shipmentId;

    final lastAt = _lastRouteAt[sid];
    final n = now ?? DateTime.now();
    if (lastAt != null && n.difference(lastAt).inMilliseconds < 4000) {
      return;
    }

    final lastFrom = _lastRoutedFrom[sid];
    final moved = lastFrom == null
        ? double.infinity
        : _distanceMeters(lastFrom, rp);
    if (moved < _rerouteMetersThreshold && _routes.containsKey(sid)) {
      return;
    }

    final pts = await _fetchOsrmRoute(rp, target);
    if (pts != null && pts.length >= 2) {
      _routes[sid] = pts;
      _lastRoutedFrom[sid] = rp;
      _lastRouteAt[sid] = n;
    }
  }

  Future<List<LatLng>?> _fetchOsrmRoute(LatLng from, LatLng to) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?overview=full&geometries=geojson';
    try {
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = j['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final geom = (routes.first as Map)['geometry'] as Map?;
      final coords = geom?['coordinates'] as List?;
      if (coords == null) return null;

      final out = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          final lon = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          out.add(LatLng(lat, lon));
        }
      }
      return out;
    } catch (_) {
      return null;
    }
  }

  void _fitToAll() {
    if (!_mapReady) return;
    final coords = <LatLng>[];

    for (final it in _items) {
      if (it.pickupLatLng != null) coords.add(it.pickupLatLng!);
      if (it.dropoffLatLng != null) coords.add(it.dropoffLatLng!);
      final rp = it.riderId != null ? _riderPos[it.riderId!] : null;
      if (rp != null) coords.add(rp);
    }
    if (coords.isEmpty) return;

    final fit = CameraFit.coordinates(
      coordinates: coords,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      maxZoom: 18,
    );
    _map.fitCamera(fit);
  }

  void _fitShipment(int index) {
    if (!_mapReady || index < 0 || index >= _items.length) return;
    final it = _items[index];
    final coords = <LatLng>[];
    if (it.pickupLatLng != null) coords.add(it.pickupLatLng!);
    if (it.dropoffLatLng != null) coords.add(it.dropoffLatLng!);
    final rp = it.riderId != null ? _riderPos[it.riderId!] : null;
    if (rp != null) coords.add(rp);
    if (coords.isEmpty) return;

    final fit = CameraFit.coordinates(
      coordinates: coords,
      padding: const EdgeInsets.fromLTRB(36, 36, 36, 36),
      maxZoom: 18,
    );
    _map.fitCamera(fit);
  }

  double _distanceMeters(LatLng a, LatLng b) {
    final d = const Distance();
    return d.as(LengthUnit.Meter, a, b);
  }

  String _short(String s, {int max = 14}) {
    final t = s.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max - 1)}…';
  }

  Color _routeColorFor(String status, Color base) {
    if (status == 'RIDER_ACCEPTED') {
      return Colors.blue.withOpacity(0.18);
    }
    if (status == 'PICKED_UP_EN_ROUTE') {
      return Colors.green.withOpacity(0.18);
    }
    return base.withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 8),
          _buildMapCard(),
          const SizedBox(height: 8),
          _buildLegendBar(),
          const SizedBox(height: 12),

          if (_loading) ...[
            const _SkeletonCard(),
            const SizedBox(height: 12),
            const _SkeletonCard(),
          ] else if (_error != null) ...[
            _ErrorTile(message: _error!, onRetry: _load),
          ] else if (_items.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'ยังไม่มีงานขาออกที่กำลังนำส่ง',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ] else ...[
            ..._items.indexed.map((e) {
              final i = e.$1;
              final it = e.$2;
              final status = switch (it.status) {
                'RIDER_ACCEPTED' => OrderStatus.riderAccepted,
                'PICKED_UP_EN_ROUTE' => OrderStatus.delivering,
                'DELIVERED' => OrderStatus.delivered,
                _ => OrderStatus.waitingPickup,
              };
              final color = _palette[i % _palette.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeliveryStatusCard(
                  number: i + 1,
                  badgeColor: color,
                  title: it.title,
                  by: it.riderName,
                  from: it.pickupText,
                  to: it.dropoffText,
                  status: status,
                  onTap: () {
                    setState(() => _focusedIndex = i);
                    _fitShipment(i);
                  },
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendBar() {
    if (_items.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _LegendChip(
            label: 'ดูทุกชุด',
            color: Colors.black87,
            selected: _focusedIndex == null,
            onTap: () {
              setState(() => _focusedIndex = null);
              _fitToAll();
            },
          ),
          const SizedBox(width: 6),
          ..._items.indexed.map((e) {
            final i = e.$1;
            final it = e.$2;
            final color = _palette[i % _palette.length];
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _LegendChip(
                label: '#${i + 1} ${_short(it.title)}',
                color: color,
                selected: _focusedIndex == i,
                onTap: () {
                  setState(() => _focusedIndex = i);
                  _fitShipment(i);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    final markers = <Marker>[];
    final circles = <CircleMarker>[];
    final polylines = <Polyline>[];

    final entries = (_focusedIndex == null)
        ? _items.indexed
        : [_items.indexed.elementAt(_focusedIndex!)];

    for (final ent in entries) {
      final i = ent.$1;
      final it = ent.$2;
      final color = _palette[i % _palette.length];

      final rp = it.riderId != null ? _riderPos[it.riderId!] : null;

      if (it.pickupLatLng != null) {
        circles.add(
          CircleMarker(
            point: it.pickupLatLng!,
            radius: 22,
            useRadiusInMeter: true,
            color: color.withOpacity(0.14),
            borderColor: color.withOpacity(0.7),
            borderStrokeWidth: 1.5,
          ),
        );
      }
      if (it.dropoffLatLng != null) {
        circles.add(
          CircleMarker(
            point: it.dropoffLatLng!,
            radius: 22,
            useRadiusInMeter: true,
            color: color.withOpacity(0.14),
            borderColor: color.withOpacity(0.7),
            borderStrokeWidth: 1.5,
          ),
        );
      }

      final routePts = _routes[it.shipmentId];
      final lineColor = _routeColorFor(it.status, color);
      if (routePts != null && routePts.length >= 2) {
        polylines.add(
          Polyline(
            points: routePts,
            strokeWidth: 5.5,
            color: lineColor.withOpacity(0.95),
          ),
        );
      } else {
        final pts = <LatLng>[];
        if (rp != null) pts.add(rp);
        final target = it.status == 'RIDER_ACCEPTED'
            ? it.pickupLatLng
            : it.dropoffLatLng;
        if (target != null) pts.add(target);
        if (pts.length >= 2) {
          polylines.add(
            Polyline(
              points: pts,
              strokeWidth: 3.5,
              color: lineColor.withOpacity(0.6),
            ),
          );
        }
      }

      if (it.pickupLatLng != null) {
        markers.add(
          Marker(
            point: it.pickupLatLng!,
            width: 40,
            height: 40,
            child: const Icon(
              Icons.store_mall_directory_rounded,
              color: Colors.blue,
              size: 28,
            ),
          ),
        );
      }
      if (it.dropoffLatLng != null) {
        markers.add(
          Marker(
            point: it.dropoffLatLng!,
            width: 40,
            height: 40,
            child: const Icon(Icons.home_filled, color: Colors.green, size: 28),
          ),
        );
      }
      if (rp != null) {
        markers.add(
          Marker(
            point: rp,
            width: 44,
            height: 44,
            child: _BadgeBike(n: i + 1, color: color),
          ),
        );
      }
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: const LatLng(13.7563, 100.5018),
          initialZoom: 12.5,
          onMapReady: () {
            _mapReady = true;
            if (_focusedIndex != null) {
              _fitShipment(_focusedIndex!);
            } else {
              _fitToAll();
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=0b03b55da9a64adab5790c1c9515b15a',
            userAgentPackageName: 'net.gonggang.osm_demo',
          ),
          if (circles.isNotEmpty) CircleLayer(circles: circles),
          if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}

class _Incoming {
  final int shipmentId;
  final String title;
  final String status;

  final String? senderAvatar;

  final String riderName;
  final String pickupText;
  final String dropoffText;
  final LatLng? pickupLatLng;
  final LatLng? dropoffLatLng;

  final int? riderId;
  final String? cover;

  _Incoming({
    required this.shipmentId,
    required this.title,
    required this.status,
    required this.senderAvatar,
    required this.riderName,
    required this.pickupText,
    required this.dropoffText,
    required this.pickupLatLng,
    required this.dropoffLatLng,
    required this.riderId,
    required this.cover,
  });
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _LegendChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.notoSansThai(
          fontWeight: FontWeight.w900,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: color,
      backgroundColor: color.withOpacity(0.10),
      shape: StadiumBorder(side: BorderSide(color: color.withOpacity(0.60))),
    );
  }
}

class _BadgeBike extends StatelessWidget {
  final int n;
  final Color color;
  const _BadgeBike({required this.n, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.pedal_bike_rounded, color: Colors.red, size: 26),
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC7C7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('ลองอีกครั้ง')),
        ],
      ),
    );
  }
}
