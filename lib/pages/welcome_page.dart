import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/pages/login_page.dart';
import 'package:songduan_app/pages/register_page.dart';
import 'package:songduan_app/widgets/gradient_button.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);
  static const _textDark = Color(0xFF2F2F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1DB),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 150),
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
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
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
                      shadows: [
                        Shadow(color: _gold, offset: const Offset(6, 0)),
                      ],
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
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => const LoginPages()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'ลงชื่อเข้าสู่ระบบ',
                    style: GoogleFonts.notoSansThai(
                      color: _gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: _line()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'Or',
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

              GradientButton(text: 'ลงทะเบียน', onTap: _onRegister),
              const SizedBox(height: 60),

              _TermsRichText(
                onTapTerms: _openTerms,
                onTapPrivacy: _openPrivacy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line() => Container(height: 1, color: Colors.black12);

  void _onRegister() => Get.to(() => const RegisterPage());

  void _openTerms() {
    Get.snackbar(
      'เปิด',
      'ข้อกำหนดและเงื่อนไข',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _openPrivacy() {
    Get.snackbar(
      'เปิด',
      'นโยบายความเป็นส่วนตัว',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

class _TermsRichText extends StatefulWidget {
  const _TermsRichText({required this.onTapTerms, required this.onTapPrivacy});

  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  @override
  State<_TermsRichText> createState() => _TermsRichTextState();
}

class _TermsRichTextState extends State<_TermsRichText> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = widget.onTapTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = widget.onTapPrivacy;
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.black54,
      height: 1.4,
      fontSize: 13,
    );

    return Text.rich(
      TextSpan(
        text: 'ดำเนินการต่อ หมายความว่าคุณยอมรับ ',
        style: base,
        children: [
          TextSpan(
            text: 'ข้อกำหนดและเงื่อนไข',
            style: base?.copyWith(color: const Color(0xff0070E0)),
            recognizer: _termsRecognizer,
          ),
          TextSpan(text: ' และ ', style: base),
          TextSpan(
            text: 'นโยบายความเป็นส่วนตัว',
            style: base?.copyWith(color: const Color(0xff0070E0)),
            recognizer: _privacyRecognizer,
          ),
          const TextSpan(
            text: ' SongDuan',
            style: TextStyle(color: Color(0xff0070E0), fontSize: 13),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
