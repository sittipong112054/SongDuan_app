import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/services/mock_realtime_service.dart';
import 'package:songduan_app/widgets/order_tile.dart';

class ReceiverListPage extends StatelessWidget {
  final String baseUrl;
  const ReceiverListPage({super.key, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    final svc = MockRealtimeService();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Text(
          'ของที่กำลังจัดส่งมายังฉัน',
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),

        ...List.generate(
          2,
          (i) => StreamBuilder<int>(
            stream: svc.orderStatusStream(),
            builder: (context, snap) {
              final status = snap.data ?? 1;
              return OrderTile(
                title: 'Incoming #${i + 1}',
                subtitle: 'จาก: ร้านตัวอย่าง ${i + 1}',
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
