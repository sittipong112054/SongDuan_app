import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/widgets/order_card.dart';

class OrderDetailCard extends StatelessWidget {
  const OrderDetailCard({
    super.key,
    required this.productName,
    required this.sender,
    required this.receiver,
    this.imagePath,
    required this.status,
    this.showStatus = true,
    this.pickupPhotoUrl, // รูปตอนรับ (จาก backend)
    this.deliverPhotoUrl, // รูปตอนส่ง (จาก backend)
  });

  final String productName;
  final PersonInfo sender;
  final PersonInfo receiver;
  final String? imagePath;
  final OrderStatus status;
  final bool showStatus;
  final String? pickupPhotoUrl;
  final String? deliverPhotoUrl;

  static const _textDark = Color(0xFF2F2F2F);

  IconData _mapStatusToIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingPickup:
        return Icons.store_mall_directory_rounded;
      case OrderStatus.riderAccepted:
        return Icons.pedal_bike_rounded;
      case OrderStatus.delivering:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.check_circle_rounded;
    }
  }

  List<Color> _mapStatusToColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingPickup:
        return [Colors.grey.shade400, Colors.grey.shade600];
      case OrderStatus.riderAccepted:
        return [Colors.blue.shade400, Colors.blue.shade700];
      case OrderStatus.delivering:
        return [Colors.orange.shade400, Colors.deepOrange.shade700];
      case OrderStatus.delivered:
        return [Colors.green.shade400, Colors.green.shade700];
    }
  }

  String _mapStatusToText(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingPickup:
        return 'รอไรเดอร์มารับสินค้า [1]';
      case OrderStatus.riderAccepted:
        return 'ไรเดอร์รับงาน [2]';
      case OrderStatus.delivering:
        return 'กำลังจัดส่ง [3]';
      case OrderStatus.delivered:
        return 'จัดส่งสำเร็จแล้ว [4]';
    }
  }

  bool _isHttpUrl(String? s) {
    if (s == null) return false;
    final v = s.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  void _openImage(String url, {String? title}) {
    Get.dialog(
      Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 320,
                    child: Center(
                      child: Icon(Icons.broken_image_outlined, size: 48),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: Get.back,
              ),
            ),
            if (title != null && title.isNotEmpty)
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    title,
                    style: GoogleFonts.notoSansThai(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      barrierDismissible: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _mapStatusToColors(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                splashRadius: 22,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'รายละเอียดรายการสินค้า',
                    style: GoogleFonts.notoSansThai(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
                    ),
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(6),
                child: Icon(_mapStatusToIcon(status), color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Cover / hero image
          Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFFE9E9E9),
                borderRadius: BorderRadius.circular(18),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: (_isHttpUrl(imagePath))
                  ? Image.network(
                      imagePath!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) => Icon(
                        Icons.broken_image_outlined,
                        size: 56,
                        color: Colors.black.withOpacity(0.45),
                      ),
                    )
                  : Icon(
                      Icons.image_not_supported_rounded,
                      size: 56,
                      color: Colors.black.withOpacity(0.45),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // ชื่อสินค้า
          Center(
            child: Text(
              productName,
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Sender
          Text(
            sender.placeName,
            style: GoogleFonts.notoSansThai(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          _PersonBlock(info: sender),

          const SizedBox(height: 14),

          // Receiver
          Text(
            receiver.placeName,
            style: GoogleFonts.notoSansThai(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          _PersonBlock(info: receiver),

          const SizedBox(height: 18),

          // แถบสถานะ
          // แถบสถานะ + ภาพสถานะ
          if (showStatus) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.last.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "สถานะ : ${_mapStatusToText(status)}",
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: colors.last,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ====== รูปสถานะ (ตอนรับ / ตอนส่ง) ======
            Text(
              'รูปสถานะ',
              style: GoogleFonts.notoSansThai(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatusPhotoTile(
                    title: 'ตอนรับ',
                    url: pickupPhotoUrl,
                    onTap: (u) => _openImage(u, title: 'รูปตอนรับ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatusPhotoTile(
                    title: 'ตอนส่ง',
                    url: deliverPhotoUrl,
                    onTap: (u) => _openImage(u, title: 'รูปตอนส่ง'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class PersonInfo {
  final String avatar; // network url หรือ asset fallback
  final String role;
  final String name;
  final String phone;
  final String address;
  final String placeName;

  PersonInfo({
    required this.avatar,
    required this.role,
    required this.name,
    required this.phone,
    required this.address,
    required this.placeName,
  });
}

class _PersonBlock extends StatelessWidget {
  const _PersonBlock({required this.info});
  final PersonInfo info;

  bool _isHttpUrl(String? s) {
    if (s == null) return false;
    final v = s.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final grey = Colors.black.withOpacity(0.7);

    Widget avatarWidget;
    if (_isHttpUrl(info.avatar)) {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: NetworkImage(info.avatar),
        onBackgroundImageError: (_, __) {},
      );
    } else if (info.avatar.startsWith('assets/')) {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundImage: AssetImage(info.avatar),
        backgroundColor: Colors.grey.shade200,
      );
    } else {
      avatarWidget = CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade300,
        child: const Icon(Icons.person, color: Colors.white),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatarWidget,
        const SizedBox(width: 10),
        Expanded(
          child: DefaultTextStyle(
            style: GoogleFonts.notoSansThai(
              fontSize: 13.5,
              color: grey,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.role,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: grey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(info.name), Text(info.phone)],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "ที่อยู่",
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: grey,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(info.address),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPhotoTile extends StatelessWidget {
  const _StatusPhotoTile({
    required this.title,
    required this.url,
    required this.onTap,
  });

  final String title;
  final String? url;
  final void Function(String url) onTap;

  bool _isHttpUrl(String? s) {
    if (s == null) return false;
    final v = s.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final has = _isHttpUrl(url);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.6,
          child: InkWell(
            onTap: has ? () => onTap(url!) : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              clipBehavior: Clip.antiAlias,
              child: has
                  ? Image.network(
                      url!,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, w, p) {
                        if (p == null) return w;
                        return const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) =>
                          const _PhotoPlaceholder(text: 'โหลดรูปไม่สำเร็จ'),
                    )
                  : const _PhotoPlaceholder(text: 'ยังไม่มีรูป'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.notoSansThai(
          color: Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
