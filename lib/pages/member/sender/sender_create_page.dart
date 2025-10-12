import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:songduan_app/services/session_service.dart';
import 'package:path/path.dart' as p;

import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';
import 'package:songduan_app/widgets/section_title.dart';

class SenderCreatePage extends StatefulWidget {
  final String baseUrl;

  const SenderCreatePage({super.key, required this.baseUrl});

  @override
  State<SenderCreatePage> createState() => _SenderCreatePageState();
}

class _SenderCreatePageState extends State<SenderCreatePage> {
  final _phoneCtrl = TextEditingController();
  final _jobNameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final List<TextEditingController> _itemCtrls = [TextEditingController()];

  bool _busy = false;

  List<Map<String, dynamic>> _pickupAddresses = [];
  int? _selectedPickupIndex;
  String? _pickupError;
  bool _loadingPickup = false;

  List<Map<String, dynamic>> _results = [];
  int? _selectedAddressIndex;
  int? _receiverUserId;
  String? _receiverName;
  String? _receiverPhone;
  String? _receiverAvatar;

  String? _proofImagePath;

  final senderId = Get.find<SessionService>().currentUserId;

  @override
  void initState() {
    super.initState();
    for (final c in [_phoneCtrl, _jobNameCtrl, _noteCtrl, ..._itemCtrls]) {
      c.addListener(() => setState(() {}));
    }
    _fetchPickupAddresses();
  }

