import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:services/models/product_model.dart';
import 'package:services/screens/services/product_detail_screen.dart';
import 'package:services/services/product_service.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String vendorName;

  const BusinessProfileScreen({super.key, required this.vendorName});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  List<Product> vendorProducts = [];
  String? businessImagePath;

  @override
  void initState() {
    super.initState();
    _loadVendorData();
  }

  Future<void> _loadVendorData() async {
    final products = await ProductService.getProductsByVendor(widget.vendorName);
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('storeName') ?? '';
    
    setState(() {
      vendorProducts = products;
      if (widget.vendorName == storeName) {
        businessImagePath = prefs.getString('businessImagePath');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vendorName),
        backgroundColor: AppConstants.appMainColour,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.grey[100],
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppConstants.appMainColour,
                  backgroundImage: businessImagePath != null ? FileImage(File(businessImagePath!)) : null,
                  child: businessImagePath == null 
                      ? Text(widget.vendorName[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.vendorName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('${vendorProducts.length} Products'),
                      if (vendorProducts.isNotEmpty)
                        Text('Location: ${vendorProducts.first.location}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: vendorProducts.isEmpty
                ? const Center(child: Text('No products found'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: vendorProducts.length,
                    itemBuilder: (context, index) {
                      final product = vendorProducts[index];
                      return Card(
                        child: InkWell(
                          onTap: () => Get.to(() => ProductDetailScreen(product: product)),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                const SizedBox(height: 8),
                                Text(
                                  product.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  product.category,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const Spacer(),
                                Text(
                                  product.price,
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
                  ),
          ),
        ],
      ),
    );
  }
}