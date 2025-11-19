import 'dart:convert';
import 'package:services/models/product_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductService {
  static const String _productsKey = 'user_products';

  static Future<List<Product>> getUserProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail') ?? '';
    final productsJson = prefs.getStringList(_productsKey) ?? [];
    
    return productsJson
        .map((json) => Product.fromJson(jsonDecode(json)))
        .where((product) => product.vendorId == userEmail)
        .toList();
  }

  static Future<List<Product>> getAllProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getStringList(_productsKey) ?? [];
    
    return productsJson
        .map((json) => Product.fromJson(jsonDecode(json)))
        .toList();
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getAllProducts();
    return products.where((p) => p.category == category).toList();
  }

  static Future<List<Product>> getProductsByVendor(String vendorId) async {
    final products = await getAllProducts();
    return products.where((p) => p.vendorId == vendorId).toList();
  }

  static Future<List<Product>> getProductsByLocation(String location) async {
    final products = await getAllProducts();
    return products.where((p) => p.location == location).toList();
  }

  static Future<void> addProduct(Product product) async {
    final prefs = await SharedPreferences.getInstance();
    final productsJson = prefs.getStringList(_productsKey) ?? [];
    
    productsJson.add(jsonEncode(product.toJson()));
    await prefs.setStringList(_productsKey, productsJson);
  }

  static Future<void> initializeDummyData() async {
    final products = await getAllProducts();
    if (products.isNotEmpty) return;

    final dummyProducts = [
      Product(
        id: '1',
        title: 'Luxury Room',
        description: 'Spacious room with AC',
        price: '₹5000',
        category: 'Room Finder',
        vendorId: 'vendor1@example.com',
        vendorName: 'Premium Stays',
        location: 'Near Me',
        contact: '+91 9876543210',
        images: ['assets/images/house.png'],
        rating: 4.5,
      ),
      Product(
        id: '2',
        title: 'Budget Room',
        description: 'Clean and affordable',
        price: '₹2000',
        category: 'Room Finder',
        vendorId: 'vendor1@example.com',
        vendorName: 'Premium Stays',
        location: 'Near Me',
        contact: '+91 9876543210',
        images: ['assets/images/house.png'],
        rating: 4.2,
      ),
      Product(
        id: '3',
        title: 'Delicious Pizza',
        description: 'Fresh and hot pizza',
        price: '₹300',
        category: 'Food',
        vendorId: 'vendor2@example.com',
        vendorName: 'Food Corner',
        location: 'City Center',
        contact: '+91 9876543211',
        images: ['assets/images/food.png'],
        rating: 4.8,
      ),
    ];

    for (final product in dummyProducts) {
      await addProduct(product);
    }
  }
}