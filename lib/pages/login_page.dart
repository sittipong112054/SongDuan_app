import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/pages/register_page.dart';
import 'package:songduan_app/pages/welcome_page.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';
import 'package:songduan_app/widgets/gradient_button.dart';

class LoginPages extends StatefulWidget {
  const LoginPages({super.key});

  @override
  State<LoginPages> createState() => _LoginPagesState();
}

class _LoginPagesState extends State<LoginPages> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  static const _bg = Color(0xFFF6EADB);
  static const _gold = Color(0xFFFF9C00);
  static const _textDark = Color(0xFF2F2F2F);

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _textDark.withOpacity(0.85),
          onPressed: () => Get.to(WelcomePage()),
          splashRadius: 22,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 140,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 34),
              // หัวข้อ
              Center(
                child: Text(
                  'Login To Your Account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 64),
              CustomTextField(
                hint: 'Email',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 28),
              ),

              const SizedBox(height: 14),

              CustomTextField(
                hint: 'Password',
                controller: _passCtrl,
                obscure: _obscure,
                prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),

              const Spacer(),
              GradientButton(text: 'เข้าสู่ระบบ', onTap: _onLogin),
              const SizedBox(height: 64),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13.5,
                      color: _textDark.withOpacity(0.6),
                    ),
                    children: [
                      const TextSpan(text: "Don't have an account? "),
                      TextSpan(
                        text: 'Sign up',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          color: _gold,
                        ),
                        recognizer: (TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => RegisterPage());
                          }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _onLogin() {
    // Get.back();
  }
}
