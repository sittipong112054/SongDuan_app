import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/pages/login_page.dart';
import 'package:songduan_app/widgets/gradient_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _textDark = Color(0xFF2F2F2F);

  @override
  Widget build(BuildContext context) {
    final double avatarSize = MediaQuery.of(context).size.width / 3;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.nunitoSans(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _textDark,
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,

      // เนื้อหาเลื่อน
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            // Avatar + name + role
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundImage: const AssetImage('assets/images/Vin.png'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vin Diesel',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        'Member',
                        style: GoogleFonts.nunitoSans(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.45),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              'ข้อมูลส่วนตัว',
              style: GoogleFonts.nunitoSans(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 10),
            const _ReadOnlyField(hint: 'Name', value: 'Vin Diesel'),
            const SizedBox(height: 10),
            const _ReadOnlyField(hint: 'Phone Number', value: '093-9054980'),

            const SizedBox(height: 18),

            Row(
              children: [
                Text(
                  'ที่อยู่',
                  style: GoogleFonts.nunitoSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Get.snackbar('ที่อยู่', 'เพิ่มที่อยู่ใหม่'),
                  child: Text(
                    'เพิ่มที่อยู่',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF9C00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            const _AddressTile(
              title: 'ร้านข้าวมันไก่',
              subtitle: 'บ้านบางดุสึอิ: ตำบลสงสัย...',
            ),
            const SizedBox(height: 10),
            const _AddressTile(
              title: 'ร้านข้าวมันไก่',
              subtitle: 'บ้านบางดุสึอิ: ตำบลสงสัย...',
            ),
          ],
        ),
      ),

      // ปุ่มล่างสุด
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(18),
        child: SizedBox(
          height: 56,
          child: GradientButton(
            text: 'ออกจากระบบ',
            onTap: () {
              Get.snackbar('ออกจากระบบ', 'ทำการออกจากระบบแล้ว');
              Get.to(() => LoginPages());
            },
          ),
        ),
      ),
    );
  }
}

/// การ์ดแสดงค่าข้อมูลอ่านอย่างเดียว (ซ้ายเป็น hint จาง ๆ ขวาเป็นค่า)
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.hint, required this.value});

  final String hint;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: GoogleFonts.nunitoSans(
                color: Colors.black.withOpacity(0.35),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunitoSans(
              color: Colors.black.withOpacity(0.8),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ดแถวที่อยู่ พร้อมลูกศร
class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F7),
      borderRadius: BorderRadius.circular(14),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // ดู/แก้ไขที่อยู่
          Get.snackbar('ที่อยู่', 'เปิดรายละเอียดที่อยู่');
        },
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: GoogleFonts.nunitoSans(
                    color: Colors.black.withOpacity(0.8),
                    fontWeight: FontWeight.w900,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunitoSans(
                          color: Colors.black.withOpacity(0.35),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: Colors.black.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
