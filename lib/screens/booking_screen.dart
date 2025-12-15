import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:services/screens/item_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../models/product_model.dart';
import '../constants/api.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  List<Product> likedProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLikedProducts();
  }

  Future<void> fetchLikedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    print(token);
    if (token == null) return;

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/api/categories/liked-products/",
    );
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    print(url);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        likedProducts = data.map((json) => Product.fromJson(json)).toList();
        isLoading = false;
      });
    } else {
      print("Failed to fetch liked products: ${response.body}");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (likedProducts.isEmpty) {
      return const Center(child: Text("No liked products yet."));
    }

    return ListView.builder(
      itemCount: likedProducts.length,
      itemBuilder: (context, index) {
        final product = likedProducts[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  "${ApiConfig.baseUrl}${product.images.isNotEmpty ? product.images[0] : ''}",
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(product.title),
              subtitle: Text("Rs. ${product.price}"),
              trailing: Icon(Icons.favorite, color: Colors.red),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(product: product),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
