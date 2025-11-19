import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:services/controllers/auth_controller.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _customLocationController = TextEditingController();
  File? _profileImage;
  File? _businessImage;
  Position? _currentPosition;
  String _selectedLocationType = 'current';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _nameController.text = prefs.getString('userName') ?? '';
    _emailController.text = prefs.getString('userEmail') ?? '';
    _phoneController.text = prefs.getString('userPhone') ?? '';
    _storeNameController.text = prefs.getString('storeName') ?? '';
    _customLocationController.text = prefs.getString('customLocation') ?? '';
    _selectedLocationType = prefs.getString('locationType') ?? 'current';
  }

  Future<void> _pickProfileImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<void> _pickBusinessImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _businessImage = File(image.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition();
        Get.snackbar('Success', 'Location captured');
      } catch (e) {
        Get.snackbar('Error', 'Failed to get location');
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userPhone', _phoneController.text);
    await prefs.setString('storeName', _storeNameController.text);
    await prefs.setString('locationType', _selectedLocationType);
    
    if (_selectedLocationType == 'current' && _currentPosition != null) {
      await prefs.setDouble('storeLat', _currentPosition!.latitude);
      await prefs.setDouble('storeLng', _currentPosition!.longitude);
    } else {
      await prefs.setString('customLocation', _customLocationController.text);
    }

    if (_profileImage != null) {
      await prefs.setString('profileImagePath', _profileImage!.path);
    }
    if (_businessImage != null) {
      await prefs.setString('businessImagePath', _businessImage!.path);
    }

    final authController = Get.find<AuthController>();
    await authController.checkLoginStatus();

    setState(() => _isLoading = false);
    Get.back();
    Get.snackbar('Success', 'Profile updated successfully!', backgroundColor: Colors.green, colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppConstants.appMainColour,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickProfileImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null ? const Icon(Icons.person, size: 40) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email (Cannot be changed)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Business Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: _pickBusinessImage,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _businessImage != null ? FileImage(_businessImage!) : null,
                  child: _businessImage == null ? const Icon(Icons.business, size: 30) : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Business/Store Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Business Location:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: const Text('Use Current Location'),
              value: 'current',
              groupValue: _selectedLocationType,
              onChanged: (value) => setState(() => _selectedLocationType = value!),
            ),
            if (_selectedLocationType == 'current')
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_currentPosition != null ? 'Location Captured' : 'Get Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentPosition != null ? Colors.green : AppConstants.appMainColour,
                  foregroundColor: Colors.white,
                ),
              ),
            RadioListTile<String>(
              title: const Text('Custom Location'),
              value: 'custom',
              groupValue: _selectedLocationType,
              onChanged: (value) => setState(() => _selectedLocationType = value!),
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
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.appMainColour,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}