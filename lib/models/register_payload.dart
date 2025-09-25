// lib/models/register_payload.dart
enum RegisterRole { member, rider }

class RegisterPayload {
  RegisterPayload({
    required this.username,
    required this.password, // ส่งแบบ plaintext ผ่าน HTTPS (server จะ hash)
    required this.role,
  });

  final String username;
  final String password;
  final RegisterRole role;

  // แปลงเป็นค่าที่ DB ต้องการ
  String get dbRole => role == RegisterRole.rider ? 'RIDER' : 'USER';
}
