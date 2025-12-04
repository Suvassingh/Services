
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:services/utils/app_constants.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  List categories = [];
  String? selectedCategoryId;

  // Text controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final vendorIdController = TextEditingController();
  final vendorNameController = TextEditingController();
  final locationController = TextEditingController();
  final contactController = TextEditingController();
  final ratingController = TextEditingController(text: "");

  final ImagePicker picker = ImagePicker();
  List<XFile>? selectedImages = [];

  bool loadingCategories = true;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    vendorIdController.dispose();
    vendorNameController.dispose();
    locationController.dispose();
    contactController.dispose();
    ratingController.dispose();
    super.dispose();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse("http://10.0.2.2:8080/api/categories/categories/"),
      );

      if (response.statusCode == 200) {
        setState(() {
          categories = jsonDecode(response.body);
          loadingCategories = false;
        });
      } else {
        showError("Failed to load categories (${response.statusCode})");
      }
    } catch (e) {
      showError("Error loading categories: $e");
    }
  }

  void showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
  }

  Future<void> pickImages() async {
    try {
      final List<XFile>? picked = await picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 900,
      );

      if (picked != null) {
        setState(() => selectedImages = picked);
      }
    } catch (e) {
      showError("Image error: $e");
    }
  }

  Future<List<String>> uploadImages() async {
    List<String> uploaded = [];

    for (var file in selectedImages!) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse("http://10.0.2.2:8080/api/categories/upload/"),
        );

        request.files.add(
          await http.MultipartFile.fromPath("image", file.path),
        );

        var response = await request.send();
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(await response.stream.bytesToString());
          uploaded.add(jsonResponse["image_url"]);
        }
      } catch (e) {
        print("Upload error: $e");
      }
    }
    return uploaded;
  }

  Future<void> submitProduct() async {
    if (selectedCategoryId == null) {
      showError("Select a category");
      return;
    }

    if (titleController.text.isEmpty ||
        descriptionController.text.isEmpty ||
        priceController.text.isEmpty ||
        vendorIdController.text.isEmpty ||
        vendorNameController.text.isEmpty ||
        locationController.text.isEmpty ||
        contactController.text.isEmpty) {
      showError("Fill all required fields");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      List<String> imageUrls = await uploadImages();

      final productData = {
        "title": titleController.text,
        "description": descriptionController.text,
        "price": priceController.text,
        "vendorId": vendorIdController.text,
        "vendorName": vendorNameController.text,
        "location": locationController.text,
        "contact": contactController.text,
        "images": imageUrls,
        "rating": double.tryParse(ratingController.text) ?? 4.0,
      };

      final response = await http.post(
        Uri.parse(
          "http://10.0.2.2:8080/api/categories/product/add/$selectedCategoryId/",
        ),
        body: jsonEncode(productData),
        headers: {"Content-Type": "application/json"},
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text("Product Added!"),
          ),
        );
        clearForm();
      } else {
        showError("Failed: ${response.statusCode}");
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
    vendorIdController.clear();
    vendorNameController.clear();
    locationController.clear();
    contactController.clear();
    ratingController.text = "4.0";
    selectedImages = [];
    selectedCategoryId = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            title: const Text(
              'Add New Product',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.appTextColour,
              ),
            ),
            backgroundColor: Colors.teal,
            elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
          ),
        ),
      ),

      body: loadingCategories
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildCategoryCard(),
                  const SizedBox(height: 16),
                  buildProductForm(),
                  const SizedBox(height: 30),
                ],
              ),
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSubmitting ? null : submitProduct,
        backgroundColor: Colors.teal,
        icon: isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check_circle_outline,),
        label: Text(isSubmitting ? "Submitting..." : "Submit"),
      ),
    );
  }



  Widget buildCategoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.category_outlined, color: Colors.teal, size: 28),
                SizedBox(width: 8),
                Text(
                  "Select Category",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text("Choose category"),
              value: selectedCategoryId,
              items: categories.map<DropdownMenuItem<String>>((cat) {
                return DropdownMenuItem(
                  value: cat["id"].toString(),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.teal.shade50,
                        backgroundImage: cat["icon"] != null
                            ? NetworkImage("http://10.0.2.2:8080${cat["icon"]}")
                            : null,
                        child: cat["icon"] == null
                            ? const Icon(Icons.category)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(cat["title"]),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => selectedCategoryId = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildHeader("Product Information"),

            buildInput(titleController, "Product Title", Icons.label),
            buildInput(
              descriptionController,
              "Description",
              Icons.description_outlined,
              maxLines: 3,
            ),
            buildInput(
              priceController,
              "Price",
              Icons.attach_money,
              type: TextInputType.number,
            ),
            buildInput(vendorIdController, "Vendor ID", Icons.person),
            buildInput(
              vendorNameController,
              "Vendor Name",
              Icons.person_outline,
            ),
            buildInput(
              locationController,
              "Location",
              Icons.location_on_outlined,
            ),
            buildInput(
              contactController,
              "Contact",
              Icons.phone,
              type: TextInputType.phone,
            ),
            buildInput(
              ratingController,
              "Rating (1-5)",
              Icons.star_rate,
              type: TextInputType.number,
            ),

            const SizedBox(height: 16),
            buildImagePicker(),
          ],
        ),
      ),
    );
  }

  Widget buildHeader(String text) {
    return Row(
      children: [
        Icon(Icons.info_outline, color: Colors.teal.shade700),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget buildInput(
    TextEditingController c,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.teal),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Images",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),

        // Preview Images
        if (selectedImages!.isNotEmpty)
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: selectedImages!.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(selectedImages![index].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedImages!.removeAt(index));
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.red,
                          radius: 12,
                          child: const Icon(
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

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: pickImages,
          icon: const Icon(Icons.add_a_photo, color: Colors.teal),
          label: const Text("Add Images"),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
            side: BorderSide(color: Colors.teal.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
