import 'package:flutter/material.dart';
import 'package:services/utils/app_constants.dart';

class ServiceDetailScreen extends StatelessWidget {
  final String serviceName;

  const ServiceDetailScreen({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),

        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            title: Text(
              serviceName,
              style: TextStyle(color: AppConstants.appTextColour,fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: AppConstants.appMainColour,
            elevation: 0,
            iconTheme: IconThemeData(color: AppConstants.appTextColour),
          ),
        ),
      ),
      body: Center(
        child: Text(
          "Welcome to $serviceName Service",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
