import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:services/models/product_model.dart';
import 'package:services/screens/auth/login_screen.dart';
import 'package:services/screens/business_profile_screen.dart';
import 'package:services/screens/services/add_service_screen.dart';
import 'package:services/screens/services/facebook_style_add_service.dart';
import 'package:services/screens/services/product_detail_screen.dart';
import 'package:services/services/product_service.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceDetailScreen extends StatefulWidget {
  final String serviceName;
  final String serviceImage;

  const ServiceDetailScreen({
    super.key,
    required this.serviceName,
    required this.serviceImage,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  List<Product> services = [];
  String selectedLocation = 'All Locations';
  bool isGridView = false;
  bool showAddButton = false;
  
  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final products = await ProductService.getProductsByCategory(widget.serviceName);
    setState(() {
      services = products;
    });
  }

  Future<String?> _getBusinessImage(String vendorName) async {
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('storeName') ?? '';
    if (vendorName == storeName) {
      return prefs.getString('businessImagePath');
    }
    return null;
  }

  Future<void> _checkAuthAndAdd() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (isLoggedIn) {
      _showPostBottomSheet();
    } else {
      Get.to(() =>  LoginScreen());
    }
  }

  Widget _buildPostComposer() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _checkAuthAndAdd,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            FutureBuilder<String?>(
              future: _getUserProfileImage(),
              builder: (context, snapshot) {
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: AppConstants.appMainColour,
                  backgroundImage: snapshot.hasData && snapshot.data != null 
                      ? FileImage(File(snapshot.data!))
                      : null,
                  child: snapshot.hasData && snapshot.data != null
                      ? null
                      : const Icon(Icons.person, color: Colors.white, size: 20),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'What ${widget.serviceName.toLowerCase()} do you want to share?',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _getUserProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profileImagePath');
  }

  void _showPostBottomSheet() {
    Get.to(() => FacebookStyleAddService(serviceCategory: widget.serviceName));
  }

  Widget _buildActionRow(IconData icon, String text, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Get.to(() => AddServiceScreen(serviceCategory: widget.serviceName));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? 'User';
  }

  Widget _buildProductView() {
    final filteredServices = services.where((service) => 
      selectedLocation == 'All Locations' || service.location == selectedLocation
    ).toList();

    if (isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: filteredServices.length,
        itemBuilder: (context, index) {
          final service = filteredServices[index];
          return Card(
            child: InkWell(
              onTap: () => Get.to(() => ProductDetailScreen(product: service)),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image, size: 40),
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: FutureBuilder<String?>(
                            future: _getBusinessImage(service.vendorName),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return CircleAvatar(
                                  radius: 12,
                                  backgroundImage: FileImage(File(snapshot.data!)),
                                  backgroundColor: Colors.white,
                                );
                              }
                              return CircleAvatar(
                                radius: 12,
                                backgroundColor: AppConstants.appMainColour,
                                child: Text(
                                  service.vendorName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      service.vendorName,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      service.price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppConstants.appMainColour,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredServices.length,
      itemBuilder: (context, index) {
        final service = filteredServices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => Get.to(() => ProductDetailScreen(product: service)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, size: 30),
                      ),
                      Positioned(
                        bottom: -5,
                        right: -5,
                        child: FutureBuilder<String?>(
                          future: _getBusinessImage(service.vendorName),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return CircleAvatar(
                                radius: 15,
                                backgroundImage: FileImage(File(snapshot.data!)),
                                backgroundColor: Colors.white,
                              );
                            }
                            return CircleAvatar(
                              radius: 15,
                              backgroundColor: AppConstants.appMainColour,
                              child: Text(
                                service.vendorName[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () => Get.to(() => BusinessProfileScreen(vendorName: service.vendorName)),
                          child: Text(
                            service.vendorName,
                            style: const TextStyle(
                              fontSize: 14, 
                              color: AppConstants.appMainColour, 
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(service.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text('${service.rating}'),
                            const SizedBox(width: 16),
                            const Icon(Icons.location_on, size: 16),
                            Text(service.location),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service.price,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.appMainColour,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.serviceName),
        backgroundColor: AppConstants.appMainColour,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => setState(() => isGridView = !isGridView),
            icon: Icon(isGridView ? Icons.list : Icons.grid_view),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => selectedLocation = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All Locations', child: Text('All Locations')),
              const PopupMenuItem(value: 'Near Me', child: Text('Near Me')),
              const PopupMenuItem(value: 'City Center', child: Text('City Center')),
              const PopupMenuItem(value: 'Downtown', child: Text('Downtown')),
            ],
            child: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPostComposer(),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Image.asset(widget.serviceImage, width: 40, height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serviceName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('Filter: $selectedLocation'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildProductView(),
          ),
        ],
      ),

    );
  }
}