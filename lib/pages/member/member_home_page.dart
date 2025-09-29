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

  List<BottomNavigationBarItem> get _senderItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'สร้าง'),
    BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'แผนที่'),
    BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_outlined),
      label: 'รายการ',
    ),
  ];

  List<BottomNavigationBarItem> get _receiverItems => const [
    BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'แผนที่'),
    BottomNavigationBarItem(icon: Icon(Icons.inbox_outlined), label: 'รายการ'),
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
      _ => 'Member',
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

    final items = _isSender ? _senderItems : _receiverItems;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
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
                          _senderItems.length - 1,
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
                          _receiverItems.length - 1,
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
                        SenderCreatePage(baseUrl: _baseUrl!),
                        SenderMapPage(baseUrl: _baseUrl!),
                        SenderListPage(baseUrl: _baseUrl!),
                      ]
                    : [
                        ReceiverMapPage(baseUrl: _baseUrl!),
                        ReceiverListPage(baseUrl: _baseUrl!),
                      ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: items,
        currentIndex: _currentIndex.clamp(0, items.length - 1),
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIndex = idx),
        selectedLabelStyle: GoogleFonts.notoSansThai(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.notoSansThai(),
      ),
    );
  }
}
