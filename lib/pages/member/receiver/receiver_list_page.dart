import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:songduan_app/services/mock_realtime_service.dart';
import 'package:songduan_app/widgets/order_card.dart';
import 'package:songduan_app/widgets/order_detail_card.dart';
import 'package:songduan_app/widgets/section_title.dart';

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

    // final items = <Map<String, dynamic>>[];

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
        const SizedBox(height: 10),
        SectionTitle('ของที่กำลังจัดส่งมายังฉัน (Receiver)'),
        const SizedBox(height: 10),

        if (items.isEmpty) ...[
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
                      Get.dialog(
                        Dialog(
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: SingleChildScrollView(
                              child: OrderDetailCard(
                                productName: m['title'] as String,
                                imagePath: m['image'],
                                status: status,
                                sender: PersonInfo(
                                  avatar: 'assets/images/Leonardo.png',
                                  role: 'ผู้ส่ง',
                                  name: 'สมศักดิ์ สิทธิบัน',
                                  phone: '093-9054980',
                                  address:
                                      'บ้านนาถุสิถิ๋ ตำบลสงสัย อำเภอบ่านสนใจ\nมหาสารคาม 44150 ประเทศไทย',
                                  placeName: m['from'] as String,
                                ),
                                receiver: PersonInfo(
                                  avatar: 'assets/images/Leonardo.png',
                                  role: 'ผู้รับ',
                                  name: 'สิทธิบัน',
                                  phone: '093-9054980',
                                  address:
                                      'บ้านนาถุสิถิ๋ ตำบลสงสัย อำเประเทศไทย',
                                  placeName: m['to'] as String,
                                ),
                              ),
                            ),
                          ),
                        ),
                        barrierDismissible: true,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
