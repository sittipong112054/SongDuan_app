import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:songduan_app/pages/rider/rider_delivery_tracking_page.dart';

class RiderJobMapPreviewPage extends StatefulWidget {
  final LatLng pickup;
  final LatLng dropoff;
  final String pickupLabel;
  final String dropoffLabel;

  final String? senderName;
  final String? senderPhone;
  final String? senderAddress;
  final String? senderAvatar;

  final String? receiverName;
  final String? receiverPhone;
  final String? receiverAddress;
  final String? receiverAvatar;

  const RiderJobMapPreviewPage({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.pickupLabel,
    required this.dropoffLabel,
    this.senderName,
    this.senderPhone,
    this.senderAddress,
    this.senderAvatar,
    this.receiverName,
    this.receiverPhone,
    this.receiverAddress,
    this.receiverAvatar,
  });

  @override
  State<RiderJobMapPreviewPage> createState() => _RiderJobMapPreviewPageState();
}

class _RiderJobMapPreviewPageState extends State<RiderJobMapPreviewPage> {
  final MapController _map = MapController();

  LatLng? _current;
  List<LatLng> _legCurrentToPickup = const [];
  List<LatLng> _legPickupToDrop = const [];
  bool _loading = true;
  String? _error;

  bool _infoExpanded = false;

  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

  final Distance _dist = const Distance();

  bool _osrmLegCurrentToPickup = true;
  bool _osrmLegPickupToDrop = true;

  double _polylineMeters(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double sum = 0;
    for (int i = 0; i < pts.length - 1; i++) {
      sum += _dist(pts[i], pts[i + 1]);
    }
    return sum;
  }

  String _fmtMeters(double m) {
    if (m < 1) return '0 m';
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    final km = m / 1000.0;
    return km < 10
        ? '${km.toStringAsFixed(2)} km'
        : '${km.toStringAsFixed(1)} km';
  }

  @override
  void initState() {
    super.initState();
    _initOnce();
  }

