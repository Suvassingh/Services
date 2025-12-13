
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  List categories = [];
  String? selectedCategoryId;
  bool isFeatured = false;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final vendorNameController = TextEditingController();
  final locationController = TextEditingController();
  final contactController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  List<XFile> selectedImages = [];

  bool loadingCategories = true;
  bool isSubmitting = false;

  final String baseUrl = "http://10.0.2.2:8080/api/categories";

  int? userId;
  String? access;

  @override
  void initState() {
    super.initState();
    loadUser();
    fetchCategories();
  }

  Future<void> loadUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    userId = pref.getInt("user_id");
    access = pref.getString("accessToken");
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/categories/"));
      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body);
          loadingCategories = false;
        });
      } else {
        showError("Failed to load categories");
      }
    } catch (e) {
      showError("Error: $e");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> pickImages() async {
    final List<XFile>? picked = await picker.pickMultiImage(imageQuality: 75);
    if (picked != null) setState(() => selectedImages = picked);
  }

  Future<List<String>> uploadImages() async {
    List<String> urls = [];
    for (var file in selectedImages) {
      var req = http.MultipartRequest('POST', Uri.parse("$baseUrl/upload/"));
      req.files.add(await http.MultipartFile.fromPath("image", file.path));

      var res = await req.send();
      var body = await res.stream.bytesToString();
      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(body);
        urls.add(jsonRes["image_url"]);
      }
    }
    return urls;
  }

  Future<void> submitProduct() async {
    if (selectedCategoryId == null) {
      showError("Select a category");
      return;
    }

    if (userId == null) {
      showError("User not logged in");
      return;
    }

    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty ||
        vendorNameController.text.isEmpty ||
        locationController.text.isEmpty ||
        contactController.text.isEmpty) {
      showError("Please fill all fields");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      List<String> imageUrls = await uploadImages();

      final data = {
        "user_id": userId,
        "title": titleController.text.trim(),
        "description": descriptionController.text.trim(),
        "price": priceController.text.trim(),
        "vendorName": vendorNameController.text.trim(),
        "location": locationController.text.trim(),
        "contact": contactController.text.trim(),
        "images": imageUrls,
        "featured": isFeatured,
      };

      final response = await http.post(
        Uri.parse(
          "http://10.0.2.2:8080/api/categories/product/add/$selectedCategoryId/",
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $access",
        },
        body: jsonEncode(data),
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product Added Successfully"),
            backgroundColor: Colors.green,
          ),
        );
        clearForm();
      } else {
        showError("Error: ${response.body}");
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      showError("Error: $e");
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    vendorNameController.clear();
    locationController.clear();
    contactController.clear();
    selectedImages.clear();
    selectedCategoryId = null;
    isFeatured = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            title: const Text(
              "Add New Product",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.appTextColour,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppConstants.appMainColour,
            elevation: 0,
            iconTheme: IconThemeData(color: AppConstants.appTextColour),
          ),
        ),
      ),
      body: loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildCategoryDropdown(),
                  const SizedBox(height: 20),
                  buildForm(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSubmitting ? null : submitProduct,
        label: Text(isSubmitting ? "Submitting..." : "Submit"),
        icon: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.done),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: "Select Category",
        border: OutlineInputBorder(),
      ),
      value: selectedCategoryId,
      items: categories.map<DropdownMenuItem<String>>((cat) {
        return DropdownMenuItem(
          value: cat["id"].toString(),
          child: Row(
            children: [
              if (cat["icon"] != null)
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    "http://10.0.2.2:8080${cat['icon']}",
                  ),
                )
              else
                const CircleAvatar(child: Icon(Icons.category)),
              const SizedBox(width: 10),
              Text(cat["title"]),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) => setState(() => selectedCategoryId = v),
    );
  }
  Widget buildForm() {
    return Column(
      children: [
        textField(titleController, "Title"),
        textField(descriptionController, "Description", maxLines: 3),
        textField(priceController, "Price", type: TextInputType.number),
        textField(vendorNameController, "Vendor Name"),
        textField(locationController, "Location"),
        textField(contactController, "Contact", type: TextInputType.phone),

        const SizedBox(height: 15),

        SwitchListTile(
          title: const Text("Mark as Featured"),
          value: isFeatured,
          onChanged: (v) => setState(() => isFeatured = v),
        ),

        const SizedBox(height: 15),

        buildImagePicker(),
      ],
    );
  }

  Widget textField(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

Widget buildImagePicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Images",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.teal,
                ),
              ),
            ],
          ),

          if (selectedImages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${selectedImages.length} image${selectedImages.length > 1 ? 's' : ''} selected",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(
                    height: 130,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildImageItem(index),
                        );
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  
                  Text(
                    "No images selected",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            ),


          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.teal, Color(0xFF26A69A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: pickImages,
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              label: const Text(
                "Add Images",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              "Add up to 10 images",
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(int index) {
    return Stack(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(selectedImages[index].path),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[100],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                    size: 40,
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Remove button
        Positioned(
          right: 6,
          top: 6,
          child: GestureDetector(
            onTap: () => setState(() => selectedImages.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(Icons.close, size: 16, color: Colors.red[600]),
            ),
          ),
        ),
      ],
    );
  }
}
