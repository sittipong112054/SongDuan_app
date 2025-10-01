import 'package:get/get.dart';

class SessionService extends GetxService {
  final RxnString _currentUserId = RxnString();

  String? get currentUserId => _currentUserId.value;

  void setCurrentUserId(dynamic id) {
    if (id == null) {
      _currentUserId.value = null;
    } else {
      _currentUserId.value = id.toString();
    }
  }

  Future<SessionService> init() async {
    return this;
  }

  void clear() {
    _currentUserId.value = null;
  }
}
