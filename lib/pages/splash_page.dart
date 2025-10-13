import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:songduan_app/pages/welcome_page.dart';
import 'package:songduan_app/pages/member/member_home_page.dart';
import 'package:songduan_app/pages/rider/rider_home_page.dart';
import 'package:songduan_app/services/session_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _decideRoute);
  }

  Future<void> _decideRoute() async {
    final ss = Get.find<SessionService>();

    if (ss.isLoggedIn) {
      final userData = {
        'id': ss.currentUserId ?? 0,
        'role': (ss.role ?? '').toUpperCase(),
        'name': ss.name ?? '',
        'username': ss.username ?? '',
        'phone': ss.phone ?? '',
        'avatar_path': ss.avatarPath ?? '',
      };

      switch ((ss.role ?? '').toUpperCase()) {
        case 'RIDER':
          Get.off(
            () => const RiderHomePage(),
            arguments: userData,
            transition: Transition.circularReveal,
            duration: const Duration(milliseconds: 1000),
          );
          return;
        case 'MEMBER':
          Get.off(
            () => const MemberHomePage(),
            arguments: userData,
            transition: Transition.circularReveal,
            duration: const Duration(milliseconds: 1000),
          );
          return;
        default:
          break;
      }
    }

    Get.off(
      () => const WelcomePage(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(18),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Text(
                  'SONGDUAN EXPRESS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.staatliches(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 3
                      ..color = _orange,
                    shadows: [Shadow(color: _gold, offset: const Offset(6, 0))],
                  ),
                ),
                Text(
                  'SONGDUAN EXPRESS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.staatliches(
                    fontSize: 42,
                    letterSpacing: 1.2,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              'เรียลไทม์ ส่งไว ถึงชัวร์',
              style: GoogleFonts.notoSansThai(
                color: const Color(0xFF8C8C8C).withOpacity(0.65),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
