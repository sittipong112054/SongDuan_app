import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/login_page.dart';
import 'package:songduan_app/pages/member/add_location_page.dart';
import 'package:songduan_app/services/session_service.dart';
import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/services/api_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _textDark = Color(0xFF2F2F2F);
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

  String? _baseUrl;

  late final Map<String, dynamic> user;
  late final String userId;
  late final String name;
  late final String username; // <-- เพิ่ม
  late final String roleLabel;
  late final bool isRider;
  late final String phone;
  late final String? avatarPath;

  List<Map<String, dynamic>> _addresses = [];
  bool _isLoadingAddresses = false;
  String? _addrError;

  Map<String, dynamic>? _vehicle;
  bool _isLoadingVehicle = false;
  String? _vehicleError;

  @override
  void initState() {
    super.initState();

    final args = Get.arguments;
    user = (args is Map<String, dynamic>) ? args : <String, dynamic>{};

    userId = (user['id'] ?? user['user_id'] ?? '').toString();
    name = (user['name'] ?? user['username'] ?? 'ผู้ใช้').toString();
    username = (user['username'] ?? 'ไม่ระบุ').toString();

    final role = (user['role'] ?? '').toString().toUpperCase();
    roleLabel = switch (role) {
      'RIDER' => 'Rider',
      'MEMBER' => 'Member',
      _ => 'User',
    };
    isRider = roleLabel == 'Rider';

    phone = (user['phone'] ?? '-').toString();
    avatarPath = user['avatar_path']?.toString();

    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
      setState(() {
        _baseUrl = config['apiEndpoint'] as String?;
      });
      if (!mounted) return;

      if (isRider) {
        await _fetchVehicle();
      } else {
        await _fetchAddresses();
      }
    } catch (_) {}
  }

  Future<void> _fetchAddresses() async {
    if ((_baseUrl ?? '').isEmpty || userId.isEmpty) {
      setState(() {
        _addrError = 'ตั้งค่าไม่ครบ (baseUrl หรือ userId ว่าง)';
      });
      return;
    }

    setState(() {
      _isLoadingAddresses = true;
      _addrError = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/addresses/$userId');

      final res = await http.get(uri, headers: await authHeaders());
      handleAuthErrorIfAny(res);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);

        final list = (data is Map && data['data'] is List)
            ? (data['data'] as List)
            : (data is List ? data : const []);

        final addrs = list
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .cast<Map<String, dynamic>>()
            .toList();

        setState(() {
          _addresses = addrs;
        });
      } else {
        setState(() {
          _addrError = 'โหลดที่อยู่ไม่สำเร็จ (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _addrError = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddresses = false;
        });
      }
    }
  }

  Future<void> _fetchVehicle() async {
    if ((_baseUrl ?? '').isEmpty || userId.isEmpty) {
      setState(() {
        _vehicleError = 'ตั้งค่าไม่ครบ (baseUrl หรือ userId ว่าง)';
      });
      return;
    }

    setState(() {
      _isLoadingVehicle = true;
      _vehicleError = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/riders/vehicles/$userId');

      final res = await http.get(uri, headers: await authHeaders());
      handleAuthErrorIfAny(res);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final obj = (data is Map && data['data'] is Map)
            ? Map<String, dynamic>.from(data['data'])
            : (data is Map ? Map<String, dynamic>.from(data) : null);

        setState(() {
          _vehicle = obj;
        });
      } else {
        setState(() {
          _vehicleError = 'โหลดข้อมูลยานพาหนะไม่สำเร็จ (${res.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _vehicleError = 'เกิดข้อผิดพลาดในการเชื่อมต่อ';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVehicle = false;
        });
      }
    }
  }

  ImageProvider _resolveAvatar(String? s) {
    if (s == null || s.trim().isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    final val = s.trim();

    if (val.startsWith('/')) {
      final b = (_baseUrl ?? '').trimRight();
      if (b.isNotEmpty) return NetworkImage('$b$val');
      return const AssetImage('assets/images/default_avatar.png');
    }

    return AssetImage(val);
  }

  ImageProvider? _resolveVehicleImage(Map<String, dynamic> v) {
    final raw =
        (v['image'] ??
                v['image_url'] ??
                v['imagePath'] ??
                v['image_path'] ??
                v['picture'] ??
                '')
            .toString()
            .trim();

    if (raw.isEmpty) return null;

    if (raw.startsWith('/')) {
      final b = (_baseUrl ?? '').trimRight();
      if (b.isNotEmpty) return NetworkImage('$b$raw');
      return null;
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return NetworkImage(raw);
    }
    return AssetImage(raw);
  }

  Future<void> _onRefresh() async {
    if (isRider) {
      await _fetchVehicle();
    } else {
      await _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = MediaQuery.of(context).size.width / 3;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profile',
          style: GoogleFonts.notoSansThai(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
          onPressed: () => Get.back(),
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
      backgroundColor: Colors.white,

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundImage: _resolveAvatar(avatarPath),
                      backgroundColor: Colors.grey.shade300,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                        // <-- แสดง username ใต้ชื่อ
                        Text(
                          '@$username',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.55),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          roleLabel,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.45),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Text(
                'ข้อมูลส่วนตัว',
                style: GoogleFonts.notoSansThai(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              _ReadOnlyField(hint: 'Name', value: name),
              const SizedBox(height: 10),
              _ReadOnlyField(hint: 'Username', value: username), // <-- เพิ่ม
              const SizedBox(height: 10),
              _ReadOnlyField(hint: 'Phone Number', value: phone),

              const SizedBox(height: 18),

              if (isRider) ...[
                Text(
                  'ข้อมูลยานพาหนะ',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 10),

                if (_isLoadingVehicle) ...[
                  const _AddressSkeleton(),
                ] else if (_vehicleError != null) ...[
                  _ErrorTile(message: _vehicleError!, onRetry: _fetchVehicle),
                ] else if (_vehicle != null) ...[
                  _ReadOnlyField(
                    hint: 'Vehicle model',
                    value:
                        (_vehicle!['vehicle_model'] ??
                                _vehicle!['model'] ??
                                _vehicle!['brand_model'] ??
                                '-')
                            .toString(),
                  ),
                  const SizedBox(height: 10),
                  _ReadOnlyField(
                    hint: 'License plate',
                    value:
                        (_vehicle!['license_plate'] ??
                                _vehicle!['plate'] ??
                                _vehicle!['registration'] ??
                                '-')
                            .toString(),
                  ),
                  const SizedBox(height: 10),
                  _VehiclePictureBox(
                    imageProvider: _resolveVehicleImage(_vehicle!),
                  ),
                ] else ...[
                  _AddressTile(
                    title: '—',
                    subtitle: 'ยังไม่มีข้อมูลยานพาหนะ',
                    onTap: null,
                  ),
                ],
              ] else ...[
                Row(
                  children: [
                    Text(
                      'ที่อยู่',
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        final created = await Get.to(
                          () => const AddLocationPage(),
                          arguments: {'userId': userId},
                        );

                        if (created != null) {
                          await _fetchAddresses();
                        }
                      },
                      child: Text(
                        'เพิ่มที่อยู่',
                        style: GoogleFonts.notoSansThai(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFF9C00),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_isLoadingAddresses) ...[
                  const _AddressSkeleton(),
                  const SizedBox(height: 10),
                  const _AddressSkeleton(),
                ] else if (_addrError != null) ...[
                  _ErrorTile(message: _addrError!, onRetry: _fetchAddresses),
                ] else if (_addresses.isNotEmpty) ...[
                  ..._addresses.map((addr) {
                    final title = (addr['label'] ?? 'ที่อยู่').toString();
                    final subtitle =
                        (addr['address_text'] ??
                                addr['full_address'] ??
                                addr['line'] ??
                                '')
                            .toString();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AddressTile(
                        title: title,
                        subtitle: subtitle,
                        onTap: () async {
                          final updated = await Get.to(
                            () => const AddLocationPage(),
                            arguments: {'userId': userId, 'address': addr},
                          );

                          if (updated != null && updated is Map) {
                            final id = updated['id'] ?? updated['address_id'];
                            setState(() {
                              final idx = _addresses.indexWhere(
                                (e) => (e['id'] ?? e['address_id']) == id,
                              );
                              if (idx >= 0) {
                                _addresses[idx] = Map<String, dynamic>.from(
                                  updated,
                                );
                              } else {
                                _addresses.insert(
                                  0,
                                  Map<String, dynamic>.from(updated),
                                );
                              }
                            });
                          }
                          await _fetchAddresses();
                        },
                      ),
                    );
                  }),
                ] else ...[
                  _AddressTile(
                    title: '—',
                    subtitle: 'ยังไม่มีที่อยู่ตั้งค่าไว้',
                    onTap: null,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(18),
        child: SizedBox(
          height: 56,
          child: GradientButton(
            text: 'ออกจากระบบ',
            onTap: () {
              logout();
            },
          ),
        ),
      ),
    );
  }

  Future<void> logout() async {
    try {
      Get.find<SessionService>().clear();
      Get.offAll(() => const LoginPages(), transition: Transition.fadeIn);

      Get.snackbar(
        'ออกจากระบบสำเร็จ',
        'คุณได้ออกจากระบบเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'เกิดข้อผิดพลาด',
        'ไม่สามารถออกจากระบบได้: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}

class _VehiclePictureBox extends StatelessWidget {
  const _VehiclePictureBox({required this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    if (imageProvider == null) {
      return _buildPlaceholder(context, 'Picture of vehicle');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image(
        image: imageProvider!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(context, 'ไม่สามารถโหลดรูปได้');
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, String message) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: Text(
        message,
        style: GoogleFonts.notoSansThai(
          fontSize: 14,
          color: Colors.black.withOpacity(0.55),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.hint, required this.value});
  final String hint;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              hint,
              style: GoogleFonts.notoSansThai(
                color: Colors.black.withOpacity(0.35),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.notoSansThai(
              color: Colors.black.withOpacity(0.8),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.title, required this.subtitle, this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F6F7),
      borderRadius: BorderRadius.circular(14),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: GoogleFonts.notoSansThai(
                    color: Colors.black.withOpacity(0.8),
                    fontWeight: FontWeight.w900,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoSansThai(
                          color: Colors.black.withOpacity(0.35),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 28,
                color: Colors.black.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressSkeleton extends StatelessWidget {
  const _AddressSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F7),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_bar(), _bar(widthFactor: 0.6)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar({double widthFactor = 0.8}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF3F1),
      borderRadius: BorderRadius.circular(14),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onRetry,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.notoSansThai(
                    color: Colors.black.withOpacity(0.8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                'ลองใหม่',
                style: GoogleFonts.notoSansThai(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
