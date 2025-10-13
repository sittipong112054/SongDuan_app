import 'dart:convert';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SessionService extends GetxService {
  final _box = GetStorage('session');

  int? currentUserId;
  String? role;
  String? name;
  String? username;
  String? phone;
  String? avatarPath;
  String? accessToken;
  DateTime? tokenExpiresAt; // จาก exp ใน JWT (ถ้ามี)

  Future<SessionService> init() async {
    currentUserId = _box.read('user_id');
    role = _box.read('role');
    name = _box.read('name');
    username = _box.read('username');
    phone = _box.read('phone');
    avatarPath = _box.read('avatar_path');
    accessToken = _box.read('access_token');
    final expMillis = _box.read('token_expires_at'); // เก็บเป็น millis
    if (expMillis is int) {
      tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(expMillis);
    }
    return this;
  }

  /// เซฟจาก response: รองรับได้ทั้ง { data: { user, token } } และ { user, token }
  void saveFromLoginResponse(Map<String, dynamic> json) {
    final u = (json['data']?['user'] ?? json['user']) as Map? ?? {};
    final token = (json['data']?['token'] ?? json['token'])?.toString();

    currentUserId = int.tryParse(u['id']?.toString() ?? '');
    role = u['role']?.toString();
    name = u['name']?.toString();
    username = u['username']?.toString();
    phone = u['phone']?.toString();
    avatarPath = u['avatar_path']?.toString();
    accessToken = token;

    // พยายามถอด exp จาก JWT (ถ้ามี)
    tokenExpiresAt = _parseJwtExp(token);

    _box.write('user_id', currentUserId);
    _box.write('role', role);
    _box.write('name', name);
    _box.write('username', username);
    _box.write('phone', phone);
    _box.write('avatar_path', avatarPath);
    _box.write('access_token', accessToken);
    _box.write('token_expires_at', tokenExpiresAt?.millisecondsSinceEpoch);
  }

  /// อัปเดตเฉพาะข้อมูล user (เช่นหลังแก้โปรไฟล์) โดยไม่แตะ token
  void updateUser(Map<String, dynamic> user) {
    name = user['name']?.toString() ?? name;
    username = user['username']?.toString() ?? username;
    phone = user['phone']?.toString() ?? phone;
    avatarPath = user['avatar_path']?.toString() ?? avatarPath;

    _box.write('name', name);
    _box.write('username', username);
    _box.write('phone', phone);
    _box.write('avatar_path', avatarPath);
  }

  void clear() {
    currentUserId = null;
    role = null;
    name = null;
    username = null;
    phone = null;
    avatarPath = null;
    accessToken = null;
    tokenExpiresAt = null;
    _box.erase();
  }

  /// ใช้ใน splash: ต้องมี user และ token ยังไม่หมดอายุ (ถ้ารู้เวลา)
  bool get isLoggedIn {
    if (currentUserId == null) return false;
    if (accessToken == null || accessToken!.isEmpty) return false;
    if (tokenExpiresAt == null) return true; // กรณี backend ไม่ใส่ exp ใน JWT
    return DateTime.now().isBefore(tokenExpiresAt!);
  }

  bool get isRider => (role ?? '').toUpperCase() == 'RIDER';
  bool get isTokenExpired {
    if (tokenExpiresAt == null) return false;
    return DateTime.now().isAfter(tokenExpiresAt!);
  }

  /// header สำหรับ request ที่ต้อง auth
  Map<String, String> authHeaders({Map<String, String>? extra}) {
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if ((accessToken ?? '').isNotEmpty)
        'Authorization': 'Bearer $accessToken',
      ...?extra,
    };
  }

  /// ถอด exp จาก JWT (วินาที epoch) → DateTime
  DateTime? _parseJwtExp(String? jwt) {
    if (jwt == null || jwt.isEmpty) return null;
    final parts = jwt.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = _decodeBase64Url(parts[1]);
      final map = jsonDecode(payload);
      final exp = map['exp'];
      if (exp is int) {
        // exp เป็น seconds → แปลงเป็น milliseconds
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (_) {}
    return null;
  }

  String _decodeBase64Url(String input) {
    var out = input.replaceAll('-', '+').replaceAll('_', '/');
    switch (out.length % 4) {
      case 2:
        out += '==';
        break;
      case 3:
        out += '=';
        break;
      case 0:
        break;
      default:
        // ความยาวแปลก ๆ ก็ปล่อยไปให้ base64.decode โยน error เอง
        break;
    }
    return utf8.decode(base64.decode(out));
  }
}
