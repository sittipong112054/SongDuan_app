import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:songduan_app/widgets/order_card.dart';

import 'package:songduan_app/widgets/order_detail_card.dart';
import 'package:songduan_app/widgets/gradient_button.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({
    super.key,
    required this.productName,
    required this.sender,
    required this.receiver,
    this.imagePath,
    required this.status,
  });

  final String productName;
  final PersonInfo sender;
  final PersonInfo receiver;
  final String? imagePath;
  final OrderStatus status;

  // static const _bg = Color(0xFFF6EADB);
  static const _textDark = Color(0xFF2F2F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          children: [
            // Header โปรไฟล์ (ตัวอย่าง)
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.grey,
                  backgroundImage: AssetImage('assets/images/johncena.png'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'John Cena',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      'Rider',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.45),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert_rounded),
                  color: Colors.black54,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // การ์ดรายละเอียด
            OrderDetailCard(
              productName: productName,
              imagePath: imagePath,
              sender: sender,
              receiver: receiver,
              status: status,
              showStatus: false,
            ),

            const SizedBox(height: 22),

            // ปุ่มล่าง (แล้วแต่ flow)
            SizedBox(
              height: 56,
              child: GradientButton(
                text: 'ยืนยันการรับงาน',
                onTap: () =>
                    Get.snackbar('ยืนยันแล้ว', 'รับงานเข้าสู่คิวของคุณ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
