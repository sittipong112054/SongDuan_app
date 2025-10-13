import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mini_gradient_button.dart';

enum OrderStatus { waitingPickup, riderAccepted, delivering, delivered }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: (imagePath != null && imagePath!.trim().isNotEmpty)
                    ? Image.network(
                        imagePath!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _PhotoPlaceholder(text: 'โหลดรูปไม่สำเร็จ'),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    : const Icon(
                        Icons.image_not_supported_rounded,
                        size: 48,
                        color: Colors.grey,
                      ),
              ),
            ],
          ),

          const SizedBox(width: 14),

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
                          color: Colors.black.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        'ไป',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                      Text(
                        to,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.black.withValues(alpha: 0.75),
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
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

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

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.image_not_supported_rounded,
          size: 36,
          color: Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.notoSansThai(
            color: Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
