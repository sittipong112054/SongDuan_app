import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/pages/login_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // โทนสีหลัก
  static const _bg = Color(0xFFF6EADB); // ครีมอ่อน
  static const _orange = Color(0xFFFF7A00); // ส้มหลัก
  // static const _gold = Color(0xFFFFB52E); // ทองไล่เฉด
  static const _textDark = Color(0xFF2F2F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 150),
              // โลโก้กลม ๆ ตรงกลาง
              Container(
                width: 160,
                height: 160,
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
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),

              // ชื่อแอป + สโลแกน
              // ชื่อแอป + สโลแกน
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
              Text(
                'เรียลไทม์ ส่งไว ถึงชัวร์',
                style: GoogleFonts.nunitoSans(
                  color: _textDark.withOpacity(0.65),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const Spacer(),

              // ปุ่ม Login (สีขาว)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginPages(), // เรียกหน้า LoginPages โดยตรง
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 2,
                    shadowColor: Colors.black12,
                    backgroundColor: Colors.white,
                    foregroundColor: _orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('ลงชื่อเข้าสู่ระบบ'),
                ),
              ),

              const SizedBox(height: 18),

              // เส้นคั่น Or
              Row(
                children: [
                  Expanded(child: _line()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or',
                      // ignore: deprecated_member_use
                      style: GoogleFonts.abel(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _textDark.withOpacity(0.6),
                      ),
                    ),
                  ),
                  Expanded(child: _line()),
                ],
              ),

              const SizedBox(height: 18),

              // ปุ่ม Register (ไล่เฉด)
              _GradientButton(text: 'ลงทะเบียน', onTap: _onRegister),

              const SizedBox(height: 18),

              // ข้อความเงื่อนไข/นโยบาย
              _TermsRichText(
                onTapTerms: _openTerms,
                onTapPrivacy: _openPrivacy,
              ),

              const SizedBox(height: 70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line() => Container(height: 1, color: Colors.black12);

  void _onRegister() {
    // TODO: นำทางไปหน้า Register
    // Navigator.pushNamed(context, '/register');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ไปหน้า Register')));
  }

  void _openTerms() {
    // TODO: เปิดหน้าหรือเว็บเพจข้อตกลง
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('เปิด “ข้อกำหนดและเงื่อนไข”')));
  }

  void _openPrivacy() {
    // TODO: เปิดหน้าหรือเว็บเพจนโยบายความเป็นส่วนตัว
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('เปิด “นโยบายความเป็นส่วนตัว”')),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  static const _orange = Color(0xFFFF7A00);
  static const _gold = Color(0xFFFFB52E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_orange, _gold],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'ลงทะเบียน',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TermsRichText extends StatelessWidget {
  const _TermsRichText({required this.onTapTerms, required this.onTapPrivacy});

  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.black54, height: 1.4);

    return Text.rich(
      TextSpan(
        text: 'ดำเนินการต่อ หมายความว่าคุณยอมรับ ',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.black87,
        ),
        children: [
          TextSpan(
            text: 'ข้อกำหนดและเงื่อนไข',
            style: base?.copyWith(
              color: const Color.fromARGB(255, 76, 0, 255),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTapTerms,
          ),
          TextSpan(text: ' และ ', style: base),
          TextSpan(
            text: 'นโยบายความเป็นส่วนตัว',
            style: base?.copyWith(
              color: const Color.fromARGB(255, 76, 0, 255),
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTapPrivacy,
          ),
          TextSpan(
            text: ' ของ SongDuan',
            style: TextStyle(
              fontWeight: FontWeight.w200,
              fontSize: 14,
              color: const Color.fromARGB(255, 76, 0, 255),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
