import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:songduan_app/pages/profile_page.dart';
import 'package:songduan_app/widgets/order_card.dart';

import 'package:songduan_app/widgets/order_detail_card.dart';
import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/profile_header.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          children: [
            ProfileHeader(
              name: "John Cena",
              role: "Rider",
              image: "assets/images/johncena.png",
              onMorePressed: () {
                Get.to(
                  () => const ProfilePage(),
                  transition: Transition.fade,
                  duration: const Duration(milliseconds: 350),
                );
              },
            ),

            const SizedBox(height: 16),

            OrderDetailCard(
              productName: productName,
              imagePath: imagePath,
              sender: sender,
              receiver: receiver,
              status: status,
              showStatus: true,
            ),

            const SizedBox(height: 22),

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
