import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/pages/member/add_profile_member_page.dart';
import 'package:songduan_app/pages/rider/add_profile_rider_page.dart';
import 'package:songduan_app/pages/login_page.dart';
import 'package:songduan_app/pages/welcome_page.dart';

import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

enum RegisterRole { member, rider }

class _RegisterPageState extends State<RegisterPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  RegisterRole _role = RegisterRole.member;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  static const _bg = Color(0xFFF6EADB);
  static const _gold = Color(0xFFFF9C00);
  static const _textDark = Color(0xFF2F2F2F);

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
              const SizedBox(height: 8),
              Center(
                child: SizedBox(
                  width: 140,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Create New Account',
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    child: _RoleChip(
                      label: 'Member',
                      selected: _role == RegisterRole.member,
                      onTap: () => setState(() => _role = RegisterRole.member),
                    ),
                  ),
                  const SizedBox(width: 70),
                  SizedBox(
                    width: 120,
                    child: _RoleChip(
                      label: 'Rider',
                      selected: _role == RegisterRole.rider,
                      onTap: () => setState(() => _role = RegisterRole.rider),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              CustomTextField(
                hint: 'Username',
                controller: _userCtrl,
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 28),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                hint: 'Password',
                controller: _passCtrl,
                obscure: _obscurePass,
                prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                  icon: Icon(
                    _obscurePass
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                hint: 'Confirm Password',
                controller: _confirmCtrl,
                obscure: _obscureConfirm,
                prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                ),
              ),
              const Spacer(),
              GradientButton(text: 'ถัดไป', onTap: _onNext),
              const SizedBox(height: 64),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: GoogleFonts.nunitoSans(
                      fontSize: 13.5,
                      color: _textDark.withOpacity(0.6),
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign in',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                          color: _gold,
                        ),
                        recognizer: (TapGestureRecognizer()
                          ..onTap = () {
                            Get.to(() => LoginPages());
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

  void _onNext() {
    if (_role == RegisterRole.rider) {
      // ไปหน้า Fill Your Profile (Rider)
      Get.to(() => const RiderProfilePage());
    } else {
      // ถ้าเป็น Member → ทำ flow อื่น เช่น กลับหน้า Home หรือ Verify OTP
      Get.to(() => const MemberProfilePage());
    }
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : const Color(0xFFE9E9E9);
    final fg = selected ? Colors.white : Colors.black.withOpacity(0.5);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    offset: const Offset(0, 6),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.nunitoSans(
            color: fg,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
