import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:songduan_app/services/session_service.dart';

class RiderDeliveryTrackingPage extends StatefulWidget {
  final String baseUrl;
  final int shipmentId;

  final LatLng pickup;
  final LatLng dropoff;
  final String? pickupLabel;
  final String? dropoffLabel;

  const RiderDeliveryTrackingPage({
    super.key,
    required this.baseUrl,
    required this.shipmentId,
    required this.pickup,
    required this.dropoff,
    this.pickupLabel,
    this.dropoffLabel,
  });

  @override
  State<RiderDeliveryTrackingPage> createState() =>
      _RiderDeliveryTrackingPageState();
}

class _RiderDeliveryTrackingPageState extends State<RiderDeliveryTrackingPage> {
  final MapController _map = MapController();

  bool _mapReady = false; // ✅ แผนที่พร้อมหรือยัง
  LatLng? _pendingCenter; // ✅ ศูนย์กลางที่รอขยับ
  double _pendingZoom = 16; // ✅ ซูมที่รอขยับ

  LatLng? _me;
  bool _loading = true;
  String? _error;

  Timer? _tick;
  StreamSubscription<Position>? _posSub;

  bool _pickedUp = false; // เปลี่ยนเป็น true เมื่อกด "รับพัสดุแล้ว"
  bool _picking = false;
  bool _finishing = false;

  // ระยะห่างล่าสุด (เมตร)
  double? _distToPickup;
  double? _distToDrop;

