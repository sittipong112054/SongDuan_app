// lib/services/session_service.dart
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SessionService extends GetxService {
  final _box = GetStorage('session');

  int? currentUserId;
  String? role; // 'RIDER' | 'MEMBER' | 'USER'
  String? name;
  String? phone;
  String? avatarPath;
  String? accessToken; // ถ้ามี JWT

  Future<SessionService> init() async {
    // โหลดจาก storage ตอนเปิดแอป
    currentUserId = _box.read('user_id');
    role = _box.read('role');
    name = _box.read('name');
    phone = _box.read('phone');
    avatarPath = _box.read('avatar_path');
    accessToken = _box.read('access_token');
    return this;
  }

  void saveFromLoginResponse(Map<String, dynamic> json) {
    // สมมติ response
    // { data: { user: { id, role, name, phone, avatar_path }, token: '...' } }
    final u = (json['data']?['user'] ?? json['user']) as Map? ?? {};
    final token = (json['data']?['token'] ?? json['token'])?.toString();

    currentUserId = int.tryParse(u['id']?.toString() ?? '');
    role = u['role']?.toString();
    name = u['name']?.toString();
    phone = u['phone']?.toString();
    avatarPath = u['avatar_path']?.toString();
    accessToken = token;

    // persist
    _box.write('user_id', currentUserId);
    _box.write('role', role);
    _box.write('name', name);
    _box.write('phone', phone);
    _box.write('avatar_path', avatarPath);
    _box.write('access_token', accessToken);
  }

  void clear() {
    currentUserId = null;
    role = null;
    name = null;
    phone = null;
    avatarPath = null;
    accessToken = null;
    _box.erase(); // ล้างทั้งหมดใน scope 'session'
  }

  bool get isLoggedIn => currentUserId != null;
  bool get isRider => (role ?? '').toUpperCase() == 'RIDER';
}
