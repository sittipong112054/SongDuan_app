import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/services/mock_directory_service.dart';

import 'package:songduan_app/widgets/gradient_button.dart';
import 'package:songduan_app/widgets/custom_text_field.dart';

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
  final List<TextEditingController> _itemCtrls = [
    TextEditingController(text: 'ชื่อสินค้า #1'),
  ];

  bool _busy = false;
  List<Map<String, dynamic>> _results = [];
  int? _selectedAddressIndex;

  String? _proofImagePath;

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
    });
    final res = await MockDirectoryService.searchByPhone(phone);
    setState(() {
      _results = res;
      _busy = false;
    });
  }

  void _attachProofMock() {
    setState(() => _proofImagePath = 'assets/images/mrbeast.jpg');
    _toast('แนบรูปสินค้ารวม (mock) เรียบร้อย');
  }

  void _addItemField() {
    final next = _itemCtrls.length + 1;
    setState(
      () => _itemCtrls.add(TextEditingController(text: 'ชื่อสินค้า #$next')),
    );
  }

  void _removeItemField(int i) {
    if (_itemCtrls.length == 1) return;
    setState(() => _itemCtrls.removeAt(i));
  }

  void _confirm() {
    final okPhone = _phoneCtrl.text.trim().isNotEmpty;
    final okAddr = _selectedAddressIndex != null;
    final okItems = _itemCtrls.any((c) => c.text.trim().isNotEmpty);

    if (!okPhone || !okAddr || !okItems) {
      _toast('กรุณากรอกข้อมูลให้ครบ (โทรศัพท์, ที่อยู่, สินค้า)');
      return;
    }
    final count = _itemCtrls.where((c) => c.text.trim().isNotEmpty).length;
    _toast('ยืนยันการสร้างสินค้า $count รายการ (mock)');
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final canConfirm =
        _phoneCtrl.text.trim().isNotEmpty &&
        _selectedAddressIndex != null &&
        _itemCtrls.any((c) => c.text.trim().isNotEmpty);
    final itemCount = _itemCtrls.where((c) => c.text.trim().isNotEmpty).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        const SizedBox(height: 8),

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

        if (_results.isNotEmpty)
          _ReceiverCard(
            phone: _phoneCtrl.text.trim(),
            name: 'สมศักดิ์ สิทธิ์มั่น',
            results: _results,
            selectedIndex: _selectedAddressIndex,
            onPickIndex: (i) => setState(() => _selectedAddressIndex = i),
          ),

        const SizedBox(height: 12),

        _CameraCard(imagePath: _proofImagePath, onTap: _attachProofMock),

        const SizedBox(height: 16),
        _SectionTitle('ข้อมูลสินค้า'),
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
                    hint: 'ชื่อสินค้า #${i + 1}',
                    controller: ctrl,
                    prefixIcon: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.black45,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
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
        const SizedBox(height: 14),
        _AddItemButton(onTap: _addItemField),
        const SizedBox(height: 16),

        _SectionTitle('ระบุโน๊ต'),

        const SizedBox(height: 6),
        _NoteField(controller: _noteCtrl),
        const SizedBox(height: 18),

        IgnorePointer(
          ignoring: !canConfirm,
          child: Opacity(
            opacity: canConfirm ? 1 : 0.6,
            child: GradientButton(
              text:
                  'ยืนยันการสร้างสินค้า ${itemCount > 0 ? itemCount : 1} รายการ',
              onTap: _confirm,
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _jobNameCtrl.dispose();
    _noteCtrl.dispose();
    for (final c in _itemCtrls) {
      c.dispose();
    }
    super.dispose();
  }
}

class _ReceiverCard extends StatelessWidget {
  final String name;
  final String phone;
  final List<Map<String, dynamic>> results;
  final int? selectedIndex;
  final ValueChanged<int> onPickIndex;
  const _ReceiverCard({
    required this.name,
    required this.phone,
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
          // header
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundImage: AssetImage(
                  'assets/images/default_avatar.png',
                ), // mock
              ),
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
              padding: const EdgeInsets.only(bottom: 10),
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
                        Text(
                          m['address'] as String,
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13.5,
                            color: Colors.black.withOpacity(0.80),
                          ),
                        ),
                      ],
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

class _CameraCard extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;
  const _CameraCard({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: imagePath == null
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
                child: Image.asset(
                  imagePath!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
      ),
    );
  }
}

class _AddItemButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddItemButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.92,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFEDEEF1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'เพิ่มสินค้าที่จะส่ง',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withOpacity(0.35),
                  ),
                ),
              ),
              const Icon(Icons.add, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

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
  const _RoundIconBtn({
    required this.icon,
    this.tooltip,
    this.onTap,
    // this.size = 40,
    // this.iconSize = 22,
  });

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
