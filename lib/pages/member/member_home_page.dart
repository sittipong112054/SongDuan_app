import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:songduan_app/config/config.dart';
import 'package:songduan_app/pages/profile_page.dart';
import 'package:songduan_app/widgets/profile_header.dart';
import 'package:songduan_app/widgets/Tab_Button.dart';

import 'package:songduan_app/pages/member/sender/sender_create_page.dart';
import 'package:songduan_app/pages/member/sender/sender_map_page.dart';
import 'package:songduan_app/pages/member/sender/sender_list_page.dart';
import 'package:songduan_app/pages/member/receiver/receiver_map_page.dart';
import 'package:songduan_app/pages/member/receiver/receiver_list_page.dart';

class MemberHomePage extends StatefulWidget {
  const MemberHomePage({super.key});

  @override
  State<MemberHomePage> createState() => _MemberHomePageState();
}

class _MemberHomePageState extends State<MemberHomePage> {
  static const _orange = Color(0xFFEA4335);
  static const _gold = Color(0xFFFF9C00);

  bool _isSender = true;
  int _senderIndex = 0;
  int _receiverIndex = 0;

  String? _baseUrl;
  String? _cfgError;
  bool _loadingCfg = true;

  late final Map<String, dynamic> _user;
  late final String _name;
  late final String _roleLabel;

  int get _currentIndex => _isSender ? _senderIndex : _receiverIndex;
  set _currentIndex(int idx) {
    if (_isSender) {
      _senderIndex = idx;
    } else {
      _receiverIndex = idx;
    }
  }

  List<GradientNavItem> get _senderTabs => const [
    GradientNavItem(Icons.add_box_outlined, 'สร้าง'),
    GradientNavItem(Icons.map_outlined, 'แผนที่'),
    GradientNavItem(Icons.list_alt_outlined, 'รายการ'),
  ];

  List<GradientNavItem> get _receiverTabs => const [
    GradientNavItem(Icons.map_outlined, 'แผนที่'),
    GradientNavItem(Icons.inbox_outlined, 'รายการ'),
  ];

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
      _ => 'User',
    };
  }

  Future<void> _loadConfig() async {
    try {
      final config = await Configuration.getConfig();
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

    final tabs = _isSender ? _senderTabs : _receiverTabs;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: ProfileHeader(
                    name: _name,
                    role: _roleLabel,
                    image: _user['avatar_path']?.toString().isNotEmpty == true
                        ? _user['avatar_path'] as String
                        : 'assets/images/default_avatar.png',
                    baseUrl: _baseUrl,
                    onMorePressed: () =>
                        Get.to(() => const ProfilePage(), arguments: _user),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabButton(
                          text: "ผู้ส่ง",
                          selected: _isSender,
                          onTap: () => setState(() {
                            _isSender = true;
                            _senderIndex = _senderIndex.clamp(
                              0,
                              _senderTabs.length - 1,
                            );
                          }),
                        ),
                      ),
                      Expanded(
                        child: TabButton(
                          text: "ผู้รับ",
                          selected: !_isSender,
                          onTap: () => setState(() {
                            _isSender = false;
                            _receiverIndex = _receiverIndex.clamp(
                              0,
                              _receiverTabs.length - 1,
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _isSender
                        ? [
                            SenderCreatePage(
                              key: UniqueKey(),
                              baseUrl: _baseUrl!,
                            ),
                            SenderMapPage(key: UniqueKey(), baseUrl: _baseUrl!),
                            SenderListPage(
                              key: UniqueKey(),
                              baseUrl: _baseUrl!,
                            ),
                          ]
                        : [
                            ReceiverMapPage(
                              key: UniqueKey(),
                              baseUrl: _baseUrl!,
                            ),
                            ReceiverListPage(
                              key: UniqueKey(),
                              baseUrl: _baseUrl!,
                            ),
                          ],
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: CustomGradientNavBar(
                  items: tabs,
                  currentIndex: _currentIndex.clamp(0, tabs.length - 1),
                  onTap: (idx) => setState(() => _currentIndex = idx),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientNavItem {
  final IconData icon;
  final String label;
  const GradientNavItem(this.icon, this.label);
}

class CustomGradientNavBar extends StatelessWidget {
  final List<GradientNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomGradientNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return _NavButton(
                item: items[i],
                selected: selected,
                onTap: () => onTap(i),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final GradientNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ts = MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.2);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: [
                      _MemberHomePageState._orange,
                      _MemberHomePageState._gold,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: selected ? 24 : 22,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansThai(
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w400,
                  fontSize: 12 * ts,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
