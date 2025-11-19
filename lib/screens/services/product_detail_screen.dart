import 'package:flutter/material.dart';
import 'package:services/models/product_model.dart';
import 'package:services/services/product_service.dart';
import 'package:services/utils/app_constants.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Product> sameVendorProducts = [];
  List<Product> nearbyProducts = [];

  @override
  void initState() {
    super.initState();
    _loadRelatedProducts();
  }

  Future<void> _loadRelatedProducts() async {
    final vendorProducts = await ProductService.getProductsByVendor(widget.product.vendorId);
    final categoryProducts = await ProductService.getProductsByCategory(widget.product.category);
    final locationProducts = await ProductService.getProductsByLocation(widget.product.location);
    
    setState(() {
      sameVendorProducts = vendorProducts.where((p) => p.id != widget.product.id).toList();
      
      // If no vendor products, show same category products from different vendors
      if (sameVendorProducts.isEmpty) {
        sameVendorProducts = categoryProducts.where((p) => 
          p.id != widget.product.id && p.vendorId != widget.product.vendorId
        ).take(5).toList();
      }
      
      nearbyProducts = locationProducts.where((p) => 
        p.id != widget.product.id && 
        p.vendorId != widget.product.vendorId &&
        p.category == widget.product.category
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.title),
        backgroundColor: AppConstants.appMainColour,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Icon(Icons.image, size: 100, color: Colors.grey),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.price,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.appMainColour,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 20),
                      const SizedBox(width: 8),
                      Text(widget.product.vendorName, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20),
                      const SizedBox(width: 8),
                      Text(widget.product.location),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(widget.product.contact),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.product.description),
                  
                  // Same Vendor Products
                  if (sameVendorProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      sameVendorProducts.any((p) => p.vendorId == widget.product.vendorId)
                          ? 'More from ${widget.product.vendorName}'
                          : 'Similar ${widget.product.category}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: sameVendorProducts.length,
                        itemBuilder: (context, index) {
                          final product = sameVendorProducts[index];
                          return Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              child: InkWell(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(product: product),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 80,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.image, size: 40, color: Colors.grey),
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
                                        product.price,
                                        style: const TextStyle(color: AppConstants.appMainColour),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  
                  // Nearby Similar Products
                  if (nearbyProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Similar ${widget.product.category} nearby',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: nearbyProducts.length,
                        itemBuilder: (context, index) {
                          final product = nearbyProducts[index];
                          return Container(
                            width: 150,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              child: InkWell(
                                onTap: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(product: product),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 80,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.image, size: 40, color: Colors.grey),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        product.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        product.vendorName,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        product.price,
                                        style: const TextStyle(color: AppConstants.appMainColour),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}