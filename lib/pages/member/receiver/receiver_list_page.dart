import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:songduan_app/services/api_helper.dart';

import 'package:songduan_app/services/session_service.dart';
import 'package:songduan_app/widgets/order_card.dart';
import 'package:songduan_app/widgets/order_detail_card.dart';
import 'package:songduan_app/widgets/section_title.dart';

class ReceiverListPage extends StatefulWidget {
  final String baseUrl;
  const ReceiverListPage({super.key, required this.baseUrl});

  @override
  State<ReceiverListPage> createState() => _ReceiverListPageState();
}

class _ReceiverListPageState extends State<ReceiverListPage> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _fetchShipments();
  }

  Future<void> _fetchShipments() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final receiverId = Get.find<SessionService>().currentUserId;
      if (receiverId == null) {
        setState(() {
          _loading = false;
          _error = 'ไม่พบผู้ใช้ปัจจุบัน (receiverId == null)';
        });
        return;
      }

      final uri = Uri.parse(
        '${widget.baseUrl}/shipments',
      ).replace(queryParameters: {'receiverId': '$receiverId'});

      final resp = await http
          .get(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 15));
      handleAuthErrorIfAny(resp);
      final body = jsonDecode(utf8.decode(resp.bodyBytes));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List list = (body is Map && body['data'] is List)
            ? (body['data'] as List)
            : (body is List ? body : const []);

        String? abs(String s) {
          s = s.trim();
          if (s.isEmpty) return null;
          return s.startsWith('http') ? s : _joinBase(widget.baseUrl, s);
        }

        final mapped = list.map<Map<String, dynamic>>((x) {
          final pickup =
              (x['pickup'] ?? x['pickup_address'] ?? <String, dynamic>{})
                  as Map? ??
              {};
          final dropoff =
              (x['dropoff'] ?? x['dropoff_address'] ?? <String, dynamic>{})
                  as Map? ??
              {};

          final double? distanceKm = (x['distance_km'] is num)
              ? (x['distance_km'] as num).toDouble()
              : null;
          final String distanceText = distanceKm != null
              ? '${distanceKm.toStringAsFixed(1)} กม.'
              : _mockDistance(x['id'] ?? 0);

          final cover =
              (x['cover_file_path'] ?? x['file_path'] ?? '') as String;
          final coverUrl = abs(cover);

          final pickupPhotoUrl = abs((x['pickup_photo_path'] ?? '') as String);
          final deliverPhotoUrl = abs(
            (x['deliver_photo_path'] ?? '') as String,
          );

          final rawSenderAvatar = (x['sender']?['avatar_path'] ?? '') as String;
          final senderAvatar = abs(rawSenderAvatar);

          final rawReceiverAvatar =
              (x['receiver']?['avatar_path'] ?? '') as String;
          final receiverAvatar = abs(rawReceiverAvatar);

          final rider = x['assignment']?['rider'];
          final riderName =
              (rider?['name'] as String?)?.trim().isNotEmpty == true
              ? rider['name'] as String
              : null;
          final riderAvatar = abs((rider?['avatar_path'] ?? '') as String);

          return {
            'id': x['id'],
            'title': (x['title'] ?? 'Order').toString(),
            'from': (pickup['label'] ?? pickup['address_text'] ?? '—')
                .toString(),
            'to': (dropoff['label'] ?? dropoff['address_text'] ?? '—')
                .toString(),
            'distance': distanceText,
            'image': coverUrl ?? deliverPhotoUrl ?? pickupPhotoUrl,
            'status': _mapStatus((x['status'] ?? '').toString()),

            'sender_avatar': senderAvatar,
            'receiver_avatar': receiverAvatar,

            'pickup_photo_url': pickupPhotoUrl,
            'deliver_photo_url': deliverPhotoUrl,

            'rider_name': riderName,
            'rider_avatar': riderAvatar,

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

  String _mockDistance(dynamic seed) {
    final i = (seed is int) ? seed : 1;
    final km = (1.2 + (i * 0.8) + Random(i).nextDouble()).toStringAsFixed(1);
    return '$km กม.';
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

  void _openDetail(Map<String, dynamic> m) {
    final raw = m['_raw'] as Map<String, dynamic>? ?? {};
    final pickup = m['_pickup'] as Map<String, dynamic>? ?? const {};
    final dropoff = m['_dropoff'] as Map<String, dynamic>? ?? const {};

    String safeAbs(String? path, String fallback) {
      if (path == null || path.trim().isEmpty) return fallback;
      return path.startsWith('http') ? path : _joinBase(widget.baseUrl, path);
    }

    final senderAvatar = safeAbs(
      raw['sender']?['avatar_path'] as String?,
      'assets/images/default_avatar.png',
    );

    final receiverAvatar = safeAbs(
      raw['receiver']?['avatar_path'] as String?,
      'assets/images/default_avatar.png',
    );

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: OrderDetailCard(
              productName: m['title'] as String,
              imagePath: m['image'] as String?,
              status: m['status'] as OrderStatus,
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
                address: (dropoff['address_text'] ?? dropoff['label'] ?? '—')
                    .toString(),
                placeName: (dropoff['label'] ?? '—').toString(),
              ),
              pickupPhotoUrl: m['pickup_photo_url'] as String?,
              deliverPhotoUrl: m['deliver_photo_url'] as String?,
            ),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F8F8),
      child: RefreshIndicator(
        onRefresh: _fetchShipments,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          children: [
            const SizedBox(height: 10),
            SectionTitle('รายการพัสดุที่ฉันจะได้รับ'),
            const SizedBox(height: 10),

            if (_loading) ...[
              _LoadingCard(),
              const SizedBox(height: 12),
              _LoadingCard(),
              const SizedBox(height: 12),
              _LoadingCard(),
            ] else if (_error != null) ...[
              _ErrorTile(message: _error!, onRetry: _fetchShipments),
            ] else if (_items.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'ยังไม่มีข้อมูลการจัดส่ง',
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
                        status: m['status'] as OrderStatus,
                        onDetail: () => _openDetail(m),
                      ),

                      if (m['rider_avatar'] != null || m['rider_name'] != null)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Tooltip(
                            message: (m['rider_name'] as String?) ?? 'Rider',
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundImage: (m['rider_avatar'] != null)
                                    ? NetworkImage(m['rider_avatar'] as String)
                                    : const AssetImage(
                                            'assets/images/default_avatar.png',
                                          )
                                          as ImageProvider,
                                backgroundColor: Colors.grey.shade200,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
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
