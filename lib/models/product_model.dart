class Product {
  final String id;
  final String title;
  final String description;
  final String price;
  final String category;
  final String vendorId;
  final String vendorName;
  final String location;
  final String contact;
  final List<String> images;
  final double rating;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.vendorId,
    required this.vendorName,
    required this.location,
    required this.contact,
    required this.images,
    this.rating = 4.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json["id"].toString(), // ✅ FIXED
      title: json["title"] ?? "",
      description: json["description"] ?? "",
      price: json["price"].toString(), // ✅ FIXED
      category: json["category"].toString(), // ✅ FIXED
      vendorId: json["vendorId"].toString(), // ✅ FIXED
      vendorName: json["vendorName"] ?? "",
      location: json["location"] ?? "",
      contact: json["contact"] ?? "",
      images: List<String>.from(json["images"] ?? []),
      rating:
          (json["rating"] is int) // ✅ FIXED
          ? (json["rating"] as int).toDouble()
          : (json["rating"] ?? 4.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "description": description,
    "price": price,
    "category": category,
    "vendorId": vendorId,
    "vendorName": vendorName,
    "location": location,
    "contact": contact,
    "images": images,
    "rating": rating,
  };
}
