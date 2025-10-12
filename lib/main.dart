import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:songduan_app/pages/splash_page.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:songduan_app/services/session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init('session');

  Get.put<SessionService>(await SessionService().init(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'SONGDUAN EXPRESS',
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansThaiTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF9C00)),
      ),
      home: SplashPage(),
    );
  }
}
