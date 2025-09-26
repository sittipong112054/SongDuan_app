import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/pages/member/map_page.dart';

import 'package:songduan_app/widgets/custom_text_field.dart';
import 'package:songduan_app/widgets/gradient_button.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _placeNameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // static const _bg = Color(0xFFF6EADB);
  // static const _textDark = Color(0xFF2F2F2F);
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

  final MapController mapController = MapController();
  LatLng latLng = LatLng(16.246373, 103.251827);

  @override
  void dispose() {
    _placeNameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6EADB),
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        title: Text(
          'เพิ่มที่อยู่',
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ชื่อของที่อยู่
              _SectionTitle('ชื่อของที่อยู่'),
              const SizedBox(height: 8),
              CustomTextField(
                hint: 'เช่น บ้านเลขที่, ที่ทำงาน',
                controller: _placeNameCtrl,
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 18),

              // ที่อยู่
              _SectionTitle('ที่อยู่'),
              const SizedBox(height: 8),
              _PickFromMapTile(onTap: _goPickOnMap),
              const SizedBox(height: 10),

              SizedBox(
                height: 200,
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: latLng,
                    initialZoom: 15.2,
                    onTap: (tapPosition, point) {
                      log(point.toString());
                    },
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
                          child: Icon(Icons.location_on, color: Colors.red),
                        ),
                        Marker(
                          point: LatLng(16.24099, 103.254331),
                          child: Icon(Icons.location_on, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SizedBox(height: 28),

              // ปุ่มลงทะเบียน
              SizedBox(
                height: 56,
                child: GradientButton(
                  text: 'ยืนยันเพิ่มที่อยู่',
                  onTap: _submit,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _goPickOnMap() {
    Get.to(() => MapPickPage());
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'บันทึกที่อยู่: ${_placeNameCtrl.text}',
          style: GoogleFonts.notoSansThai(),
        ),
      ),
    );
  }
}

// ---------------- Widgets ย่อย ----------------

class _SectionTitle extends StatelessWidget {
  // ignore: unused_element_parameter
  const _SectionTitle(this.text, {this.top = 0});
  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Text(
        text,
        style: GoogleFonts.notoSansThai(
          fontSize: 16.5,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF2F2F2F),
        ),
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
                Icons.photo_camera_back_rounded,
                size: 26,
                color: Colors.black54,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'เลือกจากแผนที่',
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
