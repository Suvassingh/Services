import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:services/models/product_model.dart';
import 'package:services/services/product_service.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddServiceScreen extends StatefulWidget {
  final String serviceCategory;

  const AddServiceScreen({super.key, required this.serviceCategory});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();
  final _vendorNameController = TextEditingController();
  List<File> _images = [];
  Position? _currentPosition;
  String _selectedLocation = 'store';
  final _customLocationController = TextEditingController();
  bool _isLoading = false;
  List<Product> _userProducts = [];
  List<String> _existingGroups = [];
  String? _selectedGroup;
  bool _showLinkOption = false;
  bool _createNewGroup = true;

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('storeName') ?? 'My Store';
    
    final allUserProducts = await ProductService.getUserProducts();
    _userProducts = allUserProducts.where((p) => p.category == widget.serviceCategory).toList();
    
    // Extract unique vendor groups and always include store name
    _existingGroups = _userProducts.map((p) => p.vendorName).toSet().toList();
    if (!_existingGroups.contains(storeName)) {
      _existingGroups.insert(0, storeName);
    }
    
    setState(() {
      _showLinkOption = true; // Always show since we have store name
      _createNewGroup = false; // Default to existing business
      _selectedGroup = storeName; // Default to store name
    });
  }

  Future<void> _getLocation() async {
    final permission = await Permission.location.request();
    if (permission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        Get.snackbar(
          'Success', 
          'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        Get.snackbar('Error', 'Failed to get location: $e');
      }
    } else {
      Get.snackbar('Error', 'Location permission denied');
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty && images.length <= 5) {
      setState(() {
        _images = images.map((image) => File(image.path)).toList();
      });
    } else if (images.length > 5) {
      Get.snackbar('Error', 'Maximum 5 images allowed');
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null && _images.length < 5) {
      setState(() {
        _images.add(File(image.path));
      });
    } else if (_images.length >= 5) {
      Get.snackbar('Error', 'Maximum 5 images allowed');
    }
  }

  Future<void> _submitService() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty || _contactController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }
    
    if (_createNewGroup && _vendorNameController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter vendor/group name');
      return;
    }
    
    if (!_createNewGroup && _selectedGroup == null) {
      Get.snackbar('Error', 'Please select existing business');
      return;
    }

    if (_selectedLocation == 'current' && _currentPosition == null) {
      Get.snackbar('Error', 'Please capture current location');
      return;
    }
    
    if (_selectedLocation == 'custom' && _customLocationController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter custom location');
      return;
    }

    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail') ?? '';
    final storeName = prefs.getString('storeName') ?? 'My Store';
    
    String productLocation = _selectedLocation == 'store' 
        ? (prefs.getString('customLocation') ?? 'Store Location')
        : _selectedLocation == 'current' 
            ? 'Current Location'
            : _customLocationController.text;
    
    String vendorName = _createNewGroup ? _vendorNameController.text : _selectedGroup!;
    String contact = _contactController.text;
    
    // If using existing group, get details from first product in that group
    if (!_createNewGroup && _selectedGroup != null) {
      final groupProducts = _userProducts.where((p) => p.vendorName == _selectedGroup).toList();
      if (groupProducts.isNotEmpty) {
        final groupProduct = groupProducts.first;
        contact = groupProduct.contact;
        productLocation = groupProduct.location;
      }
      // If no products exist for this group (store name), use current form values
    }
    
    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      price: '₹${_priceController.text}',
      category: widget.serviceCategory,
      vendorId: userEmail,
      vendorName: vendorName,
      location: productLocation,
      contact: contact,
      images: _images.map((img) => img.path).toList(),
    );
    
    await ProductService.addProduct(product);
    
    setState(() => _isLoading = false);
    Get.back();
    Get.snackbar(
      'Success', 
      'Service posted successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.serviceCategory}'),
        backgroundColor: AppConstants.appMainColour,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Service Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Images: ${_images.length}/5', style: const TextStyle(color: Colors.grey)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text('Business Group:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('Use Existing Business'),
                        value: false,
                        groupValue: _createNewGroup,
                        onChanged: (value) => setState(() => _createNewGroup = value!),
                      ),
                      RadioListTile<bool>(
                        title: const Text('Create New Business'),
                        value: true,
                        groupValue: _createNewGroup,
                        onChanged: (value) => setState(() => _createNewGroup = value!),
                      ),
                    ],
                  ),
                ),
                if (!_createNewGroup)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedGroup,
                        decoration: const InputDecoration(
                          labelText: 'Select Business',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _existingGroups.map((group) => DropdownMenuItem(
                          value: group,
                          child: Text(group),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedGroup = value),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: _vendorNameController,
                        decoration: const InputDecoration(
                          labelText: 'New Business Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Select Location:', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioListTile<String>(
              title: const Text('Use Store Location'),
              value: 'store',
              groupValue: _selectedLocation,
              onChanged: (value) => setState(() => _selectedLocation = value!),
            ),
            RadioListTile<String>(
              title: const Text('Use Current Location'),
              value: 'current',
              groupValue: _selectedLocation,
              onChanged: (value) => setState(() => _selectedLocation = value!),
            ),
            if (_selectedLocation == 'current')
              ElevatedButton.icon(
                onPressed: _getLocation,
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
              groupValue: _selectedLocation,
              onChanged: (value) => setState(() => _selectedLocation = value!),
            ),
            if (_selectedLocation == 'custom')
              TextField(
                controller: _customLocationController,
                decoration: const InputDecoration(
                  labelText: 'Enter Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Selected Images:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _images[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.appMainColour,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Post Service'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}