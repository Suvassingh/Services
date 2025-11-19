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

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'vendorId': vendorId,
    'vendorName': vendorName,
    'location': location,
    'contact': contact,
    'images': images,
    'rating': rating,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    title: json['title'],
    description: json['description'],
    price: json['price'],
    category: json['category'],
    vendorId: json['vendorId'],
    vendorName: json['vendorName'],
    location: json['location'],
    contact: json['contact'],
    images: List<String>.from(json['images']),
    rating: json['rating']?.toDouble() ?? 4.0,
  );
}