  static const double kGateMeters = 20.0; // ระยะอนุญาต

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  // ---------------- Location & Loop ----------------
  Future<void> _initLocation() async {
    try {
      final ok = await _ensurePermission();
      if (!ok) {
        setState(() {
          _error = 'ไม่ได้รับสิทธิ์การเข้าถึงตำแหน่ง';
          _loading = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _onPosition(LatLng(pos.latitude, pos.longitude));

      _posSub =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 3, // ยิงอีเวนต์ใหม่ทุกครั้งที่เคลื่อน ≥3 เมตร
            ),
          ).listen((p) {
            _onPosition(LatLng(p.latitude, p.longitude));
          });

      // ส่งตำแหน่งขึ้น backend ทุก 5 วิ
      _tick = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _sendLocation(),
      );
    } catch (e) {
      setState(() {
        _error = 'เปิดตำแหน่งไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  void _onPosition(LatLng latlng) {
    _me = latlng;
    _loading = false;

    _distToPickup = _distanceMeters(latlng, widget.pickup);
    _distToDrop = _distanceMeters(latlng, widget.dropoff);

    // ถ้า map พร้อมแล้วค่อย move เลย
    if (_mapReady) {
      _map.move(latlng, 16);
    } else {
      // ถ้ายัง → เก็บไว้แล้วค่อย move ตอน onMapReady
      _pendingCenter = latlng;
      _pendingZoom = 16;
    }

    if (mounted) setState(() {});
  }

  Future<bool> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  bool _sending = false;

  Future<void> _sendLocation() async {
    if (_sending) return;
    _sending = true;

    try {
      // ถ้ายังไม่มี _me → ขอ one-shot
      Position pos;
      if (_me == null) {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        ).timeout(const Duration(seconds: 5), onTimeout: () => throw 'timeout');
        _onPosition(LatLng(pos.latitude, pos.longitude));
      } else {
        // ใช้ _me ล่าสุด (เพราะใน stream เราอัปเดตแล้ว)
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
      }

      if (widget.baseUrl.isEmpty) return;
      final riderId = Get.find<SessionService>().currentUserId;
      if (riderId == null) return;

      final uri = Uri.parse(
        '${widget.baseUrl}/rider_locations/$riderId/location',
      );

      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': pos.latitude,
          'lng': pos.longitude,
          'heading_deg': pos.heading, // เพิ่มหัวมุม
          'speed_mps': pos.speed, // เพิ่มความเร็ว (เมตรต่อวินาที)
          'shipment_id': widget.shipmentId,
        }),
      );
    } catch (e) {
      // debugPrint('sendLocation error: $e');
    } finally {
      _sending = false;
    }
  }

  // ---------------- Status Actions (with gate ≤ 20m) ----------------
  bool get _canPickup =>
      _me != null && _distToPickup != null && _distToPickup! <= kGateMeters;

  bool get _canDeliver =>
      _pickedUp &&
      _me != null &&
      _distToDrop != null &&
      _distToDrop! <= kGateMeters;

  Future<void> _markPickedUp() async {
    if (_picking || !_canPickup) return;
    setState(() => _picking = true);
    try {
      final uri = Uri.parse(
        '${widget.baseUrl}/shipments/${widget.shipmentId}/pickup',
      );
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        setState(() => _pickedUp = true);
        Get.snackbar(
          'อัปเดตแล้ว',
          'เริ่มนำส่งสินค้า',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final b = _safeJson(resp);
        final msg = (b['error']?['message'] ?? 'HTTP ${resp.statusCode}')
            .toString();
        Get.snackbar('ผิดพลาด', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('ผิดพลาด', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _markDelivered() async {
    if (_finishing || !_canDeliver) return;
    setState(() => _finishing = true);
    try {
      final uri = Uri.parse(
        '${widget.baseUrl}/shipments/${widget.shipmentId}/deliver',
      );
      final resp = await http
          .post(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        Get.back(result: true); // ปิดหน้า → กลับไปหน้ารอรับงาน
      } else {
        final b = _safeJson(resp);
        final msg = (b['error']?['message'] ?? 'HTTP ${resp.statusCode}')
            .toString();
        Get.snackbar('ผิดพลาด', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('ผิดพลาด', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  // ---------------- Utils ----------------
  Map<String, dynamic> _safeJson(http.Response resp) {
    try {
      return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ใช้สูตร Haversine จาก geolocator ก็ได้—ที่นี่ใช้ geolocator เพื่อความแม่น
  double _distanceMeters(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  String _mLabel(double? m) {
    if (m == null) return '- m';
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(2)} km';
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    // กัน back จน “ส่งสำเร็จ”
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'นำส่งสินค้า (สด)',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w900),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null
                  ? Center(child: Text(_error!))
                  : Stack(
                      children: [
                        FlutterMap(
                          mapController: _map,
                          options: MapOptions(
                            initialCenter: _me ?? widget.pickup,
                            initialZoom: 16,
                            onMapReady: () {
                              _mapReady = true;
                              // ถ้ามีค่า center ที่รออยู่ ให้ขยับทันที
                              if (_pendingCenter != null) {
                                _map.move(_pendingCenter!, _pendingZoom);
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=0b03b55da9a64adab5790c1c9515b15a',
                              userAgentPackageName: 'net.gonggang.osm_demo',
                            ),

                            // วงรัศมี 20m ที่ pickup & dropoff
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: widget.pickup,
                                  radius: 20, // meters
                                  useRadiusInMeter: true,
                                  color: Colors.blue.withOpacity(0.18),
                                  borderStrokeWidth: 1.5,
                                  borderColor: Colors.blueAccent,
                                ),
                                CircleMarker(
                                  point: widget.dropoff,
                                  radius: 20,
                                  useRadiusInMeter: true,
                                  color: Colors.green.withOpacity(0.18),
                                  borderStrokeWidth: 1.5,
                                  borderColor: Colors.green,
                                ),
                              ],
                            ),

                            // หมุดตำแหน่ง
                            MarkerLayer(
                              markers: [
                                // ตัวเอง
                                if (_me != null)
                                  Marker(
                                    point: _me!,
                                    width: 52,
                                    height: 52,
                                    child: const Icon(
                                      Icons.pedal_bike_rounded,
                                      color: Colors.red,
                                      size: 38,
                                    ),
                                  ),

                                // pickup
                                Marker(
                                  point: widget.pickup,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    Icons.store_mall_directory_rounded,
                                    color: Colors.blue,
                                    size: 34,
                                  ),
                                ),

                                // dropoff
                                Marker(
                                  point: widget.dropoff,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    Icons.location_on_rounded,
                                    color: Colors.green,
                                    size: 36,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // ป้ายบอกระยะ
                        Positioned(
                          left: 12,
                          right: 12,
                          top: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: DefaultTextStyle(
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withOpacity(0.75),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'ไปจุดรับ: ${_mLabel(_distToPickup)}',
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'ไปจุดส่ง: ${_mLabel(_distToDrop)}',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ปุ่มควบคุม
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      (_canPickup && !_picking && !_pickedUp)
                                      ? _markPickedUp
                                      : null,
                                  icon: _picking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.play_arrow_rounded),
                                  label: Text(
                                    'รับพัสดุแล้ว',
                                    style: GoogleFonts.notoSansThai(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (_canDeliver && !_finishing)
                                      ? _markDelivered
                                      : null,
                                  icon: _finishing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    'ส่งสำเร็จ',
                                    style: GoogleFonts.notoSansThai(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }
}
