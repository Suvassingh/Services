import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:services/screens/add_product_screen.dart';
import 'package:services/screens/edit_product_screen.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api.dart';

class VendorProductScreen extends StatefulWidget {
  const VendorProductScreen({super.key});

  @override
  State<VendorProductScreen> createState() => _VendorProductScreenState();
}

class _VendorProductScreenState extends State<VendorProductScreen> {
  List products = [];
  bool isLoading = true;
  late int userId;
  late String token;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id')!;
    token = prefs.getString("accessToken") ?? "";

    fetchVendorProducts();
  }

  Future<void> fetchVendorProducts() async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/categories/vendor/products/",
      );
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/categories/product/$id/delete/",
      );
      final response = await http.delete(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        Get.snackbar(
          "Success",
          "Product Deleted",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        fetchVendorProducts();
      } else {
        Get.snackbar(
          "Error",
          "Unable to delete",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
              "Products",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.appTextColour,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppConstants.appMainColour,
            elevation: 0,
            iconTheme: IconThemeData(color: AppConstants.appTextColour),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Get.to(() => const AddProductPage())!.then((value) {
                      fetchVendorProducts(); 
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
          ? const Center(child: Text("No products found"))
          : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final p = products[index];
                String? imageUrl;
                if (p["images"] != null &&
                    p["images"].isNotEmpty &&
                    p["images"][0] != null) {
                  String imgPath = p["images"][0];
                  imageUrl = "${ApiConfig.baseUrl}$imgPath";

                  print("IMAGE URL: $imageUrl"); 
                }

                return Slidable(
                  key: ValueKey(p["id"]),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => deleteProduct(p["id"]),
                        backgroundColor: Colors.red,
                        icon: Icons.delete,
                        label: "Delete",
                      ),
                    ],
                  ),

                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Card(
                      child: ListTile(
                        leading: imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.broken_image),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.image_not_supported),
                              ),
                      
                        title: Text(p["title"] ?? "No Title"),
                        subtitle: Text("Rs. ${p["price"] ?? "0"}"),
                        trailing: p["featured"] == true
                            ? const Text(
                                "Featured",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                ),
                              )
                            : null,
                        onTap: () {
                          Get.to(() => EditProductPage(productId: p["id"]))!.then((
                            value,
                          ) {
                            fetchVendorProducts(); 
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
