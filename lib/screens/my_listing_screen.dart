import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:services/models/product_model.dart';
import 'package:services/screens/product_detail_screen.dart';
import 'package:services/services/product_service.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyListingScreen extends StatefulWidget {
  const MyListingScreen({super.key});

  @override
  State<MyListingScreen> createState() => _MyListingScreenState();
}

class _MyListingScreenState extends State<MyListingScreen> {
  List<Product> allListings = [];
  List<Product> filteredListings = [];
  String selectedCategory = 'All';
  String selectedBusiness = 'All';
  List<String> userBusinesses = [];
  
  final List<String> categories = [
    'All', 'Room Finder', 'Food', 'Jobs', 'Bus', 'For Rent', 'Hostel & PG', 'Salon and Beauty', 'Laundry & Tailor'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserListings();
  }

  Future<void> _loadUserListings() async {
    final prefs = await SharedPreferences.getInstance();
    final userStoreName = prefs.getString('storeName') ?? '';
    
    final allProducts = await ProductService.getAllProducts();
    final userProducts = allProducts.where((product) => product.vendorName == userStoreName).toList();
    
    // Get unique businesses
    final businesses = userProducts.map((p) => p.vendorName).toSet().toList();
    
    setState(() {
      allListings = userProducts;
      filteredListings = userProducts;
      userBusinesses = ['All', ...businesses];
    });
  }

  void _applyFilters() {
    setState(() {
      filteredListings = allListings.where((product) {
        bool categoryMatch = selectedCategory == 'All' || product.category == selectedCategory;
        bool businessMatch = selectedBusiness == 'All' || product.vendorName == selectedBusiness;
        return categoryMatch && businessMatch;
      }).toList();
      
      filteredListings.sort((a, b) => b.id.compareTo(a.id));
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter My Listings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (value) => setState(() => selectedCategory = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedBusiness,
              decoration: const InputDecoration(labelText: 'Business', border: OutlineInputBorder()),
              items: userBusinesses.map((business) => DropdownMenuItem(value: business, child: Text(business))).toList(),
              onChanged: (value) => setState(() => selectedBusiness = value!),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedCategory = 'All';
                        selectedBusiness = 'All';
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('Apply', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Room Finder':
        return Icons.home;
      case 'Food':
        return Icons.restaurant;
      case 'Jobs':
        return Icons.work;
      case 'Bus':
        return Icons.directions_bus;
      case 'For Rent':
        return Icons.key;
      case 'Hostel & PG':
        return Icons.hotel;
      case 'Salon and Beauty':
        return Icons.content_cut;
      case 'Laundry & Tailor':
        return Icons.local_laundry_service;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text('${allListings.length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const Text('Total Listings', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('${userBusinesses.length - 1}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const Text('Businesses', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Column(
                  children: [
                    Text('${categories.where((cat) => allListings.any((p) => p.category == cat)).length}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const Text('Categories', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          
          // Listings Grid
          Expanded(
            child: filteredListings.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list_alt, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No listings found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        Text('Start posting to see your listings here', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredListings.length,
                    itemBuilder: (context, index) {
                      final product = filteredListings[index];
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
                                  child: Icon(
                                    _getCategoryIcon(product.category),
                                    size: 40,
                                    color: AppConstants.appMainColour,
                                  ),
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
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                Text(
                                  product.vendorName,
                                  style: const TextStyle(fontSize: 12, color: AppConstants.appMainColour),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      product.price,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.appMainColour,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 12),
                                        Text('${product.rating}', style: const TextStyle(fontSize: 10)),
                                      ],
                                    ),
                                  ],
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