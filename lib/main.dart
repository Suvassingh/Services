import 'package:flutter/material.dart';
import 'package:get/get.dart';  


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Local Services ',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: AppConstants.appMainColour),
      home: const SplashScreen(),
    );
  }
}











// suvas
// suvas