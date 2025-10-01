import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:songduan_app/config/config.dart';

import 'package:songduan_app/models/register_payload.dart';
import 'package:songduan_app/pages/login_page.dart';
import 'package:songduan_app/pages/member/map_page.dart';

import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';
import 'package:songduan_app/widgets/section_title.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key});

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  late final RegisterPayload base;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _placeNameCtrl = TextEditingController();
  final _addressNameCtrl = TextEditingController();

  File? _avatarFile;
  final _picker = ImagePicker();

  String? _selectedAddress;

  final MapController mapController = MapController();
  LatLng latLng = LatLng(16.246373, 103.251827);

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
    _placeNameCtrl.dispose();
    _addressNameCtrl.dispose();
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

                const SectionTitle('ข้อมูลติดต่อ'),
                const SizedBox(height: 8),

                CustomTextField(
                  hint: 'ชื่อ',
                  controller: _nameCtrl,
                  prefixIcon: const Icon(Icons.person_rounded, size: 28),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกชื่อ' : null,
                ),

                const SizedBox(height: 8),

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
                    // ตัวอย่างรูปแบบเบอร์ไทย 10 หลักขึ้นต้น 0
                    return RegExp(r'^0\d{9}$').hasMatch(s)
                        ? null
                        : 'รูปแบบเบอร์ไม่ถูกต้อง';
                  },
                ),

                const SizedBox(height: 18),

                const SectionTitle('ข้อมูลที่อยู่'),
                const SizedBox(height: 8),

                CustomTextField(
                  hint: 'ชื่อที่อยู่, ที่ทำงาน',
                  controller: _placeNameCtrl,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.home, size: 28),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกชื่อที่อยู่' : null,
                ),
                const SizedBox(height: 8),

                CustomTextField(
                  hint: 'บ้านเลขที่ หมู่บ้าน ตำบล อำเภอ จังหวัด ประเทศ',
                  controller: _addressNameCtrl,
                  keyboardType: TextInputType.text,
                  prefixIcon: const Icon(Icons.map, size: 28),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกรายละเอียดที่อยู่' : null,
                ),
                const SizedBox(height: 8),

                _PickFromMapTile(onTap: _goPickOnMap),
                const SizedBox(height: 10),

                if (_selectedAddress != null) ...[
                  SizedBox(
                    height: 200,
                    child: IgnorePointer(
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: latLng,
                          initialZoom: 15.2,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=0b03b55da9a64adab5790c1c9515b15a',
                            userAgentPackageName: 'net.gonggang.osm_demo',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: latLng,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // const SizedBox(height: 8),
                  // Text(
                  //   _selectedAddress!,
                  //   style: GoogleFonts.notoSansThai(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w700,
                  //     color: Colors.black.withOpacity(0.7),
                  //   ),
                  // ),
                ],

                const SizedBox(height: 18),

                GradientButton(
                  text: _submitting ? 'กำลังลงทะเบียน...' : 'ลงทะเบียน',
                  onTap: _onSubmit,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _goPickOnMap() async {
    final result = await Get.to(() => const MapPickPage());
    if (result != null && result is Map && result['latlng'] is LatLng) {
      final LatLng picked = result['latlng'] as LatLng;
      final String? addr = result['address'] as String?;

      setState(() {
        latLng = picked;
        _selectedAddress = addr;

        if (_addressNameCtrl.text.trim().isEmpty && addr != null) {
          _addressNameCtrl.text = addr;
        }
      });

      mapController.move(picked, 16.0);
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;
      final out = File('${file.path}_c.jpg');
      await out.writeAsBytes(img.encodeJpg(decoded, quality: 80));
      return out;
    } catch (_) {
      return file;
    }
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x != null) {
      var f = File(x.path);
      f = await _compressImage(f) ?? f;
      if (!mounted) return;
      setState(() => _avatarFile = f);
    }
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedAddress == null) {
      Get.snackbar(
        'ที่อยู่',
        'กรุณาเลือกตำแหน่งจากแผนที่',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_avatarFile == null) {
      Get.snackbar(
        'รูปโปรไฟล์',
        'กรุณาเลือกรูปภาพโปรไฟล์',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _submitting = true);
    var config = await Configuration.getConfig();
    _baseUrl = config['apiEndpoint'];
    try {
      final uri = Uri.parse('$_baseUrl/users/members');
      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'username': base.username,
        'password': base.password,
        'role': 'MEMBER',
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'placeName': _placeNameCtrl.text.trim(),
        'address': _addressNameCtrl.text.trim(),
        'lat': latLng.latitude.toString(),
        'lng': latLng.longitude.toString(),
      });

      if (_avatarFile != null) {
        final file = _avatarFile!;
        final fileName = p.basename(file.path);
        final mime = lookupMimeType(file.path) ?? 'image/jpeg';
        final parts = mime.split('/');

        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        request.files.add(
          http.MultipartFile(
            'avatarFile',
            stream,
            length,
            filename: fileName,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      // request.headers['Authorization'] = 'Bearer ...';

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
          'สมัครสมาชิกเรียบร้อย',
          snackPosition: SnackPosition.BOTTOM,
        );

        _nameCtrl.clear();
        _phoneCtrl.clear();
        _placeNameCtrl.clear();
        _addressNameCtrl.clear();

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

class _PickFromMapTile extends StatelessWidget {
  const _PickFromMapTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(14),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              const Icon(
                Icons.maps_home_work_sharp,
                size: 26,
                color: Colors.black54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'เลือกตำแหน่งจากแผนที่',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
