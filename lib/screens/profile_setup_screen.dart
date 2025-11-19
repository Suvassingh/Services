import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:services/screens/home_screen.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customLocationController = TextEditingController();
  File? _profileImage;
  Position? _currentPosition;
  String _selectedLocationType = 'current';
  bool _isLoading = false;

  Future<void> _getCurrentLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition();
        Get.snackbar('Success', 'Current location captured');
      } catch (e) {
        Get.snackbar('Error', 'Failed to get location');
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    if (_storeNameController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter store name');
      return;
    }
    
    if (_phoneController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter phone number');
      return;
    }

    if (_selectedLocationType == 'current' && _currentPosition == null) {
      Get.snackbar('Error', 'Please capture current location');
      return;
    }

    if (_selectedLocationType == 'custom' && _customLocationController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter custom location');
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeName', _storeNameController.text);
    await prefs.setString('userPhone', _phoneController.text);
    await prefs.setString('locationType', _selectedLocationType);
    
    if (_selectedLocationType == 'current' && _currentPosition != null) {
      await prefs.setDouble('storeLat', _currentPosition!.latitude);
      await prefs.setDouble('storeLng', _currentPosition!.longitude);
    } else {
      await prefs.setString('customLocation', _customLocationController.text);
    }

    setState(() => _isLoading = false);
    Get.offAll(() => const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        backgroundColor: AppConstants.appMainColour,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null 
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Store/Business Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select Location Type:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              title: const Text('Enter Custom Location'),
              value: 'custom',
              groupValue: _selectedLocationType,
              onChanged: (value) => setState(() => _selectedLocationType = value!),
            ),
            if (_selectedLocationType == 'custom')
              TextField(
                controller: _customLocationController,
                decoration: const InputDecoration(
                  labelText: 'Enter Location (e.g., City Center, Downtown)',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.appMainColour,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Complete Setup'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}