import 'dart:math';

class MockDirectoryService {
  // คืนรายการ “ที่อยู่จากเบอร์โทร” แบบจำลอง
  static Future<List<Map<String, dynamic>>> searchByPhone(String phone) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rnd = Random(phone.hashCode);
    return List.generate(3, (i) {
      final lat = 13.75 + rnd.nextDouble() * 0.05;
      final lng = 100.50 + rnd.nextDouble() * 0.05;
      return {
        'label': 'ที่อยู่ #${i + 1} สำหรับ $phone',
        'address': 'ซอยตัวอย่าง ${10 + i}, เขตตัวอย่าง, กทม.',
        'lat': lat,
        'lng': lng,
      };
    });
  }
}
