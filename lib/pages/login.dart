import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPages extends StatefulWidget {
  const LoginPages({super.key});

  @override
  State<LoginPages> createState() => _LoginPagesState();
}

class _LoginPagesState extends State<LoginPages> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  // โทนสี
  static const _bg = Color(0xFFF6EADB);
  static const _orange = Color(0xFFFF7A00);
  // static const _gold = Color(0xFFFFB52E);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: _textDark.withOpacity(0.85),
                onPressed: () => Navigator.maybePop(context),
                padding: EdgeInsets.zero,
                splashRadius: 22,
              ),
              const SizedBox(height: 8),

              // โลโก้
              Center(
                child: Container(
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
                    'assets/images/logo.png', // TODO: เปลี่ยนพาธให้ตรงกับโปรเจกต์
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // หัวข้อ
              Center(
                child: Text(
                  'Login To Your Account',
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
              const SizedBox(height: 80),

              // Email
              _ShadowField(
                child: TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.nunitoSans(fontSize: 16),
                  decoration: _inputDecoration(
                    hint: 'Email',
                    prefix: const Icon(Icons.alternate_email_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Password
              _ShadowField(
                child: TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  style: GoogleFonts.nunitoSans(fontSize: 16),
                  decoration: _inputDecoration(
                    hint: 'Password',
                    prefix: const Icon(Icons.lock_rounded),
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 100),

              // ปุ่มเข้าสู่ระบบ (Gradient)
              _GradientButton(text: 'เข้าสู่ระบบ', onTap: _onLogin),
              const SizedBox(height: 20),

              // Sign up link
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
                          color: _orange,
                        ),
                        // ไปหน้า Register
                        recognizer: (TapGestureRecognizer()
                          ..onTap = () {
                            // Navigator.pushNamed(context, '/register');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ไปหน้า Sign up')),
                            );
                          }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  static InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF0F2F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      hintStyle: GoogleFonts.nunitoSans(
        color: Colors.black.withOpacity(0.35),
        fontWeight: FontWeight.w700,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _onLogin() {
    // TODO: call API / validate / navigate
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'กำลังเข้าสู่ระบบด้วย ${_emailCtrl.text}',
          style: GoogleFonts.nunitoSans(),
        ),
      ),
    );
  }
}

// กล่องเงาเหมือนการ์ดของ TextField
class _ShadowField extends StatelessWidget {
  const _ShadowField({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ปุ่มไล่เฉดส้ม–ทอง
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [_orange, _gold],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.nunitoSans(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
