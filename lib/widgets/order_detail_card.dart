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
  });

  final String productName;
  final PersonInfo sender;
  final PersonInfo receiver;
  final String?
  imagePath; // 👉 ควรเป็น URL (http/https) ถ้าไม่ใช่จะ fallback icon
  final OrderStatus status;
  final bool showStatus;

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

          // รูปสินค้า (NetworkImage)
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

          if (showStatus)
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
        ],
      ),
    );
  }
}

class PersonInfo {
  /// avatar ควรเป็น URL (http/https) ถ้าไม่ใช่จะ fallback เป็น default icon
  final String avatar;
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
        child: const SizedBox.shrink(),
      );
    } else {
      // ถ้าไม่ใช่ URL → ใช้ icon เอง (กันพัง)
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
