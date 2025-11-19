import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:services/screens/booking_screen.dart';
import 'package:services/screens/featured_service_screen.dart';
import 'package:services/screens/profile_screen.dart';
import 'package:services/screens/search_screen.dart';
import 'package:services/utils/app_constants.dart';
import 'package:services/widgets/featured_widget.dart';
import 'package:services/widgets/service_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const BookingsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
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
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  color: AppConstants.appTextColour,
                ),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: AppConstants.appTextColour),
                onPressed: () {},
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
      {
        'name': 'Laundry & Tailor',
        'image': 'assets/images/laundry-machine.png',
      },
    ];
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 16),
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
                    Get.to(() => FeaturedServiceScreen());
                  },
                  child: Text(
                    "View more",
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.appMainColour,
                      decoration: TextDecoration.underline,
                      decorationColor: AppConstants.appSecondaryColour
                    ),
                  ),
                ),
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
                  image:
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRpRZIS3qMvdnQHzrgylZ-ym9WYike4S3yvWA&s',
                  rating: 4.5,
                ),
                FeaturedCard(
                  title: 'Food Delivery',
                  subtitle: 'Fast & Fresh',
                  image:
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRE2Lbb_eK4FIe1eeFG8kZ0Hx1CIHxO7F8__g&s',
                  rating: 4.8,
                ),
                FeaturedCard(
                  title: 'Job Fair',
                  subtitle: 'Hiring now',
                  image:
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSGuoCCTVzjyZmhXylITPpju2BeuOeGJihhgQ&s',
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

