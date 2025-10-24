import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/profile_page.dart';
import 'package:songduan_app/pages/rider/rider_delivery_tracking_page.dart';
import 'package:songduan_app/pages/rider/rider_job_map_preview_page.dart';
import 'package:songduan_app/services/api_helper.dart';
import 'package:songduan_app/services/session_service.dart';
import 'package:songduan_app/widgets/order_card.dart';
import 'package:songduan_app/widgets/order_detail_card.dart';
import 'package:songduan_app/widgets/profile_header.dart';
import 'package:songduan_app/widgets/section_title.dart';

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  String? _baseUrl;
  String? _cfgError;
  bool _loadingCfg = true;

  late Map<String, dynamic> _user = {};
  late final String _name;
  late final String _roleLabel;

  final RxInt _acceptingId = 0.obs;

  Timer? _autoTimer;
  static const _autoRefreshSec = 10;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadSessionInfo();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  void _loadSessionInfo() {
    final session = Get.find<SessionService>();

    _user = {
      'id': session.currentUserId,
      'role': session.role,
      'name': session.name,
      'username': session.username,
      'phone': session.phone,
      'avatar_path': session.avatarPath,
    };
    _name = session.name ?? 'ผู้ใช้';
    final role = (session.role ?? '').toUpperCase();
    _roleLabel = switch (role) {
      'RIDER' => 'Rider',
      'MEMBER' => 'Member',
      _ => 'User',
    };

    _fetchShipments();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() {
        _baseUrl = config['apiEndpoint'] as String?;
        _loadingCfg = false;
      });
      _refreshAll();
      _startAutoRefresh();
    } catch (e) {
      setState(() {
        _cfgError = '$e';
        _loadingCfg = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _checkActiveJob();
    await _fetchShipments();
  }

  Future<void> _checkActiveJob() async {
    if (_baseUrl == null || _baseUrl!.isEmpty) return;

    final riderId = Get.find<SessionService>().currentUserId;
    if (riderId == null) return;

    try {
      final uri = Uri.parse('$_baseUrl/riders/$riderId/active-assignment');
      final resp = await http
          .get(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 10));
      handleAuthErrorIfAny(resp);

      if (resp.statusCode != 200) {
        return;
      }

      final body =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      final rawSid = body['data']?['shipment_id'];
      final sid = rawSid is int
          ? rawSid
          : int.tryParse(rawSid?.toString() ?? '');
      if (sid == null) return;

      final dUri = Uri.parse('$_baseUrl/shipments/$sid');
      final dResp = await http
          .get(dUri, headers: await authHeaders())
          .timeout(const Duration(seconds: 10));
      handleAuthErrorIfAny(dResp);
      if (dResp.statusCode != 200) return;

      final detail =
          jsonDecode(utf8.decode(dResp.bodyBytes)) as Map<String, dynamic>;
      final data = detail['data'] as Map<String, dynamic>;

      final pickupLat = (data['pickup']?['lat'] as num).toDouble();
      final pickupLng = (data['pickup']?['lng'] as num).toDouble();
      final dropLat = (data['dropoff']?['lat'] as num).toDouble();
      final dropLng = (data['dropoff']?['lng'] as num).toDouble();

      final pickup = LatLng(pickupLat, pickupLng);
      final dropoff = LatLng(dropLat, dropLng);

      final ok = await Get.to<bool>(
        () => RiderDeliveryTrackingPage(
          baseUrl: _baseUrl!,
          shipmentId: sid,
          pickup: pickup,
          dropoff: dropoff,
          pickupLabel: (data['pickup']?['label'] ?? '').toString(),
          dropoffLabel: (data['dropoff']?['label'] ?? '').toString(),
        ),
      );
      if (ok == true) await _fetchShipments();
    } catch (_) {}
  }

  Future<void> _fetchShipments() async {
    if (_baseUrl == null || _baseUrl!.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/shipments').replace(
        queryParameters: {
          'status': 'WAITING_FOR_RIDER',
          'available': '1',
          'pageSize': '50',
        },
      );

      final resp = await http
          .get(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 15));
      handleAuthErrorIfAny(resp);

      final body = jsonDecode(utf8.decode(resp.bodyBytes));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List list = (body is Map && body['data'] is List)
            ? (body['data'] as List)
            : (body is List ? body : const []);

        final onlyWaiting = list.where((x) {
          final s = (x is Map && x['status'] is String)
              ? (x['status'] as String).toUpperCase()
              : '';
          return s == 'WAITING_FOR_RIDER';
        }).toList();

        final mapped = onlyWaiting.map<Map<String, dynamic>>((x) {
          final pickup =
              (x['pickup'] ?? x['pickup_address'] ?? {}) as Map? ?? {};
          final dropoff =
              (x['dropoff'] ?? x['dropoff_address'] ?? {}) as Map? ?? {};

          final cover =
              (x['cover_file_path'] ?? x['file_path'] ?? '') as String;
          final imagePath = cover.trim().isEmpty
              ? null
              : (cover.startsWith('http')
                    ? cover
                    : _joinBase(_baseUrl!, cover));

          final rawSenderAvatar = (x['sender']?['avatar_path'] ?? '') as String;
          final senderAvatar = rawSenderAvatar.trim().isEmpty
              ? null
              : (rawSenderAvatar.startsWith('http')
                    ? rawSenderAvatar
                    : _joinBase(_baseUrl!, rawSenderAvatar));

          final rawReceiverAvatar =
              (x['receiver']?['avatar_path'] ?? '') as String;
          final receiverAvatar = rawReceiverAvatar.trim().isEmpty
              ? null
              : (rawReceiverAvatar.startsWith('http')
                    ? rawReceiverAvatar
                    : _joinBase(_baseUrl!, rawReceiverAvatar));

          return {
            'id': x['id'],
            'title': (x['title'] ?? 'Order').toString(),
            'status': (x['status'] ?? '').toString(),
            'from': (pickup['label'] ?? pickup['address_text'] ?? '—')
                .toString(),
            'to': (dropoff['label'] ?? dropoff['address_text'] ?? '—')
                .toString(),
            'distance': "-",
            'image': imagePath,
            'sender_avatar': senderAvatar,
            'receiver_avatar': receiverAvatar,
            '_raw': x,
            '_pickup': pickup,
            '_dropoff': dropoff,
          };
        }).toList();

        setState(() => _items = mapped);
      } else {
        final msg =
            (body is Map &&
                body['error'] is Map &&
                body['error']['message'] is String)
            ? body['error']['message'] as String
            : 'HTTP ${resp.statusCode}';
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = 'โหลดข้อมูลไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchShipmentsSoft() async {
    if (_baseUrl == null || _baseUrl!.isEmpty) return;

    try {
      final uri = Uri.parse('$_baseUrl/shipments').replace(
        queryParameters: {
          'status': 'WAITING_FOR_RIDER',
          'available': '1',
          'pageSize': '50',
        },
      );

      final resp = await http
          .get(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 15));
      handleAuthErrorIfAny(resp);

      final body = jsonDecode(utf8.decode(resp.bodyBytes));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List list = (body is Map && body['data'] is List)
            ? (body['data'] as List)
            : (body is List ? body : const []);

        final onlyWaiting = list.where((x) {
          final s = (x is Map && x['status'] is String)
              ? (x['status'] as String).toUpperCase()
              : '';
          return s == 'WAITING_FOR_RIDER';
        }).toList();

        final mapped = onlyWaiting.map<Map<String, dynamic>>((x) {
          final pickup =
              (x['pickup'] ?? x['pickup_address'] ?? {}) as Map? ?? {};
          final dropoff =
              (x['dropoff'] ?? x['dropoff_address'] ?? {}) as Map? ?? {};

          final cover =
              (x['cover_file_path'] ?? x['file_path'] ?? '') as String;
          final imagePath = cover.trim().isEmpty
              ? null
              : (cover.startsWith('http')
                    ? cover
                    : _joinBase(_baseUrl!, cover));

          final rawSenderAvatar = (x['sender']?['avatar_path'] ?? '') as String;
          final senderAvatar = rawSenderAvatar.trim().isEmpty
              ? null
              : (rawSenderAvatar.startsWith('http')
                    ? rawSenderAvatar
                    : _joinBase(_baseUrl!, rawSenderAvatar));

          final rawReceiverAvatar =
              (x['receiver']?['avatar_path'] ?? '') as String;
          final receiverAvatar = rawReceiverAvatar.trim().isEmpty
              ? null
              : (rawReceiverAvatar.startsWith('http')
                    ? rawReceiverAvatar
                    : _joinBase(_baseUrl!, rawReceiverAvatar));

          return {
            'id': x['id'],
            'title': (x['title'] ?? 'Order').toString(),
            'status': (x['status'] ?? '').toString(),
            'from': (pickup['label'] ?? pickup['address_text'] ?? '—')
                .toString(),
            'to': (dropoff['label'] ?? dropoff['address_text'] ?? '—')
                .toString(),
            'distance': "-",
            'image': imagePath,
            'sender_avatar': senderAvatar,
            'receiver_avatar': receiverAvatar,
            '_raw': x,
            '_pickup': pickup,
            '_dropoff': dropoff,
          };
        }).toList();

        if (!mounted) return;
        setState(() => _items = mapped);
      }
    } catch (_) {}
  }

  void _startAutoRefresh() {
    _autoTimer?.cancel();
    if (_baseUrl == null || _baseUrl!.isEmpty) return;

    _autoTimer = Timer.periodic(Duration(seconds: _autoRefreshSec), (_) async {
      final wasEmpty = _items.isEmpty;
      await _fetchShipmentsSoft();
      if (!mounted) return;

      if (wasEmpty && _items.isNotEmpty) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'มีงานใหม่พร้อมรับแล้ว!',
                style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w700),
              ),
              backgroundColor: const Color(0xFFFF7A00),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    });
  }

  Future<void> _acceptShipment(int shipmentId) async {
    if (_baseUrl == null || _baseUrl!.isEmpty) return;

    final riderId = Get.find<SessionService>().currentUserId;
    if (riderId == null) {
      Get.snackbar(
        'ยังไม่พร้อม',
        'ไม่พบ session ของผู้ขับ',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final uri = Uri.parse('$_baseUrl/shipments/$shipmentId/accept');
    final resp = await http
        .post(
          uri,
          headers: await authHeaders(),
          body: jsonEncode({'rider_id': riderId}),
        )
        .timeout(const Duration(seconds: 15));
    handleAuthErrorIfAny(resp);
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      final b = _safeJson(resp);
      Get.snackbar(
        'รับงานไม่สำเร็จ',
        (b['error']?['message'] ?? 'HTTP ${resp.statusCode}').toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final dUri = Uri.parse('$_baseUrl/shipments/$shipmentId');
    final dResp = await http.get(dUri, headers: await authHeaders());
    handleAuthErrorIfAny(dResp);
    if (dResp.statusCode != 200) {
      Get.snackbar(
        'โหลดรายละเอียดไม่สำเร็จ',
        'HTTP ${dResp.statusCode}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final detail =
        jsonDecode(utf8.decode(dResp.bodyBytes)) as Map<String, dynamic>;
    final data = detail['data'] as Map<String, dynamic>;

    final pickup = LatLng(
      (data['pickup']['lat'] as num).toDouble(),
      (data['pickup']['lng'] as num).toDouble(),
    );
    final dropoff = LatLng(
      (data['dropoff']['lat'] as num).toDouble(),
      (data['dropoff']['lng'] as num).toDouble(),
    );

    Get.back();
    final ok = await Get.to<bool>(
      () => RiderDeliveryTrackingPage(
        baseUrl: _baseUrl!,
        shipmentId: shipmentId,
        pickup: pickup,
        dropoff: dropoff,
        pickupLabel: (data['pickup']['label'] ?? '').toString(),
        dropoffLabel: (data['dropoff']['label'] ?? '').toString(),
      ),
    );

    if (ok == true) {
      await _fetchShipments();
    }
  }

  Map<String, dynamic> _safeJson(http.Response r) {
    try {
      return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _joinBase(String base, String rel) {
    final b = base.replaceFirst(RegExp(r'\/+$'), '');
    final r = rel.startsWith('/') ? rel : '/$rel';
    return '$b$r';
  }

  OrderStatus _mapStatus(String s) {
    switch (s.toUpperCase()) {
      case 'WAITING_FOR_RIDER':
        return OrderStatus.waitingPickup;
      case 'RIDER_ACCEPTED':
        return OrderStatus.riderAccepted;
      case 'PICKED_UP_EN_ROUTE':
        return OrderStatus.delivering;
      case 'DELIVERED':
        return OrderStatus.delivered;
      default:
        return OrderStatus.waitingPickup;
    }
  }

  LatLng? _safeLatLng(Map<dynamic, dynamic> m) {
    final lat = m['lat'] ?? m['latitude'];
    final lng = m['lng'] ?? m['longitude'];
    if (lat is num && lng is num) {
      return LatLng(lat.toDouble(), lng.toDouble());
    }
    if (lat is String && lng is String) {
      final la = double.tryParse(lat);
      final lo = double.tryParse(lng);
      if (la != null && lo != null) return LatLng(la, lo);
    }
    return null;
  }

  void _openDetail(Map<String, dynamic> m) {
    final raw = m['_raw'] as Map<String, dynamic>? ?? {};
    final pickup = m['_pickup'] as Map<String, dynamic>? ?? const {};
    final dropoff = m['_dropoff'] as Map<String, dynamic>? ?? const {};

    final shipmentId = m['id'] as int?;
    if (shipmentId == null) return;

    final senderAvatar =
        (raw['sender']?['avatar_path'] is String &&
            (raw['sender']!['avatar_path'] as String).trim().isNotEmpty)
        ? _joinBase(_baseUrl!, raw['sender']!['avatar_path'] as String)
        : 'https://via.placeholder.com/80x80.png?text=Sender';

    final receiverAvatar =
        (raw['receiver']?['avatar_path'] is String &&
            (raw['receiver']!['avatar_path'] as String).trim().isNotEmpty)
        ? _joinBase(_baseUrl!, raw['receiver']!['avatar_path'] as String)
        : 'https://via.placeholder.com/80x80.png?text=Receiver';

    final status = _mapStatus((m['status'] ?? '').toString());

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              children: [
                OrderDetailCard(
                  productName: (m['title'] ?? 'Order').toString(),
                  imagePath: m['image'] as String?,
                  status: status,
                  sender: PersonInfo(
                    avatar: senderAvatar,
                    role: 'ผู้ส่ง',
                    name: (raw['sender']?['name'] ?? '—').toString(),
                    phone: (raw['sender']?['phone'] ?? '—').toString(),
                    address: (pickup['address_text'] ?? pickup['label'] ?? '—')
                        .toString(),
                    placeName: (pickup['label'] ?? '—').toString(),
                  ),
                  receiver: PersonInfo(
                    avatar: receiverAvatar,
                    role: 'ผู้รับ',
                    name: (raw['receiver']?['name'] ?? '—').toString(),
                    phone: (raw['receiver']?['phone'] ?? '—').toString(),
                    address:
                        (dropoff['address_text'] ?? dropoff['label'] ?? '—')
                            .toString(),
                    placeName: (dropoff['label'] ?? '—').toString(),
                  ),
                  showStatus: false,
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () {
                      final LatLng? p = _safeLatLng(pickup);
                      final LatLng? d = _safeLatLng(dropoff);
                      if (p == null || d == null) {
                        Get.snackbar(
                          'พิกัดไม่สมบูรณ์',
                          'ไม่พบ lat/lng ของจุดรับหรือส่ง',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }

                      final senderName = (raw['sender']?['name'] ?? '')
                          .toString();
                      final senderPhone = (raw['sender']?['phone'] ?? '')
                          .toString();
                      final senderAddress =
                          (pickup['address_text'] ?? pickup['label'] ?? '')
                              .toString();

                      final receiverName = (raw['receiver']?['name'] ?? '')
                          .toString();
                      final receiverPhone = (raw['receiver']?['phone'] ?? '')
                          .toString();
                      final receiverAddress =
                          (dropoff['address_text'] ?? dropoff['label'] ?? '')
                              .toString();

                      Get.to(
                        () => RiderJobMapPreviewPage(
                          pickup: p,
                          dropoff: d,
                          pickupLabel:
                              (pickup['label'] ??
                                      pickup['address_text'] ??
                                      'จุดรับของ')
                                  .toString(),
                          dropoffLabel:
                              (dropoff['label'] ??
                                      dropoff['address_text'] ??
                                      'จุดส่งของ')
                                  .toString(),
                          senderName: senderName.isEmpty ? null : senderName,
                          senderPhone: senderPhone.isEmpty ? null : senderPhone,
                          senderAddress: senderAddress.isEmpty
                              ? null
                              : senderAddress,
                          senderAvatar: senderAvatar,
                          receiverName: receiverName.isEmpty
                              ? null
                              : receiverName,
                          receiverPhone: receiverPhone.isEmpty
                              ? null
                              : receiverPhone,
                          receiverAddress: receiverAddress.isEmpty
                              ? null
                              : receiverAddress,
                          receiverAvatar: receiverAvatar,
                        ),
                      );
                    },
                    icon: const Icon(Icons.map_rounded),
                    label: Text(
                      'ดูแผนที่',
                      style: GoogleFonts.notoSansThai(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                if (status == OrderStatus.waitingPickup)
                  Obx(() {
                    final isLoading = _acceptingId.value == shipmentId;
                    return ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      onPressed: isLoading
                          ? null
                          : () => _acceptShipment(shipmentId),
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.task_alt_rounded, size: 18),
                      label: Text(
                        isLoading ? 'กำลังรับงาน...' : 'ยืนยันรับงานนี้',
                        style: GoogleFonts.notoSansThai(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCfg) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_cfgError != null || _baseUrl == null || _baseUrl!.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'โหลดค่า config ไม่สำเร็จ: ${_cfgError ?? "apiEndpoint ว่าง"}',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: ProfileHeader(
                  name: _name,
                  role: _roleLabel,
                  image: _user['avatar_path']?.toString().isNotEmpty == true
                      ? _user['avatar_path'] as String
                      : 'assets/images/default_avatar.png',
                  baseUrl: _baseUrl,
                  onMorePressed: () =>
                      Get.to(() => const ProfilePage(), arguments: _user),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  color: const Color(0xFFF8F8F8),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    children: [
                      const SectionTitle('รายการส่งของที่สามารถรับได้ (ว่าง)'),
                      const SizedBox(height: 8),

                      if (_loading) ...[
                        const _LoadingCard(),
                        const SizedBox(height: 12),
                        const _LoadingCard(),
                        const SizedBox(height: 12),
                        const _LoadingCard(),
                      ] else if (_error != null) ...[
                        _ErrorTile(message: _error!, onRetry: _refreshAll),
                      ] else if (_items.isEmpty) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              'ยังไม่มีข้อมูลการจัดส่งที่ว่าง',
                              style: GoogleFonts.notoSansThai(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        ..._items.map((m) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Stack(
                              children: [
                                OrderCard(
                                  title: m['title'] as String,
                                  from: m['from'] as String,
                                  to: m['to'] as String,
                                  distanceText: m['distance'] as String,
                                  imagePath: m['image'] as String?,
                                  status: _mapStatus(
                                    (m['status'] ?? '').toString(),
                                  ),
                                  onDetail: () => _openDetail(m),
                                ),
                                if (m['sender_avatar'] != null)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundImage: NetworkImage(
                                          m['sender_avatar'] as String,
                                        ),
                                        backgroundColor: Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorTile({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.red)),
        ),
        TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
      ],
    ),
  );
}
