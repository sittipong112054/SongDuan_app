import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/member/member_home_page.dart';
import 'package:songduan_app/pages/register_page.dart';
import 'package:songduan_app/pages/rider/rider_home_page.dart';
import 'package:songduan_app/pages/welcome_page.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';
import 'package:songduan_app/widgets/gradient_button.dart';

class LoginPages extends StatefulWidget {
  const LoginPages({super.key});

  @override
  State<LoginPages> createState() => _LoginPagesState();
}

class _LoginPagesState extends State<LoginPages> {
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _passFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;

  String _baseUrl = '';

  static const _bg = Color(0xFFF6EADB);
  static const _gold = Color(0xFFFF9C00);
  static const _textDark = Color(0xFF2F2F2F);

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['username'] is String) {
      _usernameCtrl.text = args['username'] as String;
    }
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
          splashRadius: 22,
          onPressed: () {
            Get.offAll(() => const WelcomePage());
          },
          tooltip: 'ย้อนกลับ',
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 48),

                        CustomTextField(
                          hint: 'Username หรือ Phone',
                          controller: _usernameCtrl,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(
                            Icons.alternate_email_rounded,
                            size: 28,
                          ),
                          onFieldSubmitted: (_) => _passFocus.requestFocus(),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'กรอกชื่อผู้ใช้';
                            if (value.length < 4)
                              return 'ความยาวอย่างน้อย 4 ตัวอักษร';
                            if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(value)) {
                              return 'ใช้ได้เฉพาะ a-z, 0-9, ., _, -';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // Password
                        CustomTextField(
                          hint: 'Password',
                          controller: _passCtrl,
                          obscure: _obscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          prefixIcon: const Icon(Icons.lock_rounded, size: 28),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_rounded
                                  : Icons.visibility_off_rounded,
                            ),
                            tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                          ),
                          onFieldSubmitted: (_) => _submit(),
                          validator: (v) {
                            final value = v ?? '';
                            if (value.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                            if (value.length < 6)
                              return 'รหัสผ่านอย่างน้อย 6 ตัวอักษร';
                            return null;
                          },
                        ),

                        const Spacer(),
                        // ปุ่มเข้าสู่ระบบ
                        GradientButton(
                          text: _loading
                              ? 'กำลังเข้าสู่ระบบ...'
                              : 'เข้าสู่ระบบ',
                          onTap: _submit,
                        ),
                        const SizedBox(height: 24),

                        // สมัครสมาชิก: เลี่ยง TapGestureRecognizer ใน build
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.nunitoSans(
                                fontSize: 13.5,
                                color: _textDark.withOpacity(0.6),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: _gold,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onPressed: () =>
                                  Get.to(() => const RegisterPage()),
                              child: const Text(
                                'Sign up',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _loading = true);
    FocusScope.of(context).unfocus();

    var config = await Configuration.getConfig();
    _baseUrl = config['apiEndpoint'];

    try {
      final identifier = _usernameCtrl.text.trim();
      final password = _passCtrl.text;

      final uri = Uri.parse('$_baseUrl/users/login');
      final resp = await http
          .post(
            uri,
            headers: const {
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'identifier': identifier, // username หรือ phone
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final text = utf8.decode(resp.bodyBytes);
      final Map<String, dynamic> data = text.isEmpty
          ? <String, dynamic>{}
          : (jsonDecode(text) as Map<String, dynamic>);

      if (resp.statusCode == 200) {
        final role = (data['role'] ?? '').toString().toUpperCase();

        Get.snackbar(
          'สำเร็จ',
          'ยินดีต้อนรับ ${data['username'] ?? identifier}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );

        _goByRole(role, userData: data);
        return;
      }

      // error จาก backend
      final err = data['error'];
      final errMsg = (err is Map && err['message'] is String)
          ? err['message'] as String
          : 'เข้าสู่ระบบไม่สำเร็จ (HTTP ${resp.statusCode})';
      Get.snackbar(
        'ไม่สำเร็จ',
        errMsg,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      Get.snackbar(
        'ไม่สำเร็จ',
        'เกิดข้อผิดพลาด: $e',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

void _goByRole(String role, {required Map<String, dynamic> userData}) {
  switch (role) {
    case 'RIDER':
      Get.offAll(() => const RiderHomePage(), arguments: userData);
      break;
    case 'MEMBER':
      Get.offAll(() => const MemberHomePage(), arguments: userData);
      break;
    default:
      Get.offAll(() => const WelcomePage(), arguments: userData);
      Get.snackbar(
        'คำเตือน',
        'ไม่รู้จักบทบาท ($role) ส่งไปหน้าเริ่มต้น',
        snackPosition: SnackPosition.BOTTOM,
      );
  }
}
