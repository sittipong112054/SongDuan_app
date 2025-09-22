import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:songduan_app/widgets/gradient_button.dart';

class MapPickPage extends StatefulWidget {
  const MapPickPage({super.key});

  @override
  State<MapPickPage> createState() => _MapPickPageState();
}

class _MapPickPageState extends State<MapPickPage> {
  // กำหนดตำแหน่งเริ่มต้น
  final LatLng _center = LatLng(13.7563, 100.5018); // Bangkok
  LatLng? _picked;

  static const _apiKey =
      '0b03b55da9a64adab5790c1c9515b15a'; // ใส่ API key ของ Thunderforest

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 13,
              onTap: (tapPosition, point) {
                setState(() => _picked = point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.thunderforest.com/cycle/{z}/{x}/{y}.png?apikey=$_apiKey',
                userAgentPackageName: 'com.example.app',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Search bar mock (ยังไม่เชื่อม geocoding)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      onPressed: () => Get.back(),
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ค้นหาที่อยู่หรือชื่ออาคาร',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ที่อยู่จัดส่ง',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _picked != null
                        ? 'Lat: ${_picked!.latitude}, Lng: ${_picked!.longitude}'
                        : 'แตะเลือกตำแหน่งบนแผนที่',
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: GradientButton(
                      text: 'ยืนยันที่อยู่จัดส่ง',
                      onTap: () {
                        if (_picked != null) {
                          Get.back(result: _picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
