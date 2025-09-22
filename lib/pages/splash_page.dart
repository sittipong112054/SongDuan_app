import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/pages/welcome_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _orange = Color(0xFFFF7A00); // ส้มหลัก

  @override
  void initState() {
    super.initState();

    // รอ 3 วิแล้วเปลี่ยนด้วย Fade Transition
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // ใช้ FadeTransition
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(
            milliseconds: 1500,
          ), // เวลา fade 0.8 วิ
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // พื้นหลังขาวเหมือนในภาพ
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // โลโก้
            Container(
              width: 140,
              height: 140,
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

            // ชื่อแอป
            Stack(
              children: [
                // Stroke (ขอบตัวอักษร)
                Text(
                  'SONGDUAN EXPRESS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.staatliches(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth =
                          3 // ความหนาเส้นขอบ
                      ..color = const Color.fromARGB(
                        255,
                        255,
                        63,
                        0,
                      ), // สีขอบส้ม
                    shadows: [
                      Shadow(
                        color: _orange.withOpacity(0.6),
                        // color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 8),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                // Fill (ตัวอักษรด้านใน)
                Text(
                  'SONGDUAN EXPRESS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.staatliches(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white, // สีด้านใน (ตามฟิกม่าคือ #F3F4FD)
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

            const SizedBox(height: 6),

            // สโลแกน
            const Text(
              'เรียลไทม์ ส่งไว ถึงชัวร์',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
