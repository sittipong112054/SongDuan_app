import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/models/register_payload.dart';
import 'package:songduan_app/pages/member/add_profile_member_page.dart';
import 'package:songduan_app/pages/rider/add_profile_rider_page.dart';
import 'package:songduan_app/pages/login_page.dart';

import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  RegisterRole _role = RegisterRole.member;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _autovalidate = false;

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

  bool get _formValid => _formKey.currentState?.validate() ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: _textDark.withOpacity(0.85),
          onPressed: () => Get.back(),
          splashRadius: 22,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 22,
            right: 22,
            top: 12,
            bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidate
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
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
                        onTap: () =>
                            setState(() => _role = RegisterRole.member),
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

                // USERNAME
                CustomTextField(
                  hint: 'Username',
                  controller: _userCtrl,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    size: 28,
                  ),
                  autofillHints: const [AutofillHints.username],
                  maxLength: 32,
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'กรอกชื่อผู้ใช้';
                    if (s.length < 4) return 'ความยาวอย่างน้อย 4 ตัวอักษร';
                    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(s)) {
                      return 'ใช้ได้เฉพาะ a-z, 0-9, ., _, -';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  onChanged: (_) => setState(() {}), // อัปเดตปุ่ม enable
                ),
                const SizedBox(height: 14),

                // PASSWORD
                CustomTextField(
                  hint: 'Password',
                  controller: _passCtrl,
                  obscure: _obscurePass,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                  autofillHints: const [AutofillHints.newPassword],
                  maxLength: 64,
                  validator: (v) {
                    final s = v ?? '';
                    if (s.isEmpty) return 'กรอกรหัสผ่าน';
                    if (s.length < 8) return 'ความยาวอย่างน้อย 8 ตัวอักษร';
                    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(s);
                    final hasNumber = RegExp(r'\d').hasMatch(s);
                    if (!hasLetter || !hasNumber)
                      return 'ต้องมีทั้งตัวอักษรและตัวเลข';
                    return null;
                  },
                  onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  onChanged: (_) => setState(() {}), // อัปเดตปุ่ม enable
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  hint: 'Confirm Password',
                  controller: _confirmCtrl,
                  obscure: _obscureConfirm,
                  textInputAction: TextInputAction.done,
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
                  validator: (v) {
                    if ((v ?? '').isEmpty) return 'ยืนยันรหัสผ่านอีกครั้ง';
                    if (v != _passCtrl.text) return 'รหัสผ่านไม่ตรงกัน';
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleNext(),
                  onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 24),

                GradientButton(
                  text: _loading ? 'กำลังตรวจสอบ...' : 'ถัดไป',
                  onTap: _handleNext,
                ),

                const SizedBox(height: 32),

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
      ),
    );
  }

  Future<void> _handleNext() async {
    if (!_autovalidate) setState(() => _autovalidate = true);
    if (!_formValid) return;

    setState(() => _loading = true);
    try {
      final payload = RegisterPayload(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
      );

      if (_role == RegisterRole.rider) {
        Get.to(() => const RiderProfilePage(), arguments: payload);
      } else {
        Get.to(() => const MemberProfilePage(), arguments: payload);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
          style: GoogleFonts.notoSansThai(
            color: fg,
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
