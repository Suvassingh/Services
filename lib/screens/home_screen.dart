import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:services/screens/booking_screen.dart';
import 'package:services/screens/featured_service_screen.dart';
import 'package:services/screens/profile_screen.dart';
import 'package:services/screens/search_screen.dart';
import 'package:services/utils/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // final List<Map<String, dynamic>> services = [
  //   {'name': 'Room Finder', 'icon': Image.asset('assets/images/house.png'),},
  //   {'name': 'Food', 'icon': Image.asset('assets/images/food.png'), },
  //   {'name': 'Jobs', 'icon': Image.asset('assets/images/jobs.png'), },
  //   {'name': 'Bus', 'icon': Image.asset('assets/images/bus.png'), },
  //   {'name': 'For Rent', 'icon': Image.asset('assets/images/for_rent.png'), },
  //   {'name': 'Hostel & PG', 'icon': Image.asset('assets/images/hostel.png'), },
  //   {'name': 'Salon and Beauty', 'icon': Image.asset('assets/images/salon.png'), },
  //   {
  //     'name': 'Laundry & Tailor',
  //     'icon': Image.asset('assets/images/laundry.png'),
  //   },
  // ];

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const BookingsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Local Connect',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.appTextColour),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppConstants.appTextColour,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat, color: AppConstants.appTextColour),
            onPressed: () {},
          ),
        ],
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
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
 final List<Map<String, dynamic>> services = [
      {'name': 'Room Finder', 'image': 'assets/images/house.png'},
      {'name': 'Food', 'image': 'assets/images/food.png'},
      {'name': 'Jobs', 'image': 'assets/images/businessman.png'},
      {'name': 'Bus', 'image': 'assets/images/bus.png'},
      {'name': 'For Rent', 'image': 'assets/images/rent.png'},
      {'name': 'Hostel & PG', 'image': 'assets/images/hostel.png'},
      {'name': 'Salon and Beauty', 'image': 'assets/images/salon.png'},
      {'name': 'Laundry & Tailor', 'image': 'assets/images/laundry-machine.png'},
    ];
    return SingleChildScrollView(
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for services...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 20,
                ),
              ),
            ),
          ),

          // Services Grid
   Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                return ServiceCard(
                  name: service['name'],
                  imagePath: service['image'],
                );
              },
            ),
          ),

          // Featured Section
           Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(
                'Featured Services',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                  onPressed: () {
                    Get.offAll(() =>FeaturedServiceScreen());
                  },
                  child: Text(
                    "View more",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.appMainColour,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )

              
              ],
              
            ),
          ),

          // Featured Services Horizontal List
          SizedBox(
            height: 210,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              children: [
                FeaturedCard(
                  title: 'Premium Rooms',
                  subtitle: 'Luxury apartments',
                  image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpRZIS3qMvdnQHzrgylZ-ym9WYike4S3yvWA&s',
                  rating: 4.5,
                ),
                FeaturedCard(
                  title: 'Food Delivery',
                  subtitle: 'Fast & Fresh',
                  image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRE2Lbb_eK4FIe1eeFG8kZ0Hx1CIHxO7F8__g&s',
                  rating: 4.8,
                ),
                FeaturedCard(
                  title: 'Job Fair',
                  subtitle: 'Hiring now',
                  image: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSGuoCCTVzjyZmhXylITPpju2BeuOeGJihhgQ&s',
                  rating: 4.3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ServiceCard extends StatelessWidget {
  final String name;
  final String imagePath;

  const ServiceCard({super.key, required this.name, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle tap
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100], 
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.error_outline,
                ); 
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
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






