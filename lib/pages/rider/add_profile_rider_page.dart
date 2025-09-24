import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ถ้าใช้ image_picker ให้เพิ่ม dependency แล้ว uncomment ส่วนที่เกี่ยวข้อง
import 'package:image_picker/image_picker.dart';
import 'package:songduan_app/pages/rider/rider_home_page.dart';

import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';

class RiderProfilePage extends StatefulWidget {
  const RiderProfilePage({super.key});

  @override
  State<RiderProfilePage> createState() => _RiderProfilePageState();
}

class _RiderProfilePageState extends State<RiderProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _plateCtrl = TextEditingController(text: '');

  File? _avatarFile;
  File? _vehicleFile;

  final _picker = ImagePicker();

  static const _bg = Color(0xFFF6EADB);
  // static const _textDark = Color(0xFF2F2F2F);
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _plateCtrl.dispose();
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
                      backgroundColor: Color(0xFFF0F2F5),
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
              ),
              const SizedBox(height: 12),

              CustomTextField(
                hint: 'เบอร์โทร',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.call_rounded, size: 28),
              ),

              const SizedBox(height: 18),

              _SectionTitle('ข้อมูลยานพาหนะ'),
              const SizedBox(height: 8),

              CustomTextField(
                hint: 'License plate : กข-1234',
                controller: _plateCtrl,
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(Icons.local_shipping_rounded, size: 28),
              ),

              const SizedBox(height: 14),

              _VehiclePictureBox(
                file: _vehicleFile,
                onPick: _pickVehiclePicture,
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 56,
                child: GradientButton(text: 'ลงทะเบียน', onTap: _onSubmit),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _avatarFile = File(x.path));
  }

  Future<void> _pickVehiclePicture() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _vehicleFile = File(x.path));
  }

  void _onSubmit() {
    Get.to(() => RiderHomePage());
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
