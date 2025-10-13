import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/member/map_page.dart';
import 'package:songduan_app/services/api_helper.dart';
import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';
import 'package:songduan_app/widgets/section_title.dart';

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);
  static const _bg = Color(0xFFF6EADB);

  final _formKey = GlobalKey<FormState>();
  final _labelCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  final MapController _mapController = MapController();

  // bool _isDefault = false;
  bool _submitting = false;

  late final int userId;
  int? addressId;

  LatLng _latLng = const LatLng(13.7563, 100.5018);

  String? _baseUrl;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    if (args is Map && args['userId'] != null) {
      userId = int.tryParse(args['userId'].toString()) ?? 0;
    } else {
      userId = 0;
    }

    if (args is Map && args['address'] is Map) {
      final a = Map<String, dynamic>.from(args['address'] as Map);
      addressId =
          int.tryParse(a['id']?.toString() ?? '') ??
          int.tryParse(a['address_id']?.toString() ?? '');
      _labelCtrl.text = (a['label'] ?? '').toString();
      _addressCtrl.text = (a['address_text'] ?? a['full_address'] ?? '')
          .toString();
      final lat = double.tryParse(a['lat']?.toString() ?? '');
      final lng = double.tryParse(a['lng']?.toString() ?? '');
      if (lat != null && lng != null) {
        _latLng = LatLng(lat, lng);
        _latCtrl.text = lat.toStringAsFixed(6);
        _lngCtrl.text = lng.toStringAsFixed(6);
      }
      // _isDefault = a['is_default'] == 1 || a['is_default'] == true;
    }

    _setup();
  }

  Future<void> _setup() async {
    final config = await Configuration.getConfig();
    setState(() {
      _baseUrl = config['apiEndpoint'] as String?;
    });
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          addressId == null ? 'เพิ่มที่อยู่' : 'แก้ไขที่อยู่',
          style: GoogleFonts.notoSansThai(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          onPressed: () => Get.back(result: null),
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
        actions: [
          if (addressId != null)
            IconButton(
              tooltip: 'ลบที่อยู่นี้',
              onPressed: _deleteAddress,
              icon: const Icon(Icons.delete_outline),
              color: Colors.white,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('ข้อมูลที่อยู่'),
                const SizedBox(height: 8),

                CustomTextField(
                  hint: 'ป้ายกำกับ (บ้าน, ที่ทำงาน ฯลฯ)',
                  controller: _labelCtrl,
                  prefixIcon: const Icon(Icons.label_rounded),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกป้ายกำกับ' : null,
                ),
                const SizedBox(height: 10),
                CustomTextField(
                  hint: 'ที่อยู่โดยละเอียด',
                  controller: _addressCtrl,
                  keyboardType: TextInputType.multiline,
                  prefixIcon: const Icon(Icons.map_rounded),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'กรอกรายละเอียดที่อยู่' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hint: 'ละติจูด',
                        controller: _latCtrl,
                        prefixIcon: const Icon(Icons.my_location),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\-\.]'),
                          ),
                        ],
                        validator: _validateLat,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomTextField(
                        hint: 'ลองจิจูด',
                        controller: _lngCtrl,
                        prefixIcon: const Icon(Icons.explore),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9\-\.]'),
                          ),
                        ],
                        validator: _validateLng,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _PickFromMapTile(onTap: _pickFromMap),
                const SizedBox(height: 10),

                SizedBox(
                  height: 180,
                  child: IgnorePointer(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _latLng,
                        initialZoom: 15.0,
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
                              point: _latLng,
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

                // SwitchListTile.adaptive(
                //   title: Text(
                //     'ตั้งเป็นที่อยู่เริ่มต้น',
                //     style: GoogleFonts.notoSansThai(
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                //   value: _isDefault,
                //   onChanged: (v) => setState(() => _isDefault = v),
                // ),
                const SizedBox(height: 14),
                GradientButton(
                  text: _submitting
                      ? 'กำลังบันทึก...'
                      : (addressId == null ? 'บันทึกที่อยู่' : 'อัปเดตที่อยู่'),
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateLat(String? v) {
    final d = double.tryParse((v ?? '').trim());
    if (d == null) return 'ละติจูดไม่ถูกต้อง';
    if (d < -90 || d > 90) return 'ต้องอยู่ระหว่าง -90 ถึง 90';
    return null;
  }

  String? _validateLng(String? v) {
    final d = double.tryParse((v ?? '').trim());
    if (d == null) return 'ลองจิจูดไม่ถูกต้อง';
    if (d < -180 || d > 180) return 'ต้องอยู่ระหว่าง -180 ถึง 180';
    return null;
  }

  Future<void> _pickFromMap() async {
    final result = await Get.to(() => const MapPickPage());
    if (result != null && result is Map && result['latlng'] is LatLng) {
      final LatLng picked = result['latlng'] as LatLng;
      setState(() {
        _latLng = picked;
        _latCtrl.text = picked.latitude.toStringAsFixed(6);
        _lngCtrl.text = picked.longitude.toStringAsFixed(6);
      });
      _mapController.move(picked, 16.0);
      if (result['address'] is String) {
        final s = (result['address'] as String).trim();
        if (s.isNotEmpty && _addressCtrl.text.trim().isEmpty) {
          _addressCtrl.text = s;
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      final cfg = await Configuration.getConfig();
      _baseUrl = cfg['apiEndpoint'];
    }

    if (userId <= 0) {
      Get.snackbar('ข้อมูลไม่ครบ', 'userId ไม่ถูกต้อง');
      return;
    }

    final label = _labelCtrl.text.trim();
    final addr = _addressCtrl.text.trim();
    final lat = double.parse(_latCtrl.text.trim());
    final lng = double.parse(_lngCtrl.text.trim());

    setState(() => _submitting = true);

    try {
      http.Response resp;

      final payload = {
        'label': label,
        'address_text': addr,
        'lat': lat,
        'lng': lng,
      };

      if (addressId == null) {
        final uri = Uri.parse('$_baseUrl/addresses/$userId');
        resp = await http
            .post(uri, headers: await authHeaders(), body: jsonEncode(payload))
            .timeout(const Duration(seconds: 15));
      } else {
        final uri = Uri.parse('$_baseUrl/addresses/$addressId');
        resp = await http
            .patch(uri, headers: await authHeaders(), body: jsonEncode(payload))
            .timeout(const Duration(seconds: 15));
      }

      handleAuthErrorIfAny(resp);

      final json = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        Get.back(result: json['data']);
        Get.snackbar(
          'สำเร็จ',
          addressId == null ? 'เพิ่มที่อยู่แล้ว' : 'อัปเดตที่อยู่แล้ว',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final msg = json is Map && json['error'] != null
            ? (json['error']['message'] ?? 'เกิดข้อผิดพลาด')
            : 'HTTP ${resp.statusCode}';
        throw Exception(msg);
      }
    } catch (e) {
      Get.snackbar('ผิดพลาด', '$e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteAddress() async {
    if (addressId == null) return;
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      final cfg = await Configuration.getConfig();
      _baseUrl = cfg['apiEndpoint'];
    }

    final ok = await showConfirmDeleteAddressDialog();
    if (!ok) return;

    try {
      final uri = Uri.parse('$_baseUrl/addresses/$addressId');
      final resp = await http
          .delete(uri, headers: await authHeaders())
          .timeout(const Duration(seconds: 15));

      handleAuthErrorIfAny(resp);

      if (resp.statusCode == 204) {
        Get.back(result: {'deleted': true, 'id': addressId});
        Get.snackbar(
          'ลบแล้ว',
          'ลบที่อยู่เรียบร้อย',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        final json = jsonDecode(utf8.decode(resp.bodyBytes));
        final msg = json is Map && json['error'] != null
            ? (json['error']['message'] ?? 'เกิดข้อผิดพลาด')
            : 'HTTP ${resp.statusCode}';
        throw Exception(msg);
      }
    } catch (e) {
      Get.snackbar('ผิดพลาด', '$e', snackPosition: SnackPosition.BOTTOM);
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
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: const [
              Icon(Icons.maps_home_work_sharp, size: 26, color: Colors.black54),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'เลือกตำแหน่งจากแผนที่',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black54,
                  ),
                ),
              ),
              Icon(
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

Future<bool> showConfirmDeleteAddressDialog() async {
  final result = await Get.dialog<bool>(
    Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final cs = theme.colorScheme;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_forever_rounded,
                    size: 28,
                    color: cs.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ลบที่อยู่',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'ต้องการลบที่อยู่นี้หรือไม่?\nการลบไม่สามารถย้อนกลับได้',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('ยกเลิก'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Get.back(result: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.error,
                          foregroundColor: cs.onError,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('ลบ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    ),
    barrierDismissible: false,
  );

  return result == true;
}
