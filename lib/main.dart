import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:services/bindings/app_bindings.dart';
import 'package:services/screens/splash_screen.dart';
import 'package:services/utils/app_constants.dart';


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
       initialBinding: AppBindings(),
    );
  }
}












// suvas
