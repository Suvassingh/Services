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

class FacebookStyleAddService extends StatefulWidget {
  final String serviceCategory;

  const FacebookStyleAddService({super.key, required this.serviceCategory});

  @override
  State<FacebookStyleAddService> createState() => _FacebookStyleAddServiceState();
}

class _FacebookStyleAddServiceState extends State<FacebookStyleAddService> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _contactController = TextEditingController();
  final _vendorNameController = TextEditingController();
  final _customLocationController = TextEditingController();
  List<File> _images = [];
  Position? _currentPosition;
  String _selectedLocation = 'store';
  bool _isLoading = false;
  List<String> _existingGroups = [];
  String? _selectedGroup;
  bool _createNewGroup = false;

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('storeName') ?? 'My Store';
    
    final allUserProducts = await ProductService.getUserProducts();
    final userProducts = allUserProducts.where((p) => p.category == widget.serviceCategory).toList();
    
    _existingGroups = userProducts.map((p) => p.vendorName).toSet().toList();
    if (!_existingGroups.contains(storeName)) {
      _existingGroups.insert(0, storeName);
    }
    
    setState(() {
      _createNewGroup = false;
      _selectedGroup = storeName;
    });
    
    // Load contact for default selected business
    await _loadContactForBusiness(storeName);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty && images.length <= 5) {
      setState(() {
        _images = images.map((image) => File(image.path)).toList();
      });
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null && _images.length < 5) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  Future<void> _getLocation() async {
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

  Future<void> _submitService() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty ||
        _priceController.text.isEmpty || _contactController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('userEmail') ?? '';
    
    String productLocation = _selectedLocation == 'store' 
        ? (prefs.getString('customLocation') ?? 'Store Location')
        : _selectedLocation == 'current' 
            ? 'Current Location'
            : _customLocationController.text;
    
    String vendorName = _createNewGroup ? _vendorNameController.text : _selectedGroup!;
    String contact = _contactController.text;
    
    if (!_createNewGroup && _selectedGroup != null) {
      final allUserProducts = await ProductService.getUserProducts();
      final groupProducts = allUserProducts.where((p) => p.vendorName == _selectedGroup).toList();
      if (groupProducts.isNotEmpty) {
        final groupProduct = groupProducts.first;
        contact = groupProduct.contact;
        productLocation = groupProduct.location;
      }
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
    _clearForm();
    Get.snackbar(
      'Success', 
      '${widget.serviceCategory} posted successfully!',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  Future<String?> _getUserProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profileImagePath');
  }

  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName') ?? 'User';
  }

  Future<void> _loadContactForBusiness(String businessName) async {
    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString('storeName') ?? '';
    
    if (businessName == storeName) {
      // Load contact from profile setup
      final userPhone = prefs.getString('userPhone') ?? '';
      if (userPhone.isNotEmpty) {
        _contactController.text = userPhone;
      }
    } else {
      // Load contact from existing business products
      final allUserProducts = await ProductService.getUserProducts();
      final businessProducts = allUserProducts.where((p) => p.vendorName == businessName).toList();
      if (businessProducts.isNotEmpty) {
        _contactController.text = businessProducts.first.contact;
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    if (_createNewGroup) {
      _contactController.clear();
    }
    _vendorNameController.clear();
    setState(() {
      _images.clear();
      _currentPosition = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close, color: Colors.black),
        ),
        title: const Text('Create Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitService,
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('POST', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Info Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  FutureBuilder<String?>(
                    future: _getUserProfileImage(),
                    builder: (context, snapshot) {
                      return CircleAvatar(
                        radius: 25,
                        backgroundColor: AppConstants.appMainColour,
                        backgroundImage: snapshot.hasData && snapshot.data != null 
                            ? FileImage(File(snapshot.data!))
                            : null,
                        child: snapshot.hasData && snapshot.data != null
                            ? null
                            : const Icon(Icons.person, color: Colors.white),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  FutureBuilder<String>(
                    future: _getUserName(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'User',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Form Fields
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'What ${widget.serviceCategory.toLowerCase()} do you want to share?',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          hintText: 'Add more details about your ${widget.serviceCategory.toLowerCase()}...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        maxLines: 4,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Price',
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Contact',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Business Group Section
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Business:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Existing'),
                                value: false,
                                groupValue: _createNewGroup,
                                onChanged: (value) => setState(() => _createNewGroup = value!),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('New'),
                                value: true,
                                groupValue: _createNewGroup,
                                onChanged: (value) => setState(() => _createNewGroup = value!),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                        if (!_createNewGroup)
                          DropdownButtonFormField<String>(
                            value: _selectedGroup,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _existingGroups.map((group) => DropdownMenuItem(
                              value: group,
                              child: Text(group),
                            )).toList(),
                            onChanged: (value) async {
                              setState(() => _selectedGroup = value);
                              await _loadContactForBusiness(value!);
                            },
                          )
                        else
                          TextField(
                            controller: _vendorNameController,
                            decoration: const InputDecoration(
                              hintText: 'New Business Name',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Action Buttons
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildActionRow(Icons.photo_library, 'Gallery (${_images.length}/5)', Colors.green, _pickImages),
                        const Divider(height: 1),
                        _buildActionRow(Icons.camera_alt, 'Camera', Colors.blue, _captureImage),
                        const Divider(height: 1),
                        _buildActionRow(Icons.location_on, _currentPosition != null ? 'Located' : 'Get Location', Colors.red, _getLocation),
                      ],
                    ),
                  ),
                  
                  // Selected Images
                  if (_images.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 80,
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
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(IconData icon, String text, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(text, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}