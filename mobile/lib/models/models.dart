enum UserRole { buyer, producer, both }

enum ProductCategory { food, plants, farm, handmade, other }

enum ProductUnit { kg, piece, jar, box }

enum FulfillmentType { pickup, delivery }

enum OrderStatus { pending, accepted, rejected, completed, cancelled }

UserRole parseRole(String value) => UserRole.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => UserRole.buyer,
    );

ProductCategory parseCategory(String value) => ProductCategory.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => ProductCategory.other,
    );

ProductUnit parseUnit(String value) => ProductUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ProductUnit.piece,
    );

FulfillmentType parseFulfillment(String value) => FulfillmentType.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => FulfillmentType.pickup,
    );

OrderStatus parseOrderStatus(String value) => OrderStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => OrderStatus.pending,
    );

String roleApi(UserRole role) => role.name.toUpperCase();
String categoryApi(ProductCategory c) => c.name.toUpperCase();
String unitApi(ProductUnit u) => u.name;
String fulfillmentApi(FulfillmentType f) => f.name.toUpperCase();
String orderStatusApi(OrderStatus s) => s.name.toUpperCase();

class User {
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.latitude,
    this.longitude,
    this.city,
    this.producerProfileId,
    this.farmName,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? producerProfileId;
  final String? farmName;

  bool get isProducer => role == UserRole.producer || role == UserRole.both;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: parseRole(json['role'] as String),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        city: json['city'] as String?,
        producerProfileId: json['producerProfileId'] as String?,
        farmName: json['farmName'] as String?,
      );
}

class ProducerSummary {
  ProducerSummary({
    required this.id,
    required this.farmName,
    required this.ownerName,
    required this.ratingAvg,
    required this.ratingCount,
  });

  final String id;
  final String farmName;
  final String ownerName;
  final double ratingAvg;
  final int ratingCount;

  factory ProducerSummary.fromJson(Map<String, dynamic> json) => ProducerSummary(
        id: json['id'] as String,
        farmName: json['farmName'] as String,
        ownerName: json['ownerName'] as String,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      );
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.quantity,
    required this.latitude,
    required this.longitude,
    required this.pickupAvailable,
    required this.deliveryAvailable,
    required this.photos,
    required this.producer,
    this.description,
    this.locationLabel,
    this.distanceKm,
  });

  final String id;
  final String name;
  final String? description;
  final ProductCategory category;
  final double price;
  final ProductUnit unit;
  final double quantity;
  final double latitude;
  final double longitude;
  final String? locationLabel;
  final bool pickupAvailable;
  final bool deliveryAvailable;
  final List<String> photos;
  final double? distanceKm;
  final ProducerSummary producer;

  String get photo => photos.isNotEmpty ? photos.first : '';

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: parseCategory(json['category'] as String),
        price: (json['price'] as num).toDouble(),
        unit: parseUnit(json['unit'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        locationLabel: json['locationLabel'] as String?,
        pickupAvailable: json['pickupAvailable'] as bool? ?? true,
        deliveryAvailable: json['deliveryAvailable'] as bool? ?? false,
        photos: (json['photos'] as List<dynamic>? ?? []).cast<String>(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        producer: ProducerSummary.fromJson(json['producer'] as Map<String, dynamic>),
      );
}

class Order {
  Order({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerId,
    required this.buyerName,
    required this.producerId,
    required this.farmName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.totalPrice,
    required this.fulfillment,
    required this.status,
    required this.canReview,
    this.productPhoto,
    this.message,
  });

  final String id;
  final String productId;
  final String productName;
  final String? productPhoto;
  final String buyerId;
  final String buyerName;
  final String producerId;
  final String farmName;
  final double quantity;
  final ProductUnit unit;
  final double unitPrice;
  final double totalPrice;
  final FulfillmentType fulfillment;
  final String? message;
  final OrderStatus status;
  final bool canReview;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        productPhoto: json['productPhoto'] as String?,
        buyerId: json['buyerId'] as String,
        buyerName: json['buyerName'] as String,
        producerId: json['producerId'] as String,
        farmName: json['farmName'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: parseUnit(json['unit'] as String),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        totalPrice: (json['totalPrice'] as num).toDouble(),
        fulfillment: parseFulfillment(json['fulfillment'] as String),
        message: json['message'] as String?,
        status: parseOrderStatus(json['status'] as String),
        canReview: json['canReview'] as bool? ?? false,
      );
}

class Review {
  Review({
    required this.id,
    required this.reviewerName,
    required this.rating,
    this.comment,
  });

  final String id;
  final String reviewerName;
  final int rating;
  final String? comment;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        reviewerName: json['reviewerName'] as String,
        rating: (json['rating'] as num).toInt(),
        comment: json['comment'] as String?,
      );
}

class CategoryOption {
  const CategoryOption(this.key, this.label, this.emoji);
  final ProductCategory? key;
  final String label;
  final String emoji;
}

const categoryOptions = [
  CategoryOption(null, 'Kõik', '🏡'),
  CategoryOption(ProductCategory.food, 'Toit', '🍎'),
  CategoryOption(ProductCategory.plants, 'Taimed', '🌱'),
  CategoryOption(ProductCategory.farm, 'Talutooted', '🍯'),
  CategoryOption(ProductCategory.handmade, 'Käsitöö', '🎨'),
  CategoryOption(ProductCategory.other, 'Muu', '✨'),
];

const radiusOptions = [5, 20, 50];
