import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:services/models/product_model.dart';
import 'package:services/screens/item_details_screen.dart';
import 'package:services/utils/app_constants.dart';

import '../constants/api.dart';

class FeaturedServiceScreen extends StatefulWidget {
  const FeaturedServiceScreen({super.key});

  @override
  State<FeaturedServiceScreen> createState() => _FeaturedServiceScreenState();
}

class _FeaturedServiceScreenState extends State<FeaturedServiceScreen> {
  bool isLoading = true;
  List featuredProducts = [];

  @override
  void initState() {
    super.initState();
    fetchFeaturedProducts();
  }

  Future<void> fetchFeaturedProducts() async {
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/categories/products/featured/"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          featuredProducts = data;
          isLoading = false;
        });
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching featured products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            title: const Text(
              "Featured Services",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.appTextColour,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppConstants.appMainColour,
            elevation: 0,
            iconTheme: IconThemeData(color: AppConstants.appTextColour),
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : featuredProducts.isEmpty
              ? const Center(child: Text("No Featured Products"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: featuredProducts.length,
itemBuilder: (context, index) {
  final product = Product.fromJson(featuredProducts[index]);

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      Get.to(() => ProductDetailsScreen(product: product));
    },
    child: ServiceTableRow(
      title: product.title,
      subtitle: product.description,
      image: product.images.isEmpty
          ? "https://via.placeholder.com/150"
          : "${ApiConfig.baseUrl}${product.images[0]}",
      rating: product.rating,
    ),
  );
},
                ),
    );
  }
}

class ServiceTableRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final double rating;

  const ServiceTableRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              image,
              height: 70,
              width: 70,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                rating.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
