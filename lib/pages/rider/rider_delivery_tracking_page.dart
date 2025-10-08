import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  // Map
  final MapController _map = MapController();
  bool _mapReady = false;
  LatLng? _pendingCenter;
  double _pendingZoom = 16;

  // Location state
  LatLng? _me;
  bool _loading = true;
  String? _error;

  Timer? _tick;
  StreamSubscription<Position>? _posSub;

  // Status rules
  static const double kGateMeters = 20.0;
  bool _pickedUp = false; // เซ็ตเมื่อ “รับพัสดุแล้ว”
  bool _actionBusy = false; // บล็อกปุ่มหลักระหว่างทำงาน

  double? _distToPickup;
  double? _distToDrop;

  bool get _canPickup =>
      _me != null && _distToPickup != null && _distToPickup! <= kGateMeters;

  bool get _canDeliver =>
      _pickedUp &&
      _me != null &&
      _distToDrop != null &&
      _distToDrop! <= kGateMeters;

  // Photos preview
  final _picker = ImagePicker();
  File? _pickupPhotoFile;
  File? _deliverPhotoFile;

  // ====== NAV STATE ======
  bool _navToDrop = false; // false = ไป “รับ”, true = ไป “ส่ง”
  List<LatLng> _routeLine = [];
  String? _etaText; // ETA text
  double? _routeDistanceMeters; // ระยะรวมจาก routing

  LatLng get _target => _navToDrop ? widget.dropoff : widget.pickup;

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

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3, // อัปเดตเมื่อเคลื่อน ≥ 3 เมตร
        ),
      ).listen((p) => _onPosition(LatLng(p.latitude, p.longitude)));

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

    if (_mapReady) {
      _map.move(latlng, 16);
    } else {
      _pendingCenter = latlng;
      _pendingZoom = 16;
    }

    if (mounted) setState(() {});
    _updateRoute(); // อัปเดตเส้นทางและ ETA ทุกครั้งที่ตำแหน่งเราเปลี่ยน
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

  Future<void> _sendLocation() async {
    if (_me == null) return;
    try {
      final riderId = Get.find<SessionService>().currentUserId;
      if (riderId == null) return;

      final uri = Uri.parse(
        '${widget.baseUrl}/rider_locations/$riderId/location',
      );
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': _me!.latitude,
          'lng': _me!.longitude,
          'shipment_id': widget.shipmentId,
        }),
      );
    } catch (_) {}
  }

  // ---------------- Routing (OSRM public) ----------------
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
    } catch (_) {
      // เงียบไว้ กรณีออฟไลน์/เรียกไม่ติด
    }
  }

  String _fmtEta(double seconds) {
    if (seconds <= 0) return '-';
    final m = (seconds / 60).round();
    if (m < 60) return '$m นาที';
    final h = m ~/ 60;
    final mm = m % 60;
    return '$h ชม ${mm} นาที';
  }

  // ---------------- Photo helpers ----------------
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

    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('photo', file.path));

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 201) {
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
  }

  // ---------------- Status API ----------------
  Future<bool> _markPickedUp() async {
    final uri = Uri.parse(
      '${widget.baseUrl}/shipments/${widget.shipmentId}/pickup',
    );
    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      setState(() {
        _pickedUp = true;
        _navToDrop = true; // หลังรับแล้ว → นำทางไปจุดส่ง
      });
      _updateRoute();
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
  }

  Future<bool> _markDelivered() async {
    final uri = Uri.parse(
      '${widget.baseUrl}/shipments/${widget.shipmentId}/deliver',
    );
    final resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 12));

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      // หยุด stream/timer กันรั่ว
      try {
        await _posSub?.cancel();
      } catch (_) {}
      _tick?.cancel();

      // กลับหน้าหลัก + refresh + snackbar
      Get.offAllNamed(
        '/rider/home',
        arguments: {'refresh': true, 'snack': 'จัดส่งสำเร็จแล้ว'},
      );
      return true;
    } else {
      final b = _safeJson(resp);
      final msg = (b['error']?['message'] ?? 'HTTP ${resp.statusCode}')
          .toString();
      Get.snackbar('ผิดพลาด', msg, snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // ---------------- Single Action Button ----------------
  Future<void> _onAction() async {
    // ยังไม่ pickup → ต้องอยู่ในระยะ pickup ก่อน
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

    // pickup แล้ว → ต้องอยู่ในระยะ dropoff ก่อน
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

  // ---------------- Utils ----------------
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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final isPickupPhase = !_pickedUp;
    final canDoNow = isPickupPhase ? _canPickup : _canDeliver;
    final btnText = isPickupPhase
        ? 'ถ่ายรูป & รับพัสดุ'
        : 'ถ่ายรูป & ส่งสำเร็จ';
    final hintText = isPickupPhase
        ? (canDoNow ? null : 'ต้องอยู่ในระยะ ≤ 20 เมตรจากจุดรับ')
        : (canDoNow ? null : 'ต้องอยู่ในระยะ ≤ 20 เมตรจากจุดส่ง');

    return WillPopScope(
      onWillPop: () async => false, // บังคับอยู่หน้านี้จนส่งสำเร็จ
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
                                  point: widget.pickup,
                                  radius: 20,
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
                                  point: widget.pickup,
                                  width: 48,
                                  height: 48,
                                  child: const Icon(
                                    Icons.store_mall_directory_rounded,
                                    color: Colors.blue,
                                    size: 34,
                                  ),
                                ),
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
                            // เส้นทาง
                            PolylineLayer<Object>(
                              polylines: _routeLine.isEmpty
                                  ? const <Polyline<Object>>[]
                                  : <Polyline<Object>>[
                                      Polyline<Object>(
                                        points: _routeLine,
                                        strokeWidth: 6,
                                        color: Colors.indigo.withOpacity(0.7),
                                      ),
                                    ],
                            ),
                          ],
                        ),

                        // distance & ETA box
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

                        // ปุ่มสลับเป้าหมาย/รีเฟรชเส้นทาง (สลับได้หลังรับแล้ว)
                        Positioned(
                          right: 12,
                          top: 74,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (!_pickedUp) {
                                    return; // ยังไม่รับ → นำทางไปจุดรับอย่างเดียว
                                  }
                                  setState(() => _navToDrop = !_navToDrop);
                                  _updateRoute();
                                },
                                icon: const Icon(Icons.swap_horiz_rounded),
                                label: Text(
                                  _navToDrop
                                      ? 'นำทางไปจุดส่ง'
                                      : 'นำทางไปจุดรับ',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: _updateRoute,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('รีเฟรชเส้นทาง'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // previews
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 72 + 12 + 8, // เหนือปุ่มหลักนิดนึง
                          child: Row(
                            children: [
                              Expanded(
                                child: _PreviewBox(
                                  file: _pickupPhotoFile,
                                  placeholder: 'ยังไม่มีรูปตอนรับ',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _PreviewBox(
                                  file: _deliverPhotoFile,
                                  placeholder: 'ยังไม่มีรูปตอนส่ง',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // single action button (ถ่ายรูป & รับ / ถ่ายรูป & ส่ง)
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
                                btnText,
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

class _PreviewBox extends StatelessWidget {
  final File? file;
  final String? placeholder;
  const _PreviewBox({this.file, this.placeholder});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: file != null
          ? Image.file(file!, fit: BoxFit.cover, width: double.infinity)
          : Text(
              placeholder ?? 'No photo',
              style: GoogleFonts.notoSansThai(
                color: Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}