  @override
  void dispose() {
    for (final c in [_phoneCtrl, _jobNameCtrl, _noteCtrl, ..._itemCtrls]) {
      c.removeListener(() {});
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String msg) {
    Get.snackbar(
      'แจ้งเตือน',
      msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
    );
  }

  ImageProvider _resolveAvatar(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }
    final s = raw.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) {
      return NetworkImage(s);
    }
    if (s.startsWith('/')) {
      final base = widget.baseUrl.replaceFirst(RegExp(r'\/+$'), '');
      return NetworkImage('$base$s');
    }
    return AssetImage(s);
  }

  Future<void> _fetchPickupAddresses() async {
    setState(() {
      _loadingPickup = true;
      _pickupError = null;
    });
    try {
      final uri = Uri.parse('${widget.baseUrl}/addresses/$senderId');
      final resp = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 12));
      final body = jsonDecode(utf8.decode(resp.bodyBytes));

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final List list = (body is Map && body['data'] is List)
            ? body['data'] as List
            : (body is List ? body : const []);

        final mapped = list.map<Map<String, dynamic>>((a) {
          return {
            'id': a['id'],
            'label': (a['label'] ?? 'ที่อยู่').toString(),
            'address_text': (a['address_text'] ?? '').toString(),
            'is_default': a['is_default'] == 1 || a['is_default'] == true,
          };
        }).toList();

        int? defaultIdx = mapped.indexWhere((e) => e['is_default'] == true);
        if (defaultIdx < 0 && mapped.isNotEmpty) defaultIdx = 0;

        setState(() {
          _pickupAddresses = mapped;
          _selectedPickupIndex = defaultIdx! >= 0 ? defaultIdx : null;
        });
      } else {
        final msg =
            (body is Map &&
                body['error'] is Map &&
                body['error']['message'] is String)
            ? body['error']['message'] as String
            : 'HTTP ${resp.statusCode}';
        setState(() => _pickupError = msg);
      }
    } catch (e) {
      setState(() => _pickupError = 'โหลดที่อยู่ผู้ส่งไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _loadingPickup = false);
    }
  }

  Future<void> _searchReceiver() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _toast('กรุณากรอกหมายเลขโทรศัพท์ผู้รับ');
      return;
    }

    setState(() {
      _busy = true;
      _results = [];
      _selectedAddressIndex = null;
      _receiverUserId = null;
      _receiverName = null;
      _receiverPhone = null;
      _receiverAvatar = null;
    });

    try {
      final uri = Uri.parse('${widget.baseUrl}/addresses/search').replace(
        queryParameters: {
          'phone': phone,
          'page': '1',
          'pageSize': '20',

          'requesterId': senderId.toString(),
        },
      );

      final resp = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      final body = jsonDecode(utf8.decode(resp.bodyBytes));

      if (resp.statusCode == 200) {
        final user = (body['data']?['user'] ?? {}) as Map? ?? {};
        final List addrs = (body['data']?['addresses'] as List?) ?? const [];

        final mapped = addrs.map<Map<String, dynamic>>((a) {
          return {
            'id': a['id'],
            'address': (a['address_text'] ?? '').toString(),
            'lat': a['lat'],
            'lng': a['lng'],
            'is_default': a['is_default'],
            'user_id': a['user_id'],
          };
        }).toList();

        setState(() {
          _results = mapped;
          _receiverUserId = int.tryParse('${user['id'] ?? ''}');
          _receiverName = (user['name'] ?? '').toString();
          _receiverPhone = (user['phone'] ?? '').toString();
          _receiverAvatar = (user['avatar_path'] ?? '').toString();
        });
      } else {
        final msg =
            (body is Map &&
                body['error'] is Map &&
                body['error']['message'] is String)
            ? body['error']['message'] as String
            : 'HTTP ${resp.statusCode}';
        _toast(msg);
      }
    } catch (e) {
      _toast('เชื่อมต่อเซิร์ฟเวอร์ไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitShipment() async {
    final okPickup =
        _selectedPickupIndex != null && _pickupAddresses.isNotEmpty;
    final okReceiver = _receiverUserId != null;
    final okDrop = _selectedAddressIndex != null && _results.isNotEmpty;
    final okItems = _itemCtrls.any((c) => c.text.trim().isNotEmpty);

    if (!okPickup || !okReceiver || !okDrop || !okItems) {
      _toast(
        'กรุณากรอกข้อมูลให้ครบ (จุดรับของ, ผู้รับ, ที่อยู่ปลายทาง, รายการสินค้า)',
      );
      return;
    }

    final pickupId = _pickupAddresses[_selectedPickupIndex!]['id'] as int?;
    final dropoffId = _results[_selectedAddressIndex!]['id'] as int?;

    if (pickupId == null) return _toast('ไม่พบรหัสที่อยู่รับของ');
    if (dropoffId == null) return _toast('ไม่พบรหัสที่อยู่ปลายทาง');
    if (_receiverUserId == senderId) {
      return _toast('ไม่สามารถส่งให้ตัวเองได้');
    }

    final title = _jobNameCtrl.text.trim().isEmpty
        ? 'ส่งสินค้า'
        : _jobNameCtrl.text.trim();

    final items = _itemCtrls
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .map((name) => {'name': name, 'qty': 1})
        .toList();

    setState(() => _busy = true);
    try {
      final uri = Uri.parse('${widget.baseUrl}/shipments');

      http.Response resp;

      if (_proofImagePath != null) {
        final req = http.MultipartRequest('POST', uri);

        req.fields['title'] = title;
        req.fields['sender_id'] = senderId.toString();
        req.fields['receiver_id'] = _receiverUserId.toString();
        req.fields['pickup_address_id'] = pickupId.toString();
        req.fields['dropoff_address_id'] = dropoffId.toString();
        req.fields['note'] = _noteCtrl.text.trim();
        req.fields['items'] = jsonEncode(items);

        final f = File(_proofImagePath!);
        final filename = p.basename(f.path);
        final mime = lookupMimeType(f.path) ?? 'image/jpeg';
        final parts = mime.split('/');
        final stream = http.ByteStream(f.openRead());
        final length = await f.length();

        req.files.add(
          http.MultipartFile(
            'proof',
            stream,
            length,
            filename: filename,
            contentType: MediaType(parts.first, parts.last),
          ),
        );

        final sent = await req.send();
        resp = await http.Response.fromStream(sent);
      } else {
        final payload = {
          'title': title,
          'sender_id': senderId,
          'receiver_id': _receiverUserId,
          'pickup_address_id': pickupId,
          'dropoff_address_id': dropoffId,
          'items': items,
          'note': _noteCtrl.text.trim(),
        };

        resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );
      }

      final body = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode == 201) {
        _toast('สร้างงานส่งสำเร็จ');
        setState(() {
          _jobNameCtrl.clear();
          _noteCtrl.clear();
          for (final c in _itemCtrls) {
            c.clear();
          }
          _proofImagePath = null;
        });
      } else {
        final msg =
            (body is Map &&
                body['error'] is Map &&
                body['error']['message'] is String)
            ? body['error']['message'] as String
            : 'HTTP ${resp.statusCode}';
        _toast(msg);
      }
    } catch (e) {
      _toast('ส่งงานไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addItemField() {
    final c = TextEditingController();
    c.addListener(() => setState(() {}));
    setState(() => _itemCtrls.add(c));
  }

  void _removeItemField(int i) {
    if (_itemCtrls.length == 1) return;
    final c = _itemCtrls.removeAt(i);
    c.removeListener(() {});
    c.dispose();
    setState(() {});
  }

  Future<void> _manualRefreshPickup() async {
    await _fetchPickupAddresses();
    if (_phoneCtrl.text.trim().isNotEmpty) {
      await _searchReceiver();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm =
        _selectedPickupIndex != null &&
        _receiverUserId != null &&
        _selectedAddressIndex != null &&
        _itemCtrls.any((c) => c.text.trim().isNotEmpty);

    final itemCount = _itemCtrls.where((c) => c.text.trim().isNotEmpty).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        const SizedBox(height: 8),

        Row(
          children: [
            SectionTitle("เลือกจุดรับของ (ผู้ส่ง)"),
            const Spacer(),
            TextButton.icon(
              onPressed: _loadingPickup ? null : _manualRefreshPickup,
              icon: _loadingPickup
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),

        const SizedBox(height: 8),
        if (_loadingPickup) ...[
          const _SkeletonLine(),
          const SizedBox(height: 8),
          const _SkeletonLine(),
        ] else if (_pickupError != null) ...[
          _ErrorTile(message: _pickupError!, onRetry: _fetchPickupAddresses),
        ] else if (_pickupAddresses.isEmpty) ...[
          _HintTile(text: 'ยังไม่มีที่อยู่รับของ โปรดเพิ่มในโปรไฟล์ก่อน'),
        ] else ...[
          _AddressPickList(
            addresses: _pickupAddresses,
            selectedIndex: _selectedPickupIndex,
            onPick: (i) => setState(() => _selectedPickupIndex = i),
          ),
        ],

        const SizedBox(height: 14),
        SectionTitle("เลือกจุดส่งของ (ผู้รับ)"),
        const SizedBox(height: 14),

        CustomTextField(
          hint: 'หมายเลขโทรศัพท์ของผู้รับ',
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          prefixIcon: const Icon(Icons.search, color: Colors.black45),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _searchReceiver,
                    child: const Text('ค้นหา'),
                  ),
          ),
          onFieldSubmitted: (_) => _searchReceiver(),
        ),
        const SizedBox(height: 12),

        if ((_results.isNotEmpty) || (_receiverName?.isNotEmpty ?? false))
          _ReceiverCard(
            name: _receiverName ?? '—',
            phone: _receiverPhone ?? _phoneCtrl.text.trim(),
            avatar: _resolveAvatar(_receiverAvatar),
            results: _results,
            selectedIndex: _selectedAddressIndex,
            onPickIndex: (i) => setState(() => _selectedAddressIndex = i),
          ),

        const SizedBox(height: 12),

        _CameraCard(
          imagePath: _proofImagePath,
          onImagePicked: (path) => setState(() => _proofImagePath = path),
        ),

        const SizedBox(height: 16),
        SectionTitle('ข้อมูลสินค้า'),
        const SizedBox(height: 10),

        CustomTextField(
          hint: 'ชื่อเรียกของงานส่ง',
          controller: _jobNameCtrl,
          prefixIcon: const Icon(
            Icons.local_shipping_rounded,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 14),

        ..._itemCtrls.indexed.map((e) {
          final i = e.$1;
          final ctrl = e.$2;

          return Padding(
            padding: EdgeInsets.only(
              bottom: i == _itemCtrls.length - 1 ? 0 : 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    key: ValueKey('item_$i'),
                    hint: 'ชื่อสินค้า #${i + 1}',
                    controller: ctrl,
                    prefixIcon: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                if (i == 0)
                  _RoundIconBtn(
                    icon: Icons.add_circle_outline,
                    tooltip: 'เพิ่มรายการ',
                    onTap: _addItemField,
                  )
                else
                  _RoundIconBtn(
                    icon: Icons.remove_circle_outline,
                    tooltip: 'ลบรายการ',
                    onTap: _itemCtrls.length > 1
                        ? () => _removeItemField(i)
                        : null,
                  ),
              ],
            ),
          );
        }),

        const SizedBox(height: 16),

        SectionTitle('ระบุโน๊ต'),
        const SizedBox(height: 6),
        _NoteField(controller: _noteCtrl),
        const SizedBox(height: 18),

        IgnorePointer(
          ignoring: !canConfirm || _busy,
          child: Opacity(
            opacity: (!canConfirm || _busy) ? 0.6 : 1,
            child: GradientButton(
              text:
                  'ยืนยันการสร้างสินค้า ${itemCount > 0 ? itemCount : 1} รายการ',
              onTap: _submitShipment,
            ),
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}

class _AddressPickList extends StatelessWidget {
  final List<Map<String, dynamic>> addresses;
  final int? selectedIndex;
  final ValueChanged<int> onPick;

  const _AddressPickList({
    required this.addresses,
    required this.selectedIndex,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: addresses.indexed.map((e) {
        final i = e.$1;
        final a = e.$2;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ListTile(
            onTap: () => onPick(i),
            leading: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selectedIndex == i
                    ? const Color(0xFFFF7A00)
                    : const Color(0xFFE9ECEF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
              ),
              child: selectedIndex == i
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            title: Text(
              a['label'] ?? 'ที่อยู่',
              style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              a['address_text'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReceiverCard extends StatelessWidget {
  final String name;
  final String phone;
  final ImageProvider avatar;
  final List<Map<String, dynamic>> results;
  final int? selectedIndex;
  final ValueChanged<int> onPickIndex;

  const _ReceiverCard({
    required this.name,
    required this.phone,
    required this.avatar,
    required this.results,
    required this.selectedIndex,
    required this.onPickIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecor(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, backgroundImage: avatar),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$name  $phone',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          ...results.indexed.map((e) {
            final i = e.$1;
            final m = e.$2;
            return Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => onPickIndex(i),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selectedIndex == i
                            ? const Color(0xFFFF7A00)
                            : const Color(0xFFE9ECEF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ),
                      child: selectedIndex == i
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ที่อยู่ ${i + 1}',
                            style: GoogleFonts.notoSansThai(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: Text(
                              (m['address'] ?? '').toString(),
                              style: GoogleFonts.notoSansThai(
                                fontSize: 13.5,
                                color: Colors.black.withOpacity(0.80),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _CameraCard extends StatefulWidget {
  final String? imagePath;
  final ValueChanged<String> onImagePicked;

  const _CameraCard({required this.imagePath, required this.onImagePicked});

  @override
  State<_CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends State<_CameraCard> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      widget.onImagePicked(picked.path);
    }
    if (mounted) Navigator.pop(context);
  }

  void _showPickOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text("ถ่ายภาพ"),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("เลือกจากเครื่อง"),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPickOptions,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: widget.imagePath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_camera_outlined,
                    size: 44,
                    color: Colors.black45,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'รูปถ่ายสินค้ารวม',
                    style: GoogleFonts.notoSansThai(
                      color: Colors.black45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }
}

// class _AddItemButton extends StatelessWidget {
//   final VoidCallback onTap;
//   const _AddItemButton({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.center,
//       child: Material(
//         color: const Color(0xFFEDEEF1),
//         borderRadius: BorderRadius.circular(12),
//         elevation: 2,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: onTap,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'เพิ่มสินค้าที่จะส่ง',
//                   style: GoogleFonts.notoSansThai(
//                     fontSize: 14.5,
//                     fontWeight: FontWeight.w800,
//                     color: Colors.black.withOpacity(0.7),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 const Icon(Icons.add, color: Colors.black54),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            offset: const Offset(0, 6),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'ตัวอย่าง รั้วสีขาว หลังคาสีส้ม (ถ้ามี)',
          hintStyle: GoogleFonts.notoSansThai(
            color: Colors.black.withOpacity(0.35),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;
  final double size = 40;
  final double iconSize = 22;
  const _RoundIconBtn({required this.icon, this.tooltip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    Widget btn = Material(
      color: enabled ? const Color(0xFFF0F2F5) : const Color(0xFFE8EAED),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: enabled ? Colors.black87 : Colors.black38,
          ),
        ),
      ),
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      btn = Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorTile({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.red)),
        ),
        TextButton(onPressed: onRetry, child: const Text('ลองใหม่')),
      ],
    ),
  );
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine();
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

class _HintTile extends StatelessWidget {
  final String text;
  const _HintTile({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
