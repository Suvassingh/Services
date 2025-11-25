import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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

      // 1️⃣ Get user ID
      final userRes = await http.get(
        Uri.parse(
          "http://10.0.2.2:8080/api/accounts/get-user-id/?email=$userEmail",
        ),
      );

      if (userRes.statusCode != 200) {
        Get.snackbar("Error", "Failed to fetch user ID");
        return;
      }

      _userId = jsonDecode(userRes.body)["user_id"];

      // 2️⃣ Get profile data
      final profileRes = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/accounts/profile/$_userId/"),
      );

      if (profileRes.statusCode == 200) {
        userData = jsonDecode(profileRes.body);

        // Fill text controllers
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
        Get.snackbar("Error", "Failed to load profile");
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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("http://10.0.2.2:8080/api/accounts/profile-update/$_userId/"),
      );

      request.fields['name'] = _nameController.text;
      request.fields['phone'] = _phoneController.text;

      if (_selectedLocationType == 'current' && _currentPosition != null) {
        request.fields['latitude'] = _currentPosition!.latitude.toString();
        request.fields['longitude'] = _currentPosition!.longitude.toString();
      } else {
        request.fields['custom_location'] = _customLocationController.text;
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
        Get.snackbar('Error', 'Failed to update profile');
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
      appBar: AppBar(title: const Text("Profile Setup"), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
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
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Select Location Type:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile<String>(
                    title: const Text('Use Current Location'),
                    value: 'current',
                    groupValue: _selectedLocationType,
                    onChanged: (value) =>
                        setState(() => _selectedLocationType = value!),
                  ),
                  if (_selectedLocationType == 'current')
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: Text(
                        _currentPosition != null
                            ? 'Location Captured'
                            : 'Get Current Location',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPosition != null
                            ? Colors.green
                            : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  RadioListTile<String>(
                    title: const Text('Enter Custom Location'),
                    value: 'custom',
                    groupValue: _selectedLocationType,
                    onChanged: (value) =>
                        setState(() => _selectedLocationType = value!),
                  ),
                  if (_selectedLocationType == 'custom')
                    TextField(
                      controller: _customLocationController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
