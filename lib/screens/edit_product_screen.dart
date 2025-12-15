


import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:services/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api.dart';

class EditProductPage extends StatefulWidget {
  final int productId;

  const EditProductPage({super.key, required this.productId});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();

  bool isLoading = true;
  File? newImageFile;
  String? existingImageUrl;
  String token = "";
  bool isFeatured = false;

  @override
  void initState() {
    super.initState();
    loadProduct();
  }

  Future<void> loadProduct() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("accessToken") ?? "";

    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/categories/product/${widget.productId}/",
      );
      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        titleController.text = data["title"];
        descController.text = data["description"];
        priceController.text = data["price"].toString();
        isFeatured = data["featured"] ?? false;

        // handle image
        if (data["images"] != null && data["images"].isNotEmpty) {
          String img = data["images"][0].toString();
          if (!img.startsWith("http")) {
            // prepend base URL if relative path
            img = "${ApiConfig.baseUrl}$img";
          }
          existingImageUrl = img;
        }
      }
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar(
        "Error",
        "Failed to load product",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() => newImageFile = File(picked.path));
    }
  }

  Future<void> updateProduct() async {
    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/api/categories/product/${widget.productId}/update/",
      );

      var request = http.MultipartRequest("POST", url);
      request.headers["Authorization"] = "Bearer $token";

      request.fields["title"] = titleController.text;
      request.fields["description"] = descController.text;
      request.fields["price"] = priceController.text;
      request.fields["featured"] = isFeatured.toString();

      if (newImageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", newImageFile!.path),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          "Success",
          "Product Updated!",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.back(result: true); // return true to refresh list
      } else {
        Get.snackbar(
          "Error",
          "Update failed",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Something went wrong",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Widget buildImagePreview() {
    return GestureDetector(
      onTap: pickImage,
      child: Stack(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: newImageFile != null
                  ? Image.file(newImageFile!, fit: BoxFit.cover)
                  : existingImageUrl != null
                  ? Image.network(existingImageUrl!, fit: BoxFit.cover)
                  : const Center(child: Icon(Icons.add_a_photo, size: 50)),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
              "Edit Product",
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildImagePreview(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: "Product Title",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: descController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text("Set as Featured Product"),
                    value: isFeatured,
                    onChanged: (v) => setState(() => isFeatured = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.appMainColour,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Update Product",
                        style: TextStyle(fontSize: 16,color: Colors.white,fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
