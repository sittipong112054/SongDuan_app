import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mini_gradient_button.dart';

enum OrderStatus {
  waitingPickup, // [1] รอไรเดอร์มารับสินค้า
  riderAccepted, // [2] ไรเดอร์รับงาน (กำลังเดินทางมารับสินค้า)
  delivering, // [3] ไรเดอร์รับสินค้าแล้วและกำลังส่ง
  delivered, // [4] ส่งสำเร็จแล้ว
}

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.title,
    required this.from,
    required this.to,
    required this.distanceText,
    required this.status,
    this.imagePath,
    this.onDetail,
  });

  final String title;
  final String from;
  final String to;
  final String distanceText;
  final String? imagePath;
  final VoidCallback? onDetail;
  final OrderStatus status;

  // ---------- MAP: status → icon ----------
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

  // ---------- MAP: status → gradient colors ----------
  List<Color> _mapStatusToColors(OrderStatus status) {
    switch (status) {
      case OrderStatus.waitingPickup:
        return [Colors.grey.shade400, Colors.grey.shade600]; // รอ
      case OrderStatus.riderAccepted:
        return [Colors.blue.shade400, Colors.blue.shade700]; // กำลังมา
      case OrderStatus.delivering:
        return [Colors.orange.shade400, Colors.deepOrange.shade700]; // ส่งอยู่
      case OrderStatus.delivered:
        return [Colors.green.shade400, Colors.green.shade700]; // ส่งสำเร็จ
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- LEFT: product image ----------
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: imagePath != null
                    ? Image.asset(imagePath!, fit: BoxFit.cover)
                    : const Icon(
                        Icons.image_not_supported_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // ---------- MIDDLE ----------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2F2F2F),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        from,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.75),
                        ),
                      ),
                      Text(
                        'ไป',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withOpacity(0.45),
                        ),
                      ),
                      Text(
                        to,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withOpacity(0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  distanceText,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ---------- RIGHT ----------
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _mapStatusToColors(status),
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _mapStatusToIcon(status),
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              MiniGradientButton(text: 'รายละเอียด', onTap: onDetail ?? () {}),
            ],
          ),
        ],
      ),
    );
  }
}
