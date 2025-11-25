import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:services/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:services/controllers/auth_controller.dart';
import 'package:services/utils/app_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _profileImage;
  Position? _currentPosition;
  bool _isLoading = false;

  /// Pick image from gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  /// Get user's current location
  Future<void> _getLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition();
        Get.snackbar('Success', 'Location captured successfully');
      } catch (e) {
        Get.snackbar('Error', 'Failed to get location');
      }
    } else {
      Get.snackbar('Error', 'Location permission denied');
    }
  }

  /// Signup function with HTTP Multipart request
  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _currentPosition == null) {
      Get.snackbar("Error", "All fields including location are required");
      return;
    }

    setState(() => _isLoading = true);

    try {
      var url = Uri.parse("http://10.0.2.2:8080/api/accounts/signup/");
      var request = http.MultipartRequest("POST", url);

      // Add timeout
      request.fields["name"] = _nameController.text;
      request.fields["email"] = _emailController.text;
      request.fields["password"] = _passwordController.text;
      request.fields["phone"] = _phoneController.text;
      request.fields["latitude"] = _currentPosition!.latitude.toString();
      request.fields["longitude"] = _currentPosition!.longitude.toString();

      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            _profileImage!.path,
            filename: basename(_profileImage!.path),
          ),
        );
      }

      // Send with timeout
      var response = await request.send().timeout(const Duration(seconds: 30));
      var responseBody = await response.stream.bytesToString();

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success handling
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userEmail', _emailController.text);
        await prefs.setString('userName', _nameController.text);
        await prefs.setDouble('userLat', _currentPosition!.latitude);
        await prefs.setDouble('userLng', _currentPosition!.longitude);

        final authController = Get.find<AuthController>();
        await authController.checkLoginStatus();

        Get.snackbar("Success", "Account created successfully");
        Get.offAll(() => const HomeScreen());
      } else {
        Get.snackbar(
          "Error",
          "Server error: ${response.statusCode}\n$responseBody",
        );
      }
    } on SocketException {
      setState(() => _isLoading = false);
      Get.snackbar(
        "Connection Error",
        "Cannot connect to server. Please check:\n"
            "1. Server is running\n"
            "2. Correct IP address\n"
            "3. Network connection",
      );
    } on TimeoutException {
      setState(() => _isLoading = false);
      Get.snackbar("Timeout Error", "Server took too long to respond");
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Something went wrong: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : null,
                  child: _profileImage == null
                      ? const Icon(Icons.camera_alt, size: 30)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
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
                decoration: const InputDecoration(
                  labelText: 'Email',
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
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.location_on),
                  label: Text(
                    _currentPosition != null
                        ? 'Location Captured'
                        : 'Get Location',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentPosition != null
                        ? Colors.green
                        : AppConstants.appMainColour,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.appMainColour,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