  Future<void> _initOnce() async {
    try {
      final cur = await _getCurrentPositionOnce();
      _current = cur;

      _legPickupToDrop = await _fetchRouteOSRM(widget.pickup, widget.dropoff);
      if (_legPickupToDrop.isEmpty) {
        _osrmLegPickupToDrop = false;
      }

      if (_current != null) {
        _legCurrentToPickup = await _fetchRouteOSRM(_current!, widget.pickup);
        if (_legCurrentToPickup.isEmpty) {
          _osrmLegCurrentToPickup = false;
        }
      }

      if (!_osrmLegPickupToDrop || !_osrmLegCurrentToPickup) {
        _error = 'บริการเส้นทาง (OSRM) ไม่สามารถใช้งานได้ชั่วคราว';
      }

      setState(() => _loading = false);
      _fitAll();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<LatLng?> _getCurrentPositionOnce() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      return null;
    }
    try {
      final p = await Geolocator.getCurrentPosition();
      return LatLng(p.latitude, p.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<List<LatLng>> _fetchRouteOSRM(LatLng from, LatLng to) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final resp = await http.get(url).timeout(const Duration(seconds: 12));
      if (resp.statusCode != 200) return const [];

      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      if (body is! Map ||
          body['routes'] is! List ||
          (body['routes'] as List).isEmpty) {
        return const [];
      }
      final geometry = (body['routes'] as List).first?['geometry'];
      if (geometry is! Map) return const [];
      final coords = geometry['coordinates'];
      if (coords is! List) return const [];

      final pts = <LatLng>[];
      for (final c in coords) {
        if (c is List && c.length >= 2) {
          final lng = (c[0] as num).toDouble();
          final lat = (c[1] as num).toDouble();
          pts.add(LatLng(lat, lng));
        }
      }
      return pts;
    } catch (_) {
      return const [];
    }
  }

  void _fitAll() {
    final pts = <LatLng>[
      widget.pickup,
      widget.dropoff,
      if (_current != null) _current!,
      ..._legPickupToDrop,
      ..._legCurrentToPickup,
    ];
    if (pts.isEmpty) return;
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(pts),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final polylines = <Polyline>[
      if (_legCurrentToPickup.isNotEmpty)
        Polyline(
          points: _legCurrentToPickup,
          strokeWidth: 5,
          color: Colors.blueAccent.withValues(alpha: 0.8),
        ),
      if (_legPickupToDrop.isNotEmpty)
        Polyline(
          points: _legPickupToDrop,
          strokeWidth: 5,
          color: Colors.greenAccent.withValues(alpha: 0.5),
        ),
    ];

    final double? mCurrentToPickup =
        (_osrmLegCurrentToPickup && _legCurrentToPickup.isNotEmpty)
        ? _polylineMeters(_legCurrentToPickup)
        : null;
    final double? mPickupToDrop =
        (_osrmLegPickupToDrop && _legPickupToDrop.isNotEmpty)
        ? _polylineMeters(_legPickupToDrop)
        : null;
    final double? mTotal = (mCurrentToPickup != null && mPickupToDrop != null)
        ? (mCurrentToPickup + mPickupToDrop)
        : null;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'ตัวอย่างแผนที่งาน',
          style: GoogleFonts.notoSansThai(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_orange, _gold],
            ),
          ),
        ),
        backgroundColor: _orange,
        actions: [
          IconButton(
            onPressed: _fitAll,
            icon: const Icon(Icons.center_focus_strong, color: Colors.white),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _current ?? widget.pickup,
              initialZoom: 13,
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.all &
                    ~InteractiveFlag.rotate &
                    ~InteractiveFlag.pinchMove,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=0b03b55da9a64adab5790c1c9515b15a',
                userAgentPackageName: 'net.gonggang.osm_demo',
              ),
              if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.pickup,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.store_mall_directory_rounded,
                      color: Colors.blue,
                      size: 36,
                    ),
                  ),
                  Marker(
                    point: widget.dropoff,
                    width: 44,
                    height: 44,
                    child: const Icon(
                      Icons.home_filled,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                  if (_current != null)
                    Marker(
                      point: _current!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.motorcycle_rounded,
                        color: Colors.red,
                        size: 36,
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (_error != null && !_loading)
            Positioned(
              left: 12,
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.25)),
                ),
                child: Text(
                  'เส้นทางไม่พร้อม: $_error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              radius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEA4335), Color(0xFFFF9C00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Dot(color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'จาก: ${widget.pickupLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 14,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.grey.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _Dot(color: Colors.green),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'ถึง: ${widget.dropoffLabel}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() {
                          _infoExpanded = !_infoExpanded;
                        }),
                        icon: Icon(
                          _infoExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (mCurrentToPickup != null)
                          _DistChip(
                            label: 'คุณ→รับ',
                            value: _fmtMeters(mCurrentToPickup),
                            icon: Icons.my_location,
                          ),
                        if (mPickupToDrop != null)
                          _DistChip(
                            label: 'รับ→ส่ง',
                            value: _fmtMeters(mPickupToDrop),
                            icon: Icons.route_rounded,
                          ),
                        if (mTotal != null)
                          _DistChip(
                            label: 'รวม',
                            value: _fmtMeters(mTotal),
                            icon: Icons.stacked_line_chart_rounded,
                            emphasized: true,
                          ),
                      ],
                    ),
                  ),

                  AnimatedCrossFade(
                    crossFadeState: _infoExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        const Divider(height: 16),
                        _PersonTile(
                          roleLabel: 'ผู้ส่ง',
                          roleColor: Colors.blue,
                          name: widget.senderName,
                          phone: widget.senderPhone,
                          address: widget.senderAddress ?? widget.pickupLabel,
                          avatarUrl: widget.senderAvatar,
                          fallbackIcon: Icons.store_rounded,
                        ),
                        const SizedBox(height: 8),
                        _PersonTile(
                          roleLabel: 'ผู้รับ',
                          roleColor: Colors.green,
                          name: widget.receiverName,
                          phone: widget.receiverPhone,
                          address:
                              widget.receiverAddress ?? widget.dropoffLabel,
                          avatarUrl: widget.receiverAvatar,
                          fallbackIcon: Icons.person_pin_circle_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white70,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding, this.radius});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      borderRadius: BorderRadius.circular(radius ?? 16),
      blur: 16,
      backgroundOpacity: 0.18,
      child: child,
    );
  }
}

class _PersonTile extends StatelessWidget {
  final String roleLabel;
  final Color roleColor;
  final String? name;
  final String? phone;
  final String? address;
  final String? avatarUrl;
  final IconData fallbackIcon;

  const _PersonTile({
    required this.roleLabel,
    required this.roleColor,
    required this.name,
    required this.phone,
    required this.address,
    required this.avatarUrl,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = (name?.trim().isNotEmpty == true) ? name! : '—';
    final displayPhone = (phone?.trim().isNotEmpty == true) ? phone! : '—';
    final displayAddress = (address?.trim().isNotEmpty == true)
        ? address!
        : '—';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AvatarOrIcon(url: avatarUrl, fallbackIcon: fallbackIcon),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(height: 1.35),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      roleLabel,
                      style: TextStyle(
                        color: roleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const TextSpan(text: '  '),
                TextSpan(
                  text: displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: 'โทร: $displayPhone',
                  style: const TextStyle(color: Colors.black87),
                ),
                const TextSpan(text: '\n'),
                TextSpan(
                  text: 'ที่อยู่: $displayAddress',
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarOrIcon extends StatelessWidget {
  final String? url;
  final IconData fallbackIcon;
  const _AvatarOrIcon({required this.url, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    const double size = 40;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: hasUrl
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(fallbackIcon, size: 22),
              )
            : Icon(fallbackIcon, size: 22),
      ),
    );
  }
}

class _DistChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  const _DistChip({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = emphasized
        ? Colors.black87
        : Colors.black.withValues(alpha: 0.75);
    const fg = Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          const Text(
            ' ',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: fg, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
