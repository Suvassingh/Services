






import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:services/constants/api.dart';
import 'package:services/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:services/controllers/auth_controller.dart';
import 'package:services/utils/app_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _profileImage;
  Position? _currentPosition;

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  Future<void> _getLocation() async {
    final permission = await Permission.location.request();

    if (permission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition();
        Get.snackbar("Success", "Location captured successfully");
      } catch (e) {
        Get.snackbar("Error", "Failed to get location");
      }
    } else {
      Get.snackbar("Error", "Location permission denied");
    }
  }

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
      var url = Uri.parse("${ApiConfig.baseUrl}/api/accounts/signup/");
      var request = http.MultipartRequest("POST", url);

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

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("accessToken", data["tokens"]["access"]);
        await prefs.setString("refreshToken", data["tokens"]["refresh"]);

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
        Get.snackbar("Error", "Server error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      Get.snackbar("Error", "Something went wrong: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppConstants.appMainColour.withOpacity(0.1),
              Colors.white,
              AppConstants.appMainColour.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ScaleTransition(
                      scale: Tween(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : null,
                            child: _profileImage == null
                                ? const Icon(
                                    Icons.camera_alt,
                                    size: 35,
                                    color: Colors.black54,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Icon(
                                Icons.edit,
                                color: AppConstants.appMainColour,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  _buildField(
                    controller: _nameController,
                    hint: "Full Name",
                    icon: Icons.person,
                  ),

                  const SizedBox(height: 20),

                  _buildField(
                    controller: _emailController,
                    hint: "Email",
                    icon: Icons.email,
                    keyboard: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 20),

                  _buildField(
                    controller: _phoneController,
                    hint: "Phone Number",
                    icon: Icons.phone,
                    keyboard: TextInputType.phone,
                  ),

                  const SizedBox(height: 20),

                  _buildField(
                    controller: _passwordController,
                    hint: "Password",
                    icon: Icons.lock,
                    isPassword: true,
                    obscure: _obscurePassword,
                    onSuffixTap: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _getLocation,
                      icon: const Icon(Icons.location_on),
                      label: Text(
                        _currentPosition != null
                            ? "Location Captured"
                            : "Get Location",
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentPosition != null
                            ? Colors.green
                            : AppConstants.appMainColour,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.appMainColour,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.person_add),
                                SizedBox(width: 10),
                                Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 15,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.back(),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              color: AppConstants.appMainColour,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onSuffixTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppConstants.appMainColour),
          suffixIcon: isPassword
              ? IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
