import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:songduan_app/models/order.dart';
import 'package:songduan_app/services/mock_directory_service.dart';

class SenderCreatePage extends StatefulWidget {
  final String baseUrl;
  const SenderCreatePage({super.key, required this.baseUrl});

  @override
  State<SenderCreatePage> createState() => _SenderCreatePageState();
}

class _SenderCreatePageState extends State<SenderCreatePage> {
  final _phoneCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  LatLng? _selected;
  String? _selectedAddress;
  String? _proofImagePath;

  final MapController _mapController = MapController();
  final LatLng _fallback = const LatLng(13.7563, 100.5018);

  bool _busy = false;

  Future<void> _search() async {
    setState(() => _busy = true);
    final res = await MockDirectoryService.searchByPhone(
      _phoneCtrl.text.trim(),
    );
    setState(() {
      _results = res;
      _busy = false;
    });
  }

  void _pickAddress(Map<String, dynamic> m) {
    final lat = (m['lat'] as double);
    final lng = (m['lng'] as double);
    setState(() {
      _selected = LatLng(lat, lng);
      _selectedAddress = m['address'] as String;
    });
  }

  void _attachProofMock() {
    setState(() {
      _proofImagePath = 'assets/images/mock_proof.png'; // เดโม่
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('แนบรูปสถานะ [1] (mock) เรียบร้อย')),
    );
  }

  void _addOrder() {
    if (_selected == null || _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกที่อยู่/พิกัดผู้รับก่อน')),
      );
      return;
    }
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      receiverPhone: _phoneCtrl.text,
      receiverName: 'คุณผู้รับ',
      address: _selectedAddress!,
      lat: _selected!.latitude,
      lng: _selected!.longitude,
      status: 1,
      proofImagePath: _proofImagePath,
    );
    // ปกติจะส่งไปเก็บใน state management / API
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เพิ่มออเดอร์: ${order.address} (mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = _selected ?? _fallback;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      children: [
        Text(
          'สร้างรายการส่งสินค้า (Sender)',
          style: GoogleFonts.nunitoSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'ค้นหาจากหมายเลขโทรศัพท์ผู้รับ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _busy ? null : _search,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ค้นหา'),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_results.isNotEmpty) ...[
          Text(
            'เลือกที่อยู่ผู้รับจากเบอร์:',
            style: GoogleFonts.notoSansThai(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ..._results.map(
            (m) => ListTile(
              title: Text(m['label']),
              subtitle: Text(m['address']),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _pickAddress(m),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // แผนที่ดูพิกัดที่เลือก
        SizedBox(
          height: 240,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'net.songduan.app',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        child: const Icon(Icons.location_on, color: Colors.red),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: _attachProofMock,
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('แนบรูปสถานะ [1] (mock)'),
            ),
            ElevatedButton.icon(
              onPressed: _addOrder,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('เพิ่มลงรายการ'),
            ),
          ],
        ),
        if (_proofImagePath != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'ไฟล์แนบ: $_proofImagePath',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
