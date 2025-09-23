import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/pages/profile_page.dart';
import 'package:songduan_app/pages/rider/order_detail_page.dart';

import 'package:songduan_app/widgets/order_card.dart';
import 'package:songduan_app/widgets/order_detail_card.dart';
import 'package:songduan_app/widgets/profile_header.dart';

class RiderHomePage extends StatelessWidget {
  const RiderHomePage({super.key});

  // static const _bg = Color(0xFFF6EADB);
  static const _textDark = Color(0xFF2F2F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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
            Text(
              'รายการสินค้า',
              style: GoogleFonts.notoSansThai(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(3, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: OrderCard(
                  title: 'Food Delivery',
                  from: 'ร้านข้าวมันไก่',
                  to: 'หอมีชัยแมนชั่น',
                  distanceText: 'ระยะทาง 0.9 km.',
                  imagePath: null,
                  status: OrderStatus.waitingPickup,
                  onDetail: () {
                    Get.to(
                      () => OrderDetailPage(
                        productName: 'Food Delivery',
                        imagePath: 'assets/images/logo.png',
                        status: OrderStatus.waitingPickup,
                        sender: PersonInfo(
                          avatar: 'assets/images/Vin.png',
                          role: 'ผู้ส่ง',
                          name: 'สมศักดิ์ สิทธิบัน',
                          phone: '093-9054980',
                          address:
                              'บ้านนาถุสิถิ๋ ตำบลสงสัย อำเภอบ่านสนใจ\nมหาสารคาม 44150 ประเทศไทย',
                          placeName: 'ร้านข้าวมันไก่d',
                        ),
                        receiver: PersonInfo(
                          avatar: 'assets/images/Leonardo.png',
                          role: 'ผู้รับ',
                          name: 'สิทธิบัน',
                          phone: '093-9054980',
                          address: 'บ้านนาถุสิถิ๋ ตำบลสงสัย อำเประเทศไทย',
                          placeName: 'หอมีชัยแมนชั่น',
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
