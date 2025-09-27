import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/services/mock_realtime_service.dart';
import 'package:songduan_app/widgets/order_tile.dart';

class SenderListPage extends StatelessWidget {
  final String baseUrl;
  const SenderListPage({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    // เดโม่: ใช้สตรีมสถานะร่วมกัน
    final svc = MockRealtimeService();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Text(
          'รายการส่งของของฉัน',
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),

        // mock 3 orders
        ...List.generate(
          3,
          (i) => StreamBuilder<int>(
            stream: svc.orderStatusStream(),
            builder: (context, snap) {
              final status = snap.data ?? 1;
              return OrderTile(
                title: 'Order #${i + 1}',
                subtitle: 'ปลายทาง: ซอยตัวอย่าง ${10 + i}',
                status: status,
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}
