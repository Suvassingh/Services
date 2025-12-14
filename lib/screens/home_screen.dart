import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:services/models/product_model.dart';
import 'package:services/screens/booking_screen.dart';
import 'package:services/screens/featured_service_screen.dart';
import 'package:services/screens/item_details_screen.dart';
import 'package:services/screens/notification_screen.dart';

import 'package:services/screens/profile_setup_screen.dart';
import 'package:services/screens/search_screen.dart';
import 'package:services/screens/item_list_category.dart';
import 'package:services/utils/app_constants.dart';

import '../models/category_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;


  final List<Widget> _pages = [
    const HomePage(),
    const SearchProductsPage(),
    const BookingScreen(),
    const ProfileSetupScreen(),
  ];

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
              'Local Connect',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.appTextColour,
              ),
            ),
            backgroundColor: Colors.teal,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(
                    Icons.notifications,
                    color: AppConstants.appTextColour,
                  ),
                  onPressed: () {
                    Get.to(() => NotificationScreen());
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Favourites',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<CategoryModel> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchFeaturedProducts();
  }

  Future<void> fetchCategories() async {
    try {
      final res = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/categories/categories/"),
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);

        setState(() {
          categories = data
              .map((json) => CategoryModel.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        print("Error: ${res.statusCode}");
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }
  void _onCategoryTap(CategoryModel category) {
    Get.to(() => CategoryServicesScreen(category: category,
    

    ));
  }
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 5,
                          childAspectRatio: 0.7,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];

                      return ServiceCard(
                        name: cat.title,
                        imageUrl:
                        "http://10.0.2.2:8080${cat.icon}",
                        onTap: () => _onCategoryTap(cat),
                      );
                    },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Featured Services',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Get.to(() => FeaturedServiceScreen());
                  },
                  child: Text(
                    "View more",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.appMainColour,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
SizedBox(height: 8),
          _buildFeaturedList(),
        ],
      ),
    );
  }
List<Product> featuredProducts = [];
  bool isFeaturedLoading = true;

  Future<void> fetchFeaturedProducts() async {
    try {
      final res = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/categories/products/featured/"),
      );

      if (res.statusCode == 200) {
        List data = jsonDecode(res.body);
        setState(() {
          featuredProducts = data
              .map((json) => Product.fromJson(json))
              .toList();
          isFeaturedLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching featured: $e");
    }
  }

  
Widget _buildFeaturedList() {
    if (isFeaturedLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (featuredProducts.isEmpty) {
      return const Center(child: Text("No featured products found."));
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        itemCount: featuredProducts.length,
        itemBuilder: (context, index) {
          final p = featuredProducts[index];
          String img = p.images.isNotEmpty
              ? "http://10.0.2.2:8080${p.images[0]}"
              : "https://via.placeholder.com/150";

         return GestureDetector(
            onTap: () {
              Get.to(() => ProductDetailsScreen(product: p));
            },
            child: FeaturedCard(
              title: p.title,
              subtitle: p.description,
              image: img,
              rating: p.rating,
            ),
          );
        },
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 150,
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                fit:BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error_outline, size: 30);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 1));
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}



class FeaturedCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final double rating;

  const FeaturedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              image,
              width: 140,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 140,
                  height: 100,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
