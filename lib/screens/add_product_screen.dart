import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  int? userId; // logged-in user ID
  String? access; // auth token

  @override
  void initState() {
    super.initState();
    loadUser();
    fetchCategories();
  }

  Future<void> loadUser() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    userId = pref.getInt("user_id");
    print("USER ID = $userId");
    access = pref.getString("accessToken");
    print("Access Token = $access");
    
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
    final List<XFile>? picked = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1000,
    );
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
      final productData = {
        "user_id": userId,
        "title": titleController.text,
        "description": descriptionController.text,
        "price": priceController.text,
        "vendorName": vendorNameController.text,
        "location": locationController.text,
        "contact": contactController.text,
        "images": imageUrls,
        "featured": isFeatured,
      };

      final response = await http.post(
        Uri.parse(
          "http://10.0.2.2:8080/api/categories/product/add/$selectedCategoryId/",
        ),
        headers: {"Content-Type": "application/json",
        "Authorization": "Bearer $access",
        },
        body: jsonEncode(productData),
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product Added Successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        clearForm();
      } else {
        showError("Failed: ${response.body}");
      }
    } catch (e) {
      showError("Error: $e");
      setState(() => isSubmitting = false);
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    priceController.clear();
    vendorNameController.clear();
    locationController.clear();
    contactController.clear();
    selectedImages = [];
    selectedCategoryId = null;
    isFeatured = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: Colors.teal,
      ),
      body: loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildCategoryDropdown(),
                  const SizedBox(height: 16),
                  buildForm(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSubmitting ? null : submitProduct,
        label: Text(isSubmitting ? "Submitting..." : "Submit"),
        icon: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
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
          child: Text(cat["title"]),
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
        const SizedBox(height: 20),
        SwitchListTile(
          title: const Text("Set as Featured Product"),
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
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Images", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (selectedImages.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(selectedImages[index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => selectedImages.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Icon(
                            Icons.close,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: pickImages,
          icon: const Icon(Icons.add_a_photo, color: Colors.teal),
          label: const Text("Add Images"),
        ),
      ],
    );
  }
}
