import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;

import 'package:songduan_app/widgets/gradient_button.dart';

class MapPickPage extends StatefulWidget {
  const MapPickPage({super.key});

  @override
  State<MapPickPage> createState() => _MapPickPageState();
}

class _MapPickPageState extends State<MapPickPage> {
  final MapController _mapController = MapController();

  final LatLng _fallbackCenter = const LatLng(13.7563, 100.5018);
  LatLng _currentCenter = const LatLng(13.7563, 100.5018);

  LatLng? _picked;
  String? _pickedAddress;

  final TextEditingController _searchCtrl = TextEditingController();

  static const _apiKey = '0b03b55da9a64adab5790c1c9515b15a';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // -------------- GPS init --------------
  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentCenter = _fallbackCenter);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _currentCenter = _fallbackCenter);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final gps = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _currentCenter = gps;
        _picked = gps;
      });

      _mapController.move(gps, 15);
      await _reverseGeocode(gps);
    } catch (_) {
      setState(() => _currentCenter = _fallbackCenter);
    }
  }

  // -------------- Reverse geocoding เมื่อผู้ใช้แตะ --------------
  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final placemarks = await gc.placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final pieces = [
          p.name,
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((e) => (e ?? '').trim().isNotEmpty).map((e) => e!.trim());

        setState(() => _pickedAddress = pieces.join(' · '));
      } else {
        setState(() => _pickedAddress = null);
      }
    } catch (_) {
      setState(() => _pickedAddress = null);
    }
  }

  // -------------- Forward geocoding จากช่องค้นหา --------------
  Future<void> _searchAddress() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    try {
      final results = await gc.locationFromAddress(query);
      if (results.isNotEmpty) {
        final r = results.first;
        final dest = LatLng(r.latitude, r.longitude);
        _mapController.move(dest, 16);
        setState(() {
          _picked = dest;
        });
        // แปลงเป็นที่อยู่ให้อ่านง่าย
        await _reverseGeocode(dest);
      }
    } catch (e) {
      // สะกิดผู้ใช้แบบเบา ๆ
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('หาไม่เจอ ลองพิมพ์ให้เฉพาะเจาะจงขึ้นหน่อยค่ะ')),
      );
    }
  }

  // ปุ่มพากล้องกลับมายังตำแหน่งฉัน
  Future<void> _goToMyLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final me = LatLng(pos.latitude, pos.longitude);
      _mapController.move(me, 16);
      setState(() {
        _picked = me;
      });
      await _reverseGeocode(me);
    } catch (_) {
      // เงียบ ๆ ก็ได้
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 14,
              onTap: (tapPosition, point) async {
                setState(() {
                  _picked = point;
                  _pickedAddress = null; // เคลียร์ก่อนค่อยโหลดใหม่
                });
                await _reverseGeocode(point);
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

          // Search bar + back + my location
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: const InputDecoration(
                                hintText: 'ค้นหาที่อยู่หรือชื่ออาคาร',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchAddress(),
                            ),
                          ),
                          if (_searchCtrl.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.my_location, size: 20),
                      onPressed: _goToMyLocation,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom sheet แสดงผลลัพธ์
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
                  if (_picked != null) ...[
                    Text(
                      'Lat: ${_picked!.latitude.toStringAsFixed(6)}, Lng: ${_picked!.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _pickedAddress ?? 'กำลังดึงที่อยู่...',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withOpacity(0.9),
                      ),
                    ),
                  ] else
                    Text(
                      'แตะเลือกตำแหน่งบนแผนที่ หรือพิมพ์ค้นหา',
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
                          // ส่งทั้งพิกัดและที่อยู่กลับ
                          Get.back(
                            result: {
                              'latlng': _picked,
                              'address': _pickedAddress,
                            },
                          );
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}
