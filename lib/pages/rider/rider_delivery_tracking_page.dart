import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';

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

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.blur = 18,
    this.backgroundOpacity = 0.22,
    this.tintOpacityTop = 0.28,
    this.tintOpacityBottom = 0.12,
    this.strokeOpacity = 0.38,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double blur;
  final double backgroundOpacity;
  final double tintOpacityTop;
  final double tintOpacityBottom;
  final double strokeOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(borderRadius: borderRadius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: tintOpacityTop),
                  Colors.white.withValues(alpha: tintOpacityBottom),
                ],
              ),
              color: Colors.white.withValues(alpha: backgroundOpacity),
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: strokeOpacity),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
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

class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onTap,
    required this.text,
    this.icon,
    this.enabled = true,
    this.primary = false,
    this.busy = false,
    this.primaryColor,
  });

  final VoidCallback? onTap;
  final String text;
  final IconData? icon;
  final bool enabled;
  final bool primary;
  final bool busy;
  final Color? primaryColor;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _pressed = false;

  Color get _accent =>
      widget.primaryColor ??
      (widget.primary ? const Color(0xFF007AFF) : Colors.black87);

  @override
  Widget build(BuildContext context) {
    final bool disabled = !widget.enabled || widget.busy;
    final Color edge = disabled
        ? Colors.black.withValues(alpha: 0.15)
        : _accent.withValues(alpha: 0.50);

    final Color textColor = disabled
        ? Colors.black.withValues(alpha: 0.35)
        : (widget.primary ? Colors.white : Colors.black.withValues(alpha: 0.9));

    final Color iconColor = disabled
        ? Colors.black.withValues(alpha: 0.35)
        : (widget.primary ? Colors.white : Colors.black.withValues(alpha: 0.9));

    final List<Color> bg = disabled
        ? [
            Colors.white.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.08),
          ]
        : widget.primary
        ? [_accent.withValues(alpha: 0.55), _accent.withValues(alpha: 0.32)]
        : [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.16),
          ];

    final shadow = disabled
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: _accent.withValues(alpha: 0.35),
              blurRadius: 18,
              spreadRadius: 1.5,
              offset: const Offset(0, 8),
            ),
          ];

    final scale = _pressed ? 0.98 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bg,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: edge, width: 1.2),
              boxShadow: shadow,
            ),
            child: InkWell(
              onTap: (widget.enabled && !widget.busy) ? widget.onTap : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              splashColor: _accent.withValues(alpha: disabled ? 0.0 : 0.18),
              highlightColor: Colors.white.withValues(
                alpha: disabled ? 0.0 : 0.10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.busy)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: iconColor),
                  ],
                  if (!widget.busy && widget.icon != null)
                    const SizedBox(width: 8),
                  Text(
                    widget.text,
                    style: GoogleFonts.notoSansThai(
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double appBarTotalHeight(BuildContext context, {PreferredSizeWidget? appBar}) {
  final topInset = MediaQuery.of(context).padding.top;
  final toolbar = appBar?.preferredSize.height ?? kToolbarHeight;
  return topInset + toolbar;
}

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

  final ValueNotifier<LatLng?> _meVN = ValueNotifier<LatLng?>(null);
  final ValueNotifier<double?> _speedVN = ValueNotifier<double?>(null);
  final ValueNotifier<double?> _distPickupVN = ValueNotifier<double?>(null);
  final ValueNotifier<double?> _distDropVN = ValueNotifier<double?>(null);

  bool _loading = true;
  String? _error;
  StreamSubscription<Position>? _posSub;

  static const double kGateMeters = 20.0;
  bool _pickedUp = false;
  bool _actionBusy = false;

  bool get _canPickup =>
      _meVN.value != null &&
      _distPickupVN.value != null &&
      _distPickupVN.value! <= kGateMeters;
  bool get _canDeliver =>
      _pickedUp &&
      _meVN.value != null &&
      _distDropVN.value != null &&
      _distDropVN.value! <= kGateMeters;

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

  bool _sending = false;
  DateTime? _lastSendTryAt;
  final Duration _minSendGap = const Duration(milliseconds: 600);

  double? _speedMpsDisplay;
  final double _speedSmoothAlpha = 0.35;

  DateTime? _lastRouteAt;
  final Duration _routeMinGap = const Duration(seconds: 1);

  bool _followMe = true;

  String? _shipmentTitle;
  String? _senderName;
  String? _senderPhone;
  String? _receiverName;
  String? _receiverPhone;
  String? _senderAvatarUrl;
  String? _receiverAvatarUrl;

  LatLng? _lastSent;
  DateTime? _lastSentAt;
  LatLng? _lastRecenterPos;

  DateTime? _lastUiTick;
  final Duration _minUiTick = const Duration(milliseconds: 250);

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
    _posSub?.cancel();
    _meVN.dispose();
    _speedVN.dispose();
    _distPickupVN.dispose();
    _distDropVN.dispose();
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

        _shipmentTitle = (data?['title'] ?? '').toString();

        String toAbs(String? p) {
          if (p == null || p.isEmpty) return '';
          if (p.startsWith('http://') || p.startsWith('https://')) return p;
          final base = widget.baseUrl.endsWith('/')
              ? widget.baseUrl.substring(0, widget.baseUrl.length - 1)
              : widget.baseUrl;
          return '$base$p';
        }

        final s = data?['sender'] as Map<String, dynamic>?;
        _senderName = (s?['name'] ?? '').toString();
        _senderPhone = (s?['phone'] ?? '').toString();
        _senderAvatarUrl = toAbs((s?['avatar_path'] as String?)?.trim());

        final r = data?['receiver'] as Map<String, dynamic>?;
        _receiverName = (r?['name'] ?? '').toString();
        _receiverPhone = (r?['phone'] ?? '').toString();
        _receiverAvatarUrl = toAbs((r?['avatar_path'] as String?)?.trim());

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

        _pickupPhotoUrl = toAbs(
          (data?['pickup_photo_path'] as String?)?.trim(),
        );
        _deliverPhotoUrl = toAbs(
          (data?['deliver_photo_path'] as String?)?.trim(),
        );

        final status = (data?['status'] ?? '').toString();
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
        final err = jsonDecode(utf8.decode(resp.bodyBytes));
        final msg =
            err is Map &&
                err['error'] is Map &&
                err['error']['message'] is String
            ? err['error']['message'] as String
            : 'โหลดงานไม่สำเร็จ (HTTP ${resp.statusCode})';
        Get.snackbar('ผิดพลาด', msg, snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {}
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

      final LocationSettings common = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      LocationSettings effective = common;
      if (Platform.isAndroid) {
        effective = AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          intervalDuration: const Duration(milliseconds: 300),
          forceLocationManager: false,
        );
      } else if (Platform.isIOS) {
        effective = AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          activityType: ActivityType.automotiveNavigation,
          pauseLocationUpdatesAutomatically: true,
          showBackgroundLocationIndicator: false,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: effective,
      );

      _onPosition(LatLng(pos.latitude, pos.longitude), raw: pos);

      _posSub = Geolocator.getPositionStream(
        locationSettings: effective,
      ).listen((p) => _onPosition(LatLng(p.latitude, p.longitude), raw: p));
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
    _meVN.value = latlng;
    _loading = false;

    _distPickupVN.value = _distanceMeters(latlng, _pickup);
    _distDropVN.value = _distanceMeters(latlng, _dropoff);

    double? h = raw?.heading;
    if (h == null || h.isNaN || h < 0) {
      if (_lastSent != null) {
        h = _bearingDegrees(_lastSent!, latlng);
      }
    }
    _lastHeadingDegFromSensor = h;

    double? s = raw?.speed;
    if (s == null || s.isNaN || s < 0) {
      if (_lastSent != null && _lastSentAt != null) {
        final dt =
            DateTime.now().difference(_lastSentAt!).inMilliseconds / 1000.0;
        if (dt > 0) s = _distanceMeters(_lastSent!, latlng) / dt;
      }
    }
    if (s != null && !s.isNaN) {
      _speedMpsDisplay = (_speedMpsDisplay == null)
          ? s
          : _speedSmoothAlpha * s + (1 - _speedSmoothAlpha) * _speedMpsDisplay!;
      _speedVN.value = _speedMpsDisplay;
    }

    if (_mapReady) {
      _maybeRecenter(latlng);
    } else {
      _pendingCenter = latlng;
      _pendingZoom = 16;
    }

    final now = DateTime.now();
    if (_lastUiTick == null || now.difference(_lastUiTick!) >= _minUiTick) {
      _lastUiTick = now;
      if (mounted) setState(() {});
    }

    _trySendLocationThrottled();
    _tryUpdateRouteDebounced();
  }

  void _maybeRecenter(LatLng newPos) {
    if (!_followMe) return;
    final last = _lastRecenterPos;
    if (last == null || _distanceMeters(last, newPos) > 8) {
      _map.move(newPos, 16);
      _lastRecenterPos = newPos;
    }
  }

  double _bearingDegrees(LatLng a, LatLng b) {
    final lat1 = a.latitude * (pi / 180.0);
    final lat2 = b.latitude * (pi / 180.0);
    final dLon = (b.longitude - a.longitude) * (pi / 180.0);
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final brng = atan2(y, x) * 180.0 / pi;
    return (brng + 360.0) % 360.0;
  }

  void _trySendLocationThrottled() {
    final now = DateTime.now();
    if (_sending) return;
    if (_lastSendTryAt != null &&
        now.difference(_lastSendTryAt!) < _minSendGap) {
      return;
    }
    _lastSendTryAt = now;
    _sendLocation();
  }

  void _tryUpdateRouteDebounced() {
    final now = DateTime.now();
    if (_lastRouteAt != null && now.difference(_lastRouteAt!) < _routeMinGap) {
      return;
    }
    _lastRouteAt = now;
    _updateRoute();
  }

  Future<void> _sendLocation() async {
    final me = _meVN.value;
    if (me == null) return;
    if (_sending) return;
    _sending = true;

    try {
      double? headingDeg = _lastHeadingDegFromSensor;
      double? speedMps = _lastSpeedMpsFromSensor;

      final now = DateTime.now();
      if ((headingDeg == null || headingDeg.isNaN || headingDeg < 0) &&
          _lastSent != null) {
        headingDeg = _bearingDegrees(_lastSent!, me);
      }
      if ((speedMps == null || speedMps.isNaN || speedMps <= 0) &&
          _lastSent != null &&
          _lastSentAt != null) {
        final dt = now.difference(_lastSentAt!).inMilliseconds / 1000.0;
        if (dt > 0) {
          final d = _distanceMeters(_lastSent!, me);
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
        'lat': round(me.latitude, 7),
        'lng': round(me.longitude, 7),
        'shipment_id': widget.shipmentId,
        if (headingDeg != null)
          'heading_deg': round((headingDeg + 360) % 360, 2),
        if (speedMps != null) 'speed_mps': round(speedMps, 2),
      };

      final resp = await http
          .post(uri, headers: await authHeaders(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 8));

      handleAuthErrorIfAny(resp);

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        _lastSent = me;
        _lastSentAt = now;
        _lastSpeedMpsFromSensor = speedMps;
      } else {
        debugPrint('ส่ง location ไม่สำเร็จ: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดขณะอัปเดต location: $e');
    } finally {
      _sending = false;
    }
  }

  Future<void> _updateRoute() async {
    final me = _meVN.value;
    if (me == null) return;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${me.longitude},${me.latitude};${_target.longitude},${_target.latitude}'
      '?overview=simplified&geometries=geojson',
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

          if (mounted) {
            setState(() {
              _routeLine = coords;
              _routeDistanceMeters = (r['distance'] as num?)?.toDouble();
              final sec = (r['duration'] as num?)?.toDouble() ?? 0;
              _etaText = _fmtEta(sec);
            });
          }
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

  String _speedNumber(double? mps) {
    final kmh = (mps ?? 0) * 3.6;
    return kmh < 10 ? kmh.toStringAsFixed(1) : kmh.toStringAsFixed(0);
  }

  void _toggleFollow() {
    setState(() => _followMe = !_followMe);
    if (_followMe && _mapReady && _meVN.value != null) {
      _map.move(_meVN.value!, 16);
      _lastRecenterPos = _meVN.value!;
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) {
          await showGlassAlert(
            title: 'ไม่สามารถออกได้',
            message: 'กรุณาทำรายการให้เสร็จก่อนออกจากหน้านี้',
            okText: 'ตกลง',
          );
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
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
                            initialCenter: _meVN.value ?? _pickup,
                            initialZoom: 16,
                            interactionOptions: InteractionOptions(
                              flags: _followMe
                                  ? InteractiveFlag.none
                                  : (InteractiveFlag.all &
                                        ~InteractiveFlag.rotate),
                            ),
                            onMapReady: () {
                              _mapReady = true;
                              if (_pendingCenter != null) {
                                _map.move(_pendingCenter!, _pendingZoom);
                                _lastRecenterPos = _pendingCenter;
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=0b03b55da9a64adab5790c1c9515b15a',
                              userAgentPackageName: 'net.gonggang.osm_demo',
                            ),

                            PolylineLayer(
                              polylines: _routeLine.isEmpty
                                  ? const <Polyline>[]
                                  : <Polyline>[
                                      Polyline(
                                        points: _routeLine,
                                        strokeWidth: 7,
                                        color: _pickedUp
                                            ? Colors.greenAccent.withValues(
                                                alpha: 0.8,
                                              )
                                            : Colors.blueAccent.withValues(
                                                alpha: 0.8,
                                              ),
                                        borderStrokeWidth: 2.5,
                                        borderColor: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ],
                            ),

                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _pickup,
                                  radius: 20,
                                  useRadiusInMeter: true,
                                  color: Colors.blue.withValues(alpha: 0.18),
                                  borderStrokeWidth: 1.5,
                                  borderColor: Colors.blueAccent,
                                ),
                                CircleMarker(
                                  point: _dropoff,
                                  radius: 20,
                                  useRadiusInMeter: true,
                                  color: Colors.green.withValues(alpha: 0.18),
                                  borderStrokeWidth: 1.5,
                                  borderColor: Colors.green,
                                ),
                              ],
                            ),

                            MarkerLayer(
                              markers: [
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

                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _meVN.value ?? _pickup,
                                  width: 52,
                                  height: 52,
                                  child: ValueListenableBuilder<LatLng?>(
                                    valueListenable: _meVN,
                                    builder: (_, me, __) {
                                      final angle =
                                          ((_lastHeadingDegFromSensor ?? 0) %
                                              360) *
                                          pi /
                                          180.0;
                                      return Transform.rotate(
                                        angle: angle,
                                        child: const Icon(
                                          Icons.navigation_rounded,
                                          color: Colors.red,
                                          size: 38,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Positioned(
                          left: 12,
                          right: 12,
                          top: appBarTotalHeight(context) + 12,
                          child: RepaintBoundary(
                            child: Column(
                              children: [
                                GlassCard(
                                  child: DefaultTextStyle(
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child:
                                                  ValueListenableBuilder<
                                                    double?
                                                  >(
                                                    valueListenable:
                                                        _distPickupVN,
                                                    builder: (_, v, _) => Text(
                                                      'ไปจุดรับ: ${_mLabel(v)}',
                                                    ),
                                                  ),
                                            ),
                                            Expanded(
                                              child:
                                                  ValueListenableBuilder<
                                                    double?
                                                  >(
                                                    valueListenable:
                                                        _distDropVN,
                                                    builder: (_, v, _) => Text(
                                                      'ไปจุดส่ง: ${_mLabel(v)}',
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
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
                                const SizedBox(height: 10),
                                GlassCard(
                                  child: _JobMiniCard(
                                    title: _shipmentTitle ?? 'งานจัดส่ง',
                                    senderName: _senderName ?? '—',
                                    senderPhone: _senderPhone ?? '—',
                                    receiverName: _receiverName ?? '—',
                                    receiverPhone: _receiverPhone ?? '—',
                                    senderAvatarUrl: _senderAvatarUrl,
                                    receiverAvatarUrl: _receiverAvatarUrl,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      const Spacer(),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 16,
                                            sigmaY: 16,
                                          ),
                                          child: Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.5,
                                                ),
                                                width: 1.5,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: ValueListenableBuilder<double?>(
                                              valueListenable: _speedVN,
                                              builder: (_, v, _) => Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _speedNumber(v),
                                                    style:
                                                        GoogleFonts.notoSansThai(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                  ),
                                                  Text(
                                                    'km/h',
                                                    style:
                                                        GoogleFonts.notoSansThai(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Colors.black54,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const Spacer(),
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.15,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.my_location_rounded,
                                            color: _followMe
                                                ? Colors.blueAccent
                                                : Colors.black54,
                                          ),
                                          onPressed: _toggleFollow,
                                          tooltip: 'ติดตามตำแหน่ง',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
                                child: GlassCard(
                                  padding: EdgeInsets.zero,
                                  child: _PreviewBox(
                                    file: _pickupPhotoFile,
                                    url: _pickupPhotoUrl,
                                    placeholder: _pickedUp
                                        ? 'รับแล้ว'
                                        : 'ยังไม่มีรูปตอนรับ',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GlassCard(
                                  padding: EdgeInsets.zero,
                                  child: _PreviewBox(
                                    file: _deliverPhotoFile,
                                    url: _deliverPhotoUrl,
                                    placeholder: _pickedUp
                                        ? 'ยังไม่มีรูปตอนส่ง'
                                        : 'รอรับก่อนถึงถ่ายตอนส่งได้',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 36,
                          child: Tooltip(
                            message: hintText ?? '',
                            child: GlassButton(
                              primary: true,
                              primaryColor: isPickupPhase
                                  ? const Color(0xFF007AFF)
                                  : const Color(0xFF34C759),
                              enabled: canDoNow && !_actionBusy,
                              busy: _actionBusy,
                              onTap: _onAction,
                              icon: Icons.camera_alt_outlined,
                              text: isPickupPhase
                                  ? 'ถ่ายรูป & รับพัสดุ'
                                  : 'ถ่ายรูป & ส่งสำเร็จ',
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
    if (widget.file != null) {
      return Container(
        height: 86,
        decoration: const BoxDecoration(),
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
      return _placeholderBox(widget.placeholder ?? 'No photo');
    }

    final withBuster = _appendCacheBuster(rawUrl, _retry);
    final uri = Uri.tryParse(withBuster);

    if (uri == null || (!uri.hasScheme && !withBuster.startsWith('/'))) {
      return _placeholderBox(widget.placeholder ?? 'No photo');
    }

    return Container(
      height: 86,
      decoration: const BoxDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        withBuster,
        fit: BoxFit.cover,
        width: double.infinity,
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

  Widget _placeholderBox(String text) {
    return Container(
      height: 86,
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

  Widget _errorBox({required VoidCallback onRetry}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image_outlined, color: Colors.black54),
              const SizedBox(width: 6),
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

Future<void> showGlassAlert({
  required String title,
  required String message,
  String okText = 'ตกลง',
  VoidCallback? onOk,
  bool barrierDismissible = false,
}) {
  return Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.38),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: Colors.black.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: _GlassButton(
                    text: okText,
                    onTap: () {
                      if (onOk != null) onOk();
                      Get.back();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    barrierColor: Colors.black.withValues(alpha: 0.20),
    barrierDismissible: barrierDismissible,
  );
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.35),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  text,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobMiniCard extends StatelessWidget {
  const _JobMiniCard({
    required this.title,
    required this.senderName,
    required this.senderPhone,
    required this.receiverName,
    required this.receiverPhone,
    this.senderAvatarUrl,
    this.receiverAvatarUrl,
  });

  final String title;
  final String senderName;
  final String senderPhone;
  final String receiverName;
  final String receiverPhone;
  final String? senderAvatarUrl;
  final String? receiverAvatarUrl;

  bool _isHttp(String? s) =>
      s != null &&
      (s.startsWith('http://') ||
          s.startsWith('https://') ||
          s.startsWith('/'));

  Widget _avatar(String? url, {IconData fallback = Icons.person}) {
    if (_isHttp(url) && (url ?? '').trim().isNotEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, _) {},
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.grey.shade300,
      child: Icon(fallback, size: 16, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.notoSansThai(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: Colors.black.withValues(alpha: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.isEmpty ? 'งานจัดส่ง' : 'ชื่องาน: $title',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSansThai(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _avatar(
                senderAvatarUrl,
                fallback: Icons.person_pin_circle_rounded,
              ),
              const SizedBox(width: 8),
              const Text('ผู้ส่ง: '),
              Expanded(
                child: Text(senderName, overflow: TextOverflow.ellipsis),
              ),
              _CopyChip(text: senderPhone),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _avatar(receiverAvatarUrl, fallback: Icons.place_rounded),
              const SizedBox(width: 8),
              const Text('ผู้รับ: '),
              Expanded(
                child: Text(receiverName, overflow: TextOverflow.ellipsis),
              ),
              _CopyChip(text: receiverPhone),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyChip extends StatelessWidget {
  const _CopyChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final disabled = text.trim().isEmpty || text.trim() == '—';
    return InkWell(
      onTap: disabled
          ? null
          : () async {
              final messenger = ScaffoldMessenger.maybeOf(context);
              await Clipboard.setData(ClipboardData(text: text));
              messenger?.showSnackBar(
                SnackBar(
                  backgroundColor: Colors.black.withValues(alpha: 0.65),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  content: const Text('คัดลอกเบอร์แล้ว'),
                  duration: const Duration(milliseconds: 900),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: disabled ? Colors.grey.shade200 : Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy_rounded,
              size: 14,
              color: disabled ? Colors.black54 : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              (text.isEmpty ? '—' : text),
              style: GoogleFonts.notoSansThai(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: disabled ? Colors.black54 : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
