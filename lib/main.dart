import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:songduan_app/pages/splash_page.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        textTheme: GoogleFonts.notoSansThaiTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF9C00)),
      ),
      home: SplashPage(),
    );
  }
}

// https://songduan-api.onrender.com
