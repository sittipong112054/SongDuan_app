import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/profile_page.dart';
import 'package:songduan_app/widgets/Tab_Button.dart';
import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/profile_header.dart';

class MemberHomePage extends StatefulWidget {
  const MemberHomePage({super.key});

  @override
  State<MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<MemberHomePage> {
  bool _isSender = true;

  String? _baseUrl;
  String? _cfgError;
  bool _loadingCfg = true;

  late final Map<String, dynamic> _user;
  late final String _name;
  late final String _roleLabel;

  final MapController mapController = MapController();
  LatLng latLng = LatLng(16.246373, 103.251827);

  @override
  void initState() {
    super.initState();
    _loadConfig();

    final args = Get.arguments;
    _user = (args is Map<String, dynamic>) ? args : <String, dynamic>{};
    _name = (_user['name'] ?? _user['username'] ?? 'ผู้ใช้').toString();

    final role = (_user['role'] ?? '').toString().toUpperCase();
    _roleLabel = switch (role) {
      'RIDER' => 'Rider',
      'MEMBER' => 'Member',
      _ => 'Member',
    };
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig(); // <- ของคุณ
      setState(() {
        _baseUrl = config['apiEndpoint'] as String?;
        _loadingCfg = false;
      });
    } catch (e) {
      setState(() {
        _cfgError = '$e';
        _loadingCfg = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCfg) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_cfgError != null || _baseUrl == null || _baseUrl!.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'โหลดค่า config ไม่สำเร็จ: ${_cfgError ?? "apiEndpoint ว่าง"}',
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            ProfileHeader(
              name: _name,
              role: _roleLabel,
              image: _user['avatar_path']?.toString().isNotEmpty == true
                  ? _user['avatar_path'] as String
                  : 'assets/images/default_avatar.png',
              baseUrl: _baseUrl,
              onMorePressed: () =>
                  Get.to(() => const ProfilePage(), arguments: _user),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TabButton(
                    text: "ผู้ส่ง",
                    selected: _isSender,
                    onTap: () => setState(() => _isSender = true),
                  ),
                ),
                Expanded(
                  child: TabButton(
                    text: "ผู้รับ",
                    selected: !_isSender,
                    onTap: () => setState(() => _isSender = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Map
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
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
                ), // TODO: แทนด้วย FlutterMap/GoogleMap
              ),
            ),
            const SizedBox(height: 18),

            // Orders info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ข้อมูลไรเดอร์",
                    style: GoogleFonts.nunitoSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(3, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        "${i + 1}. ร้านข้าวมันไก่ → หอมีชัยแมนชั่น",
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Spacer(),

            // Action Button
            GradientButton(
              text: "สร้างสินค้า",
              onTap: () {
                // TODO: ไปหน้า Create Order
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
