import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:services/screens/add_product_screen.dart';
import 'package:services/screens/my_product_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart'; 

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? userData;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customLocationController = TextEditingController();

  File? _profileImage;
  Position? _currentPosition;
  String _selectedLocationType = 'current';

  int? _userId;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('userEmail');

      if (userEmail == null) {
        Get.snackbar("Error", "User email not found");
        return;
      }

      final headers = await AuthService.getAuthHeaders();

      final userRes = await http.get(
        Uri.parse(
          "http://10.0.2.2:8080/api/accounts/get-user-id/?email=$userEmail",
        ),
        headers: headers,
      );

      if (userRes.statusCode != 200) {
        if (userRes.statusCode == 401) {
          Get.snackbar("Error", "Authentication failed. Please login again.");
          return;
        }
        Get.snackbar("Error", "Failed to fetch user ID: ${userRes.statusCode}");
        return;
      }

      _userId = jsonDecode(userRes.body)["user_id"];

      final profileRes = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/accounts/profile/$_userId/"),
        headers: headers,
      );

      if (profileRes.statusCode == 200) {
        userData = jsonDecode(profileRes.body);

        _nameController.text = userData!["name"] ?? '';
        _phoneController.text = userData!["phone"] ?? '';
        if (userData!["latitude"] != null && userData!["longitude"] != null) {
          _currentPosition = Position(
            latitude: userData!["latitude"],
            longitude: userData!["longitude"],
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        } else if (userData!["custom_location"] != null) {
          _selectedLocationType = 'custom';
          _customLocationController.text = userData!["custom_location"];
        }

        setState(() => _isLoading = false);
      } else {
        Get.snackbar(
          "Error",
          "Failed to load profile: ${profileRes.statusCode}",
        );
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition();
        Get.snackbar('Success', 'Current location captured');
        setState(() {});
      } catch (e) {
        Get.snackbar('Error', 'Failed to get location');
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) {
      Get.snackbar('Error', 'Name and phone are required');
      return;
    }

    if (_selectedLocationType == 'current' && _currentPosition == null) {
      Get.snackbar('Error', 'Please capture current location');
      return;
    }

    if (_selectedLocationType == 'custom' &&
        _customLocationController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter custom location');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final headers = await AuthService.getAuthHeadersMultipart();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.0.2.2:8080/api/accounts/profile-update/$_userId/"),
      );

      request.headers.addAll(headers);

      request.fields['name'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;

      if (_selectedLocationType == 'current' && _currentPosition != null) {
        request.fields['latitude'] = _currentPosition!.latitude.toString();
        request.fields['longitude'] = _currentPosition!.longitude.toString();
        request.fields['custom_location'] = '';
      } else {
        request.fields['custom_location'] = _customLocationController.text;
        request.fields['latitude'] = '';
        request.fields['longitude'] = '';
      }

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _profileImage!.path,
          ),
        );
      }

      final response = await request.send();
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Profile updated successfully');
        _fetchProfile();
      } else {
        final responseBody = await response.stream.bytesToString();
        Get.snackbar(
          'Error',
          'Failed to update profile: ${response.statusCode}',
        );
        print('Error response: $responseBody');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile Setup",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap:() => Get.to(() => const VendorProductScreen()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      "assets/images/add-to-cart (1).png",
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                 
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : (userData!["profile_image"] != null
                                  ? NetworkImage(
                                      "http://10.0.2.2:8080${userData!["profile_image"]}",
                                    )
                                  : const AssetImage("assets/profile.png")
                                        as ImageProvider),
                        child:
                            _profileImage == null &&
                                userData!["profile_image"] == null
                            ? Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey.shade700,
                              )
                            : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Name
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: const Icon(Icons.person),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Phone
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Location Type',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        RadioListTile<String>(
                          title: const Text('Use Current Location'),
                          value: 'current',
                          groupValue: _selectedLocationType,
                          activeColor: Colors.teal,
                          onChanged: (value) =>
                              setState(() => _selectedLocationType = value!),
                        ),

                        if (_selectedLocationType == 'current')
                          Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location),
                              label: Text(
                                _currentPosition != null
                                    ? 'Location Captured'
                                    : 'Get Current Location',
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                backgroundColor: _currentPosition != null
                                    ? Colors.green
                                    : Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),

                        // Radio 2
                        RadioListTile<String>(
                          title: const Text('Enter Custom Location'),
                          value: 'custom',
                          groupValue: _selectedLocationType,
                          activeColor: Colors.blueAccent,
                          onChanged: (value) =>
                              setState(() => _selectedLocationType = value!),
                        ),

                        if (_selectedLocationType == 'custom')
                          TextField(
                            controller: _customLocationController,
                            decoration: InputDecoration(
                              labelText: 'Enter Custom Location',
                              prefixIcon: const Icon(Icons.location_on),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Save Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}
