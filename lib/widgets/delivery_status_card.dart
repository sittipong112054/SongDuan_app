import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/widgets/order_card.dart';

class DeliveryStatusCard extends StatelessWidget {
  final int number;
  final Color badgeColor;
  final String title;
  final String by;
  final String from;
  final String to;
  final OrderStatus status;
  final String? byAvatarUrl;

  const DeliveryStatusCard({
    super.key,
    required this.number,
    required this.badgeColor,
    required this.title,
    required this.by,
    required this.from,
    required this.to,
    required this.status,
    this.byAvatarUrl,
    required Null Function() onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleNumber(n: number, color: badgeColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (byAvatarUrl != null && byAvatarUrl!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(byAvatarUrl!),
                    onBackgroundImageError: (_, __) {},
                  ),
                ),
              Text(
                'โดย $by',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansThai(
                  color: Colors.black54,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          StatusStepBar(status: status),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: Text(
                  from,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansThai(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
              Text(
                'ไป',
                style: GoogleFonts.notoSansThai(
                  color: Colors.black45,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  to,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansThai(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleNumber extends StatelessWidget {
  final int n;
  final Color color;
  const _CircleNumber({required this.n, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '$n',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class StatusStepBar extends StatelessWidget {
  final OrderStatus status;
  const StatusStepBar({super.key, required this.status});

  int get activeIndex => switch (status) {
    OrderStatus.waitingPickup => 0,
    OrderStatus.riderAccepted => 0,
    OrderStatus.delivering => 1,
    OrderStatus.delivered => 2,
  };

  List<Color> get activePair => switch (status) {
    OrderStatus.waitingPickup => [Colors.grey, Colors.grey.shade700],
    OrderStatus.riderAccepted => [Colors.blue.shade400, Colors.blue.shade700],
    OrderStatus.delivering => [
      Colors.orange.shade400,
      Colors.deepOrange.shade700,
    ],
    OrderStatus.delivered => [Colors.green.shade400, Colors.green.shade700],
  };

  @override
  Widget build(BuildContext context) {
    const titles = ['เข้ารับสินค้า', 'กำลังส่งสินค้า', 'จัดส่งสำเร็จ'];
    final dotSize = 25.0;
    final lineColor = Colors.grey.shade300;
    final dotInactivePair = [Colors.grey.shade300, Colors.grey.shade400];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Dot(
                colors: activeIndex == 0 ? activePair : dotInactivePair,
                size: dotSize,
              ),
              Expanded(child: Container(height: 3, color: lineColor)),
              _Dot(
                colors: activeIndex == 1 ? activePair : dotInactivePair,
                size: dotSize,
              ),
              Expanded(child: Container(height: 3, color: lineColor)),
              _Dot(
                colors: activeIndex == 2 ? activePair : dotInactivePair,
                size: dotSize,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (i) {
            final isActive = i == activeIndex;
            final textColor = isActive ? activePair.last : Colors.black26;
            return Expanded(
              child: Align(
                alignment: i == 0
                    ? Alignment.centerLeft
                    : (i == 1 ? Alignment.center : Alignment.centerRight),
                child: Text(
                  titles[i],
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final List<Color> colors;
  final double size;
  const _Dot({required this.colors, required this.size});

  @override
  Widget build(BuildContext context) {
    final light = colors.first;
    final dark = colors.last;
    final isInactiveGrey = light.computeLuminance() == dark.computeLuminance();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isInactiveGrey
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [light, dark],
              ),
        color: isInactiveGrey ? dark : null,
      ),
    );
  }
}
