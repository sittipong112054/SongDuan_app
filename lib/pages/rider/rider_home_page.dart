import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/profile_page.dart';
import 'package:songduan_app/pages/rider/order_detail_page.dart';

import 'package:songduan_app/widgets/order_card.dart';
import 'package:songduan_app/widgets/order_detail_card.dart';
import 'package:songduan_app/widgets/profile_header.dart';

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  static const _textDark = Color(0xFF2F2F2F);

  String? _baseUrl; // จะได้จาก config
  String? _cfgError; // เก็บ error ถ้ามี
  bool _loadingCfg = true; // สถานะโหลด config

  late final Map<String, dynamic> _user;
  late final String _name;
  late final String _roleLabel;

  @override
  void initState() {
    super.initState();
    _loadConfig();

    final args = Get.arguments;
    _user = (args is Map<String, dynamic>) ? args : <String, dynamic>{};
    _name = (_user['name'] ?? _user['username'] ?? 'ผู้ใช้').toString();

    final role = (_user['role'] ?? '').toString().toUpperCase();
    _roleLabel = switch (role) {
      'RIDER' => 'Rider',
      'MEMBER' => 'Member',
      _ => 'Rider',
    };
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig(); // <- ของคุณ
      setState(() {
        _baseUrl = config['apiEndpoint'] as String?;
        _loadingCfg = false;
      });
    } catch (e) {
      setState(() {
        _cfgError = '$e';
        _loadingCfg = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCfg) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_cfgError != null || _baseUrl == null || _baseUrl!.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'โหลดค่า config ไม่สำเร็จ: ${_cfgError ?? "apiEndpoint ว่าง"}',
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            ProfileHeader(
              name: _name,
              role: _roleLabel,
              image: _user['avatar_path']?.toString().isNotEmpty == true
                  ? _user['avatar_path'] as String
                  : 'assets/images/default_avatar.png',
              baseUrl: _baseUrl,
              onMorePressed: () =>
                  Get.to(() => const ProfilePage(), arguments: _user),
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
                  status: OrderStatus.riderAccepted,
                  onDetail: () {
                    Get.to(
                      () => OrderDetailPage(
                        productName: 'Food Delivery',
                        imagePath: 'assets/images/logo.png',
                        status: OrderStatus.waitingPickup,
                        sender: PersonInfo(
                          avatar: 'assets/images/Leonardo.png',
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
