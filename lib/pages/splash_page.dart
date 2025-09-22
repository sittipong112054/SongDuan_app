import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:songduan_app/pages/welcome_page.dart';

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
    Future.delayed(const Duration(seconds: 2), () {
      Get.off(
        () => const WelcomePage(),
        transition: Transition.circularReveal,
        duration: const Duration(milliseconds: 1000),
      );
    });
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
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                    fontWeight: FontWeight.normal,
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
                color: Color(0xFF8C8C8C).withOpacity(0.65),
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
