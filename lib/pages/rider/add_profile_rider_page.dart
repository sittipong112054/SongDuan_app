import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:songduan_app/config/config.dart';

import 'package:songduan_app/models/register_payload.dart';
import 'package:songduan_app/pages/login_page.dart';
import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';

class RiderProfilePage extends StatefulWidget {
  const RiderProfilePage({super.key});

  @override
  State<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  late final RegisterPayload base;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController(text: '');
  final _modelCtrl = TextEditingController(text: '');

  File? _avatarFile;
  File? _vehicleFile;

  final _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  static const _bg = Color(0xFFF6EADB);
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

  String _baseUrl = '';

  @override
  void initState() {
    super.initState();
    base = Get.arguments as RegisterPayload;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'กรอกข้อมูลเพิ่มเติม',
          style: GoogleFonts.notoSansThai(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_orange, _gold],
            ),
          ),
        ),
        backgroundColor: _orange,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 6),

                // Avatar + edit
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 78,
                        backgroundColor: const Color(0xFFF0F2F5),
                        child: ClipOval(
                          child: SizedBox(
                            width: 148,
                            height: 148,
                            child: _avatarFile != null
                                ? Image.file(_avatarFile!, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      'Add\nPhoto',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.notoSansThai(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black.withOpacity(0.4),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                _SectionTitle('ข้อมูลติดต่อ'),
                const SizedBox(height: 8),

                CustomTextField(
                  hint: 'ชื่อ',
                  controller: _nameCtrl,
                  keyboardType: TextInputType.name,
                  prefixIcon: const Icon(Icons.person_rounded, size: 28),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกชื่อ' : null,
                ),
                const SizedBox(height: 12),

                CustomTextField(
                  hint: 'เบอร์โทร',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.call_rounded, size: 28),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (v) {
                    final s = (v ?? '').trim();
                    return RegExp(r'^0\d{9}$').hasMatch(s)
                        ? null
                        : 'รูปแบบเบอร์ไม่ถูกต้อง';
                  },
                ),

                const SizedBox(height: 18),

                _SectionTitle('ข้อมูลยานพาหนะ'),
                const SizedBox(height: 8),

                CustomTextField(
                  hint: 'ยี่ห้อ เช่น Honda Wave 110i',
                  controller: _modelCtrl,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(
                    Icons.local_shipping_rounded,
                    size: 28,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกยี่ห้อรถ' : null,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  hint: 'ทะเบียนรถ เช่น 1กข-1234',
                  controller: _plateCtrl,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(
                    Icons.local_shipping_rounded,
                    size: 28,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกทะเบียนรถ' : null,
                ),

                const SizedBox(height: 14),

                _VehiclePictureBox(
                  file: _vehicleFile,
                  onPick: _pickVehiclePicture,
                ),

                const SizedBox(height: 30),

                SizedBox(
                  height: 56,
                  child: GradientButton(
                    text: _submitting ? 'กำลังลงทะเบียน...' : 'ลงทะเบียน',
                    onTap: _onSubmit,
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) setState(() => _avatarFile = File(x.path));
  }

  Future<void> _pickVehiclePicture() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) setState(() => _vehicleFile = File(x.path));
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // บังคับให้มีภาพทั้งสอง
    if (_avatarFile == null) {
      Get.snackbar(
        'รูปโปรไฟล์',
        'กรุณาเลือกรูปภาพโปรไฟล์',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (_vehicleFile == null) {
      Get.snackbar(
        'รูปรถ',
        'กรุณาเลือกรูปรถ',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _submitting = true);

    var config = await Configuration.getConfig();
    _baseUrl = config['apiEndpoint'];

    try {
      final uri = Uri.parse('$_baseUrl/users/riders');
      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'username': base.username,
        'password': base.password,
        'role': 'RIDER',
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'vehicle_model': _modelCtrl.text.trim(),
        'vehicle_plate': _plateCtrl.text.trim(),
      });

      final avatar = _avatarFile!;
      final avatarName = p.basename(avatar.path);
      final avatarMime = lookupMimeType(avatar.path) ?? 'image/jpeg';
      final avatarParts = avatarMime.split('/');

      request.files.add(
        http.MultipartFile(
          'avatarFile',
          http.ByteStream(avatar.openRead()),
          await avatar.length(),
          filename: avatarName,
          contentType: MediaType(avatarParts[0], avatarParts[1]),
        ),
      );

      // แนบไฟล์ vehicle
      final vehicle = _vehicleFile!;
      final vehicleName = p.basename(vehicle.path);
      final vehicleMime = lookupMimeType(vehicle.path) ?? 'image/jpeg';
      final vehicleParts = vehicleMime.split('/');

      request.files.add(
        http.MultipartFile(
          'vehiclePhotoFile',
          http.ByteStream(vehicle.openRead()),
          await vehicle.length(),
          filename: vehicleName,
          contentType: MediaType(vehicleParts[0], vehicleParts[1]),
        ),
      );

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final resp = await http.Response.fromStream(streamed);

      Map<String, dynamic> body;
      try {
        body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      } catch (_) {
        throw Exception(
          'Invalid response: ${resp.statusCode} ${resp.reasonPhrase}',
        );
      }

      if (resp.statusCode == 201) {
        Get.snackbar(
          'สำเร็จ',
          'สมัคร Rider เรียบร้อย',
          snackPosition: SnackPosition.BOTTOM,
        );

        _nameCtrl.clear();
        _phoneCtrl.clear();
        _modelCtrl.clear();
        _plateCtrl.clear();

        Get.offAll(
          () => const LoginPages(),
          arguments: {'username': base.username},
          transition: Transition.fadeIn,
          duration: const Duration(milliseconds: 220),
        );
        return;
      }

      final err = body['error'];
      if (err is Map && err['message'] is String) {
        throw Exception(
          '[${err['code'] ?? resp.statusCode}] ${err['message']}',
        );
      }
      throw Exception('HTTP ${resp.statusCode}: ${resp.reasonPhrase}');
    } catch (e) {
      Get.snackbar('เกิดข้อผิดพลาด', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.notoSansThai(
        fontSize: 16.5,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF2F2F2F),
      ),
    );
  }
}

class _VehiclePictureBox extends StatelessWidget {
  const _VehiclePictureBox({required this.file, required this.onPick});

  final File? file;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hint = Text(
      'Picture of vehicle',
      style: GoogleFonts.notoSansThai(
        color: Colors.black.withOpacity(0.25),
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );

    final content = file == null
        ? Center(child: hint)
        : ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              file!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 170,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                offset: const Offset(0, 6),
                blurRadius: 10,
              ),
            ],
          ),
          child: content,
        ),
        Positioned(
          right: 6,
          bottom: 6,
          child: GestureDetector(
            onTap: onPick,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
