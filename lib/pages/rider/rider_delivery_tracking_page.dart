import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:songduan_app/pages/rider/rider_home_page.dart';
import 'package:songduan_app/services/api_helper.dart';
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
  bool _mapReady = false;
  LatLng? _pendingCenter;
  double _pendingZoom = 16;

  LatLng? _me;
  bool _loading = true;
  String? _error;

  Timer? _tick;
  StreamSubscription<Position>? _posSub;

  static const double kGateMeters = 20.0;

  bool _pickedUp = false;
  bool _actionBusy = false;

  double? _distToPickup;
  double? _distToDrop;

  bool get _canPickup =>
      _me != null && _distToPickup != null && _distToPickup! <= kGateMeters;
  bool get _canDeliver =>
      _pickedUp &&
      _me != null &&
      _distToDrop != null &&
      _distToDrop! <= kGateMeters;

  final _picker = ImagePicker();
  File? _pickupPhotoFile;
  File? _deliverPhotoFile;

  String? _pickupPhotoUrl;
  String? _deliverPhotoUrl;

  bool _navToDrop = false;
  List<LatLng> _routeLine = [];
  String? _etaText;
  double? _routeDistanceMeters;

  LatLng get _target => _navToDrop ? _dropoff : _pickup;

  late LatLng _pickup;
  late LatLng _dropoff;
  String? _pickupLabel;
  String? _dropoffLabel;

  double? _lastHeadingDegFromSensor;
  double? _lastSpeedMpsFromSensor;

  @override
  void initState() {
    super.initState();
    _pickup = widget.pickup;
    _dropoff = widget.dropoff;
    _pickupLabel = widget.pickupLabel;
    _dropoffLabel = widget.dropoffLabel;
    _bootstrap();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadShipmentStatus();
    if (!mounted) return;
    await _initLocation();
  }

  Future<void> _loadShipmentStatus() async {
    try {
      final uri = Uri.parse('${widget.baseUrl}/shipments/${widget.shipmentId}');
      final resp = await http
          .get(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 10));

      handleAuthErrorIfAny(resp);

      if (resp.statusCode == 200) {
        final body =
            jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;

        final status = (data?['status'] ?? '').toString();

        try {
          final p = data?['pickup'] as Map<String, dynamic>?;
          final d = data?['dropoff'] as Map<String, dynamic>?;
          if (p != null && p['lat'] != null && p['lng'] != null) {
            _pickup = LatLng(
              (p['lat'] as num).toDouble(),
              (p['lng'] as num).toDouble(),
            );
            _pickupLabel = (p['label'] ?? _pickupLabel)?.toString();
          }
          if (d != null && d['lat'] != null && d['lng'] != null) {
            _dropoff = LatLng(
              (d['lat'] as num).toDouble(),
              (d['lng'] as num).toDouble(),
            );
            _dropoffLabel = (d['label'] ?? _dropoffLabel)?.toString();
          }
        } catch (_) {}

        String? pickupPath = (data?['pickup_photo_path'] as String?)?.trim();
        String? deliverPath = (data?['deliver_photo_path'] as String?)?.trim();

        String toAbs(String? p) {
          if (p == null || p.isEmpty) return '';
          if (p.startsWith('http://') || p.startsWith('https://')) return p;
          final base = widget.baseUrl.endsWith('/')
              ? widget.baseUrl.substring(0, widget.baseUrl.length - 1)
              : widget.baseUrl;
          return '$base$p';
        }

        _pickupPhotoUrl = toAbs(pickupPath);
        _deliverPhotoUrl = toAbs(deliverPath);

        if (status == 'DELIVERED') {
          if (mounted) Get.offAll(() => const RiderHomePage());
          return;
        }

        if (status == 'PICKED_UP_EN_ROUTE') {
          _pickedUp = true;
          _navToDrop = true;
        } else {
          _pickedUp = false;
          _navToDrop = false;
        }

        if (mounted) {
          setState(() {});
          _updateRoute();
        }
      } else {
        // ไม่ใช่ 200 → แสดง error ที่อ่านออก (ถ้ามี)
        final err = jsonDecode(utf8.decode(resp.bodyBytes));
        final msg =
            err is Map &&
                err['error'] is Map &&
                err['error']['message'] is String
            ? err['error']['message'] as String
            : 'โหลดงานไม่สำเร็จ (HTTP ${resp.statusCode})';
        Get.snackbar('ผิดพลาด', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      // เงียบไว้ตามเดิม หรือจะแจ้งเตือนก็ได้
    }
  }

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
      _onPosition(LatLng(pos.latitude, pos.longitude), raw: pos);

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
        ),
      ).listen((p) => _onPosition(LatLng(p.latitude, p.longitude), raw: p));

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

  void _onPosition(LatLng latlng, {Position? raw}) {
    _me = latlng;
    _loading = false;

    _distToPickup = _distanceMeters(latlng, _pickup);
    _distToDrop = _distanceMeters(latlng, _dropoff);

    if (raw != null) {
      _lastHeadingDegFromSensor = raw.heading;
      _lastSpeedMpsFromSensor = raw.speed;
    }

    if (_mapReady) {
      _map.move(latlng, 16);
    } else {
      _pendingCenter = latlng;
      _pendingZoom = 16;
    }

    if (mounted) setState(() {});
    _updateRoute();
  }

  LatLng? _lastSent;
  DateTime? _lastSentAt;

  double _bearingDegrees(LatLng a, LatLng b) {
    final lat1 = a.latitude * (pi / 180.0);
    final lat2 = b.latitude * (pi / 180.0);
    final dLon = (b.longitude - a.longitude) * (pi / 180.0);
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x) * 180.0 / pi;
    return (brng + 360.0) % 360.0;
  }

  Future<void> _sendLocation() async {
    if (_me == null) return;

    double? headingDeg = _lastHeadingDegFromSensor;
    double? speedMps = _lastSpeedMpsFromSensor;

    final now = DateTime.now();
    if ((headingDeg == null || headingDeg.isNaN || headingDeg < 0) &&
        _lastSent != null) {
      headingDeg = _bearingDegrees(_lastSent!, _me!);
    }
    if ((speedMps == null || speedMps.isNaN || speedMps <= 0) &&
        _lastSent != null &&
        _lastSentAt != null) {
      final dt = now.difference(_lastSentAt!).inMilliseconds / 1000.0;
      if (dt > 0) {
        final d = _distanceMeters(_lastSent!, _me!);
        speedMps = d / dt;
      }
    }

    double round(double v, [int p = 6]) => double.parse(v.toStringAsFixed(p));
    final riderId = Get.find<SessionService>().currentUserId;
    if (riderId == null) return;

    final uri = Uri.parse(
      '${widget.baseUrl}/rider_locations/$riderId/location',
    );
    final payload = <String, dynamic>{
      'lat': round(_me!.latitude, 7),
      'lng': round(_me!.longitude, 7),
      'shipment_id': widget.shipmentId,
      if (headingDeg != null) 'heading_deg': round((headingDeg + 360) % 360, 2),
      if (speedMps != null) 'speed_mps': round(speedMps, 2),
    };

    try {
      final resp = await http
          .post(uri, headers: await authHeaders(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 10));

      handleAuthErrorIfAny(resp);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _lastSent = _me;
        _lastSentAt = now;
      } else {
        debugPrint('ส่ง location ไม่สำเร็จ: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดขณะอัปเดต location: $e');
    }
  }

  Future<void> _updateRoute() async {
    if (_me == null) return;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${_me!.longitude},${_me!.latitude};${_target.longitude},${_target.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final resp = await http.get(url).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final m = jsonDecode(resp.body) as Map<String, dynamic>;
        final routes = m['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final r = routes.first as Map<String, dynamic>;
          final geo = r['geometry'] as Map<String, dynamic>;
          final coords = (geo['coordinates'] as List)
              .whereType<List>()
              .map(
                (e) =>
                    LatLng((e[1] as num).toDouble(), (e[0] as num).toDouble()),
              )
              .toList();

          setState(() {
            _routeLine = coords;
            _routeDistanceMeters = (r['distance'] as num?)?.toDouble();
            final sec = (r['duration'] as num?)?.toDouble() ?? 0;
            _etaText = _fmtEta(sec);
          });
        }
      }
    } catch (_) {}
  }

  String _fmtEta(double seconds) {
    if (seconds <= 0) return '-';
    final m = (seconds / 60).round();
    if (m < 60) return '$m นาที';
    final h = m ~/ 60;
    final mm = m % 60;
    return '$h ชม $mm นาที';
  }

  Future<File?> _pickImage() async {
    final source = await Get.bottomSheet<ImageSource>(
      SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('ถ่ายภาพ'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('เลือกรูปจากเครื่อง'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
    if (source == null) return null;

    final x = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (x == null) return null;
    return File(x.path);
  }

  Future<bool> _uploadPhoto({
    required bool isPickup,
    required File file,
  }) async {
    final path = isPickup
        ? '/shipments/${widget.shipmentId}/pickup-photo'
        : '/shipments/${widget.shipmentId}/deliver-photo';
    final uri = Uri.parse('${widget.baseUrl}$path');

    try {
      final req = http.MultipartRequest('POST', uri);
      req.files.add(await http.MultipartFile.fromPath('photo', file.path));

      final headers = await authHeaders();
      headers.remove('Content-Type');
      req.headers.addAll(headers);

      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final resp = await http.Response.fromStream(streamed);

      handleAuthErrorIfAny(resp);

      if (resp.statusCode == 201) {
        final body = _safeJson(resp);
        final fp = (body['data']?['file_path'] ?? body['file_path'] ?? '')
            ?.toString();

        if (fp != null && fp.isNotEmpty) {
          String toAbs(String p) {
            if (p.startsWith('http://') || p.startsWith('https://')) return p;
            final base = widget.baseUrl.endsWith('/')
                ? widget.baseUrl.substring(0, widget.baseUrl.length - 1)
                : widget.baseUrl;
            return '$base$p';
          }

          if (mounted) {
            setState(() {
              if (isPickup) {
                _pickupPhotoUrl = toAbs(fp);
              } else {
                _deliverPhotoUrl = toAbs(fp);
              }
            });
          }
        }

        Get.snackbar(
          'อัปโหลดสำเร็จ',
          isPickup ? 'บันทึกรูปตอนรับแล้ว' : 'บันทึกรูปตอนส่งแล้ว',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        final b = _safeJson(resp);
        final msg = (b['error']?['message'] ?? 'HTTP ${resp.statusCode}')
            .toString();
        Get.snackbar(
          'อัปโหลดไม่สำเร็จ',
          msg,
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'อัปโหลดไม่สำเร็จ',
        '$e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  Future<bool> _markPickedUp() async {
    final uri = Uri.parse(
      '${widget.baseUrl}/shipments/${widget.shipmentId}/pickup',
    );

    try {
      final resp = await http
          .post(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 12));

      handleAuthErrorIfAny(resp);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        if (mounted) {
          setState(() {
            _pickedUp = true;
            _navToDrop = true;
          });
          _updateRoute();
        }
        Get.snackbar(
          'อัปเดตแล้ว',
          'เริ่มนำส่งสินค้า',
          snackPosition: SnackPosition.BOTTOM,
        );
        return true;
      } else {
        final b = _safeJson(resp);
        final msg = (b['error']?['message'] ?? 'HTTP ${resp.statusCode}')
            .toString();
        Get.snackbar('ผิดพลาด', msg, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      Get.snackbar('ผิดพลาด', '$e', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<bool> _markDelivered() async {
    final uri = Uri.parse(
      '${widget.baseUrl}/shipments/${widget.shipmentId}/deliver',
    );

    try {
      final resp = await http
          .post(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 12));

      handleAuthErrorIfAny(resp);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        try {
          await _posSub?.cancel();
        } catch (_) {}
        _tick?.cancel();
        Get.offAll(() => const RiderHomePage());
        return true;
      } else {
        final b = _safeJson(resp);
        final msg = (b['error']?['message'] ?? 'HTTP ${resp.statusCode}')
            .toString();
        Get.snackbar('ผิดพลาด', msg, snackPosition: SnackPosition.BOTTOM);
        return false;
      }
    } catch (e) {
      Get.snackbar('ผิดพลาด', '$e', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<void> _onAction() async {
    if (!_pickedUp) {
      if (!_canPickup || _actionBusy) return;

      setState(() => _actionBusy = true);
      try {
        final file = await _pickImage();
        if (file == null) return;
        final okUpload = await _uploadPhoto(isPickup: true, file: file);
        if (!okUpload) return;
        setState(() => _pickupPhotoFile = file);

        await _markPickedUp();
      } finally {
        if (mounted) setState(() => _actionBusy = false);
      }
      return;
    }

    if (_pickedUp) {
      if (!_canDeliver || _actionBusy) return;

      setState(() => _actionBusy = true);
      try {
        final file = await _pickImage();
        if (file == null) return;
        final okUpload = await _uploadPhoto(isPickup: false, file: file);
        if (!okUpload) return;
        setState(() => _deliverPhotoFile = file);

        await _markDelivered();
      } finally {
        if (mounted) setState(() => _actionBusy = false);
      }
    }
  }

  Map<String, dynamic> _safeJson(http.Response resp) {
    try {
      return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final isPickupPhase = !_pickedUp;
    final canDoNow = isPickupPhase ? _canPickup : _canDeliver;

    final hintText = isPickupPhase
        ? (canDoNow ? null : 'ต้องอยู่ในระยะ ≤ 20 เมตรจากจุดรับ')
        : (canDoNow ? null : 'ต้องอยู่ในระยะ ≤ 20 เมตรจากจุดส่ง');

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'Rider นำส่งสินค้า',
            style: GoogleFonts.notoSansThai(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFFEA4335), Color(0xFFFF9C00)],
              ),
            ),
          ),
          backgroundColor: const Color(0xFFEA4335),
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
                            initialCenter: _me ?? _pickup,
                            initialZoom: 16,
                            interactionOptions: InteractionOptions(
                              flags:
                                  InteractiveFlag.all & ~InteractiveFlag.rotate,
                            ),
                            onMapReady: () {
                              _mapReady = true;
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
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _pickup,
                                  radius: 20,
                                  useRadiusInMeter: true,
                                  color: Colors.blue.withOpacity(0.18),
                                  borderStrokeWidth: 1.5,
                                  borderColor: Colors.blueAccent,
                                ),
                                CircleMarker(
                                  point: _dropoff,
                                  radius: 20,
                                  useRadiusInMeter: true,
                                  color: Colors.green.withOpacity(0.18),
                                  borderStrokeWidth: 1.5,
                                  borderColor: Colors.green,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
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
                                Marker(
                                  point: _pickup,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    Icons.store_mall_directory_rounded,
                                    color: Colors.blue,
                                    size: 34,
                                  ),
                                ),
                                Marker(
                                  point: _dropoff,
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
                            PolylineLayer(
                              polylines: _routeLine.isEmpty
                                  ? const <Polyline>[]
                                  : <Polyline>[
                                      Polyline(
                                        points: _routeLine,
                                        strokeWidth: 7,
                                        color: _pickedUp
                                            ? Colors.greenAccent.withOpacity(
                                                0.8,
                                              )
                                            : Colors.blueAccent.withOpacity(
                                                0.8,
                                              ),
                                        borderStrokeWidth: 2.5,
                                        borderColor: Colors.black.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ],
                            ),
                          ],
                        ),

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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                  if (_etaText != null ||
                                      _routeDistanceMeters != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'เส้นทาง: ${_routeDistanceMeters == null ? '-' : _mLabel(_routeDistanceMeters)}',
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'เวลาโดยประมาณ: ${_etaText ?? '-'}',
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 72 + 12 + 8,
                          child: Row(
                            children: [
                              Expanded(
                                child: _PreviewBox(
                                  file: _pickupPhotoFile,
                                  url: _pickupPhotoUrl,
                                  placeholder: _pickedUp
                                      ? 'รับแล้ว'
                                      : 'ยังไม่มีรูปตอนรับ',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PreviewBox(
                                  file: _deliverPhotoFile,
                                  url: _deliverPhotoUrl,
                                  placeholder: _pickedUp
                                      ? 'ยังไม่มีรูปตอนส่ง'
                                      : 'รอรับก่อนถึงถ่ายตอนส่งได้',
                                ),
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: Tooltip(
                            message: hintText ?? '',
                            child: ElevatedButton.icon(
                              onPressed: (!canDoNow || _actionBusy)
                                  ? null
                                  : _onAction,
                              icon: _actionBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_outlined),
                              label: Text(
                                isPickupPhase
                                    ? 'ถ่ายรูป & รับพัสดุ'
                                    : 'ถ่ายรูป & ส่งสำเร็จ',
                                style: GoogleFonts.notoSansThai(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPickupPhase
                                    ? Colors.blue
                                    : Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
      ),
    );
  }
}

class _PreviewBox extends StatefulWidget {
  final File? file;
  final String? url;
  final String? placeholder;

  const _PreviewBox({this.file, this.url, this.placeholder});

  @override
  State<_PreviewBox> createState() => _PreviewBoxState();
}

class _PreviewBoxState extends State<_PreviewBox> {
  int _retry = 0;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Colors.black.withOpacity(0.05));
    final deco = BoxDecoration(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(12),
      border: border,
    );

    if (widget.file != null) {
      return Container(
        height: 86,
        decoration: deco,
        clipBehavior: Clip.antiAlias,
        child: Image.file(
          widget.file!,
          fit: BoxFit.cover,
          width: double.infinity,
        ),
      );
    }

    final rawUrl = (widget.url ?? '').trim();
    if (rawUrl.isEmpty) {
      return _placeholderBox(deco, widget.placeholder ?? 'No photo');
    }

    final withBuster = _appendCacheBuster(rawUrl, _retry);
    final uri = Uri.tryParse(withBuster);

    if (uri == null || (!uri.hasScheme && !withBuster.startsWith('/'))) {
      return _placeholderBox(deco, widget.placeholder ?? 'No photo');
    }

    return Container(
      height: 86,
      decoration: deco,
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        withBuster,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return _loadingBox();
        },
        errorBuilder: (ctx, err, stack) {
          return _errorBox(
            onRetry: () {
              setState(() => _retry++);
            },
          );
        },
        gaplessPlayback: true,
      ),
    );
  }

  Widget _placeholderBox(BoxDecoration deco, String text) {
    return Container(
      height: 86,
      decoration: deco,
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.notoSansThai(
          color: Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _loadingBox() {
    return Container(
      color: const Color(0xFFF0F2F5),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _errorBox({required VoidCallback onRetry}) {
    return Container(
      color: const Color(0xFFF0F2F5),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: Colors.black54),
              const SizedBox(height: 6),
              Text(
                ' โหลดรูปไม่สำเร็จ',
                style: GoogleFonts.notoSansThai(
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('ลองอีกครั้ง'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 0),
            ),
          ),
        ],
      ),
    );
  }

  String _appendCacheBuster(String url, int retry) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final u = Uri.parse(url);
      final q = Map<String, String>.from(u.queryParameters);
      q['v'] = DateTime.now().millisecondsSinceEpoch.toString();
      final newUri = u.replace(queryParameters: q);
      return newUri.toString();
    }
    return url.contains('?')
        ? '$url&v=${DateTime.now().millisecondsSinceEpoch + retry}'
        : '$url?v=${DateTime.now().millisecondsSinceEpoch + retry}';
  }
}
