import 'package:flutter/material.dart';
import 'package:services/utils/app_constants.dart';

class FeaturedServiceScreen extends StatelessWidget {
  const FeaturedServiceScreen({super.key});

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
            backgroundColor: AppConstants.appMainColour,
            elevation: 0,
            iconTheme: IconThemeData(color: AppConstants.appTextColour),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ServiceTableRow(
            title: "Premium Rooms",
            subtitle: "Luxury apartments",
            rating: 4.5,
            image:
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpRZIS3qMvdnQHzrgylZ-ym9WYike4S3yvWA&s",
          ),
          ServiceTableRow(
            title: "Food Delivery",
            subtitle: "Fast & Fresh",
            rating: 4.8,
            image:
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRE2Lbb_eK4FIe1eeFG8kZ0Hx1CIHxO7F8__g&s",
          ),
          ServiceTableRow(
            title: "Job Fair",
            subtitle: "Hiring now",
            rating: 4.3,
            image:
                "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSGuoCCTVzjyZmhXylITPpju2BeuOeGJihhgQ&s",
          ),
        ],
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
          // Image
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

          // Title + Subtitle
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
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),

          // Rating
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
