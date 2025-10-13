import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:songduan_app/services/session_service.dart';
import 'package:songduan_app/pages/login_page.dart';

Future<Map<String, String>> authHeaders({Map<String, String>? extra}) async {
  final ss = Get.find<SessionService>();
  final token = ss.accessToken;
  return {
    'Content-Type': 'application/json; charset=utf-8',
    if ((token ?? '').isNotEmpty) 'Authorization': 'Bearer $token',
    ...?extra,
  };
}

void handleAuthErrorIfAny(http.Response res) {
  if (res.statusCode == 401) {
    final ss = Get.find<SessionService>();
    ss.clear();
    Get.offAll(() => const LoginPages(), transition: Transition.fadeIn);
    Get.snackbar(
      'เซสชันหมดเวลา',
      'กรุณาเข้าสู่ระบบใหม่',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
    throw Exception('Unauthorized');
  }
}
