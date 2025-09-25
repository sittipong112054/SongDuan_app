import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/pages/member/map_page.dart';
import 'package:songduan_app/pages/rider/rider_home_page.dart';

import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key});

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _placeNameCtrl = TextEditingController();
  final _addressNameCtrl = TextEditingController();

  File? _avatarFile;
  final _picker = ImagePicker();

  String? _selectedAddress;

  final MapController mapController = MapController();
  LatLng latLng = LatLng(16.246373, 103.251827);

  static const _bg = Color(0xFFF6EADB);
  // static const _textDark = Color(0xFF2F2F2F);
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

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

              _SectionTitle('ข้อมูลที่อยู่'),
              const SizedBox(height: 8),

              CustomTextField(
                hint: 'ชื่อที่อยู่, ที่ทำงาน',
                controller: _placeNameCtrl,
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(Icons.home, size: 28),
              ),
              const SizedBox(height: 8),

              CustomTextField(
                hint: 'บ้านเลขที่ หมู่บ้าน ตำบล อำเภอ จังหวัด ประเทศ',
                controller: _addressNameCtrl,
                keyboardType: TextInputType.text,
                prefixIcon: const Icon(Icons.map, size: 28),
              ),
              const SizedBox(height: 8),

              _PickFromMapTile(onTap: _goPickOnMap),
              const SizedBox(height: 10),

              if (_selectedAddress != null) ...[
                SizedBox(
                  height: 200,
                  child: IgnorePointer(
                    // หรือ AbsorbPointer()
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

                const SizedBox(height: 8),
                Text(
                  _selectedAddress!,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 18),
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

      // สำคัญ: initialCenter ใช้แค่ครั้งแรก ต้อง move ด้วย controller
      mapController.move(picked, 16.0);
    }
  }

  Future<void> _pickAvatar() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _avatarFile = File(x.path));
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
