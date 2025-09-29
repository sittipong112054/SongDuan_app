import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:songduan_app/services/mock_realtime_service.dart';
import 'package:songduan_app/widgets/order_card.dart';

class ReceiverListPage extends StatelessWidget {
  final String baseUrl;
  const ReceiverListPage({super.key, required this.baseUrl});

  String _mockDistance(int i) {
    final km = (0.8 + (i * 0.6) + Random(99 + i).nextDouble()).toStringAsFixed(
      1,
    );
    return '$km กม.';
  }

  @override
  Widget build(BuildContext context) {
    final svc = MockRealtimeService();

    // mock รายการ 2 ชิ้นที่กำลังมาหาเรา
    final items = List.generate(2, (i) {
      return {
        'title': 'Incoming #${i + 1}',
        'from': 'คุณ Sender ${i + 1}',
        'to': 'บ้านฉัน',
        'distance': _mockDistance(i),
        'image': i == 0 ? 'assets/images/mrbeast.jpg' : null,
      };
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Text(
          'ของที่กำลังจัดส่งมายังฉัน (Receiver)',
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),

        ...items.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: StreamBuilder(
              stream: svc.orderStatusStream(),
              builder: (context, snapshot) {
                final status = snapshot.data ?? OrderStatus.waitingPickup;
                return OrderCard(
                  title: m['title'] as String,
                  from: m['from'] as String,
                  to: m['to'] as String,
                  distanceText: m['distance'] as String,
                  imagePath: m['image'],
                  status: status,
                  onDetail: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ดูรายละเอียด: ${m['title']} (mock)'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
