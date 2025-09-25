import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/login_page.dart';
import 'package:songduan_app/widgets/gradient_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _textDark = Color(0xFF2F2F2F);
  String? _baseUrl;

  late final Map<String, dynamic> user;
  late final String name;
  late final String roleLabel;
  late final String phone;
  late final String? avatarPath;
  late final List<Map<String, dynamic>> addresses;

  @override
  void initState() {
    super.initState();
    _loadConfig();

    final args = Get.arguments;
    user = (args is Map<String, dynamic>) ? args : <String, dynamic>{};

    name = (user['name'] ?? user['username'] ?? 'ผู้ใช้').toString();
    final role = (user['role'] ?? '').toString().toUpperCase();
    roleLabel = switch (role) {
      'RIDER' => 'Rider',
      'MEMBER' => 'Member',
      'USER' => 'User',
      _ => 'Member',
    };
    phone = (user['phone'] ?? '-').toString();
    avatarPath = user['avatar_path']?.toString();

    final rawAddrs = user['addresses'];
    if (rawAddrs is List) {
      addresses = rawAddrs
          .whereType<Map>()
          .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
          .toList()
          .cast<Map<String, dynamic>>();
    } else {
      addresses = const [];
    }
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() {
        _baseUrl = config['apiEndpoint'] as String?;
      });
    } catch (e) {}
  }

  ImageProvider _resolveAvatar(String? s) {
    if (s == null || s.trim().isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    final val = s.trim();

    if (val.startsWith('/')) {
      final b = (_baseUrl ?? '').trimRight();
      if (b.isNotEmpty) return NetworkImage('$b$val');
      return const AssetImage('assets/images/default_avatar.png');
    }

    return AssetImage(val);
  }

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

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          children: [
            // Avatar + name + role (ใช้รูปจริง)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundImage: _resolveAvatar(avatarPath),
                    backgroundColor: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        roleLabel,
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
            _ReadOnlyField(hint: 'Name', value: name),
            const SizedBox(height: 10),
            _ReadOnlyField(hint: 'Phone Number', value: phone),

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
                  onTap: () {
                    Get.snackbar('ที่อยู่', 'เพิ่มที่อยู่ใหม่');
                    // Get.to(() => MapPickPage());
                  },
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

            // แสดงรายการที่อยู่จริง (ถ้ามี) ไม่งั้นโชว์ตัวอย่างว่าง ๆ
            if (addresses.isNotEmpty)
              ...addresses.map((addr) {
                final title = (addr['label'] ?? 'ที่อยู่').toString();
                final subtitle = (addr['address_text'] ?? '').toString();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AddressTile(title: title, subtitle: subtitle),
                );
              })
            else ...[
              const _AddressTile(
                title: '—',
                subtitle: 'ยังไม่มีที่อยู่ตั้งค่าไว้',
              ),
            ],
          ],
        ),
      ),

      // ปุ่มออกจากระบบ
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(18),
        child: SizedBox(
          height: 56,
          child: GradientButton(
            text: 'ออกจากระบบ',
            onTap: () {
              // เคลียร์ session/states ตามจริงก่อน (ถ้ามี)
              Get.snackbar('ออกจากระบบ', 'ทำการออกจากระบบแล้ว');
              Get.offAll(() => const LoginPages());
            },
          ),
        ),
      ),
    );
  }
}

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
