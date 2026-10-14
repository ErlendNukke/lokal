import 'package:lokal/models/models.dart';
import 'package:lokal/services/api_client.dart';

class MarketplaceService {
  MarketplaceService(this._api);

  final ApiClient _api;

  Future<List<Product>> searchProducts({
    double? lat,
    double? lng,
    int? radiusKm,
    ProductCategory? category,
    String? q,
  }) async {
    final query = <String, String>{
      if (lat != null) 'lat': '$lat',
      if (lng != null) 'lng': '$lng',
      if (radiusKm != null) 'radiusKm': '$radiusKm',
      if (category != null) 'category': categoryApi(category),
      if (q != null && q.isNotEmpty) 'q': q,
    };
    final list = await _api.request<List<dynamic>>(
      'GET',
      '/api/products',
      query: query,
      auth: false,
    );
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> getProduct(String id, {double? lat, double? lng}) async {
    final query = <String, String>{
      if (lat != null) 'lat': '$lat',
      if (lng != null) 'lng': '$lng',
    };
    final json = await _api.request<Map<String, dynamic>>(
      'GET',
      '/api/products/$id',
      query: query,
      auth: false,
    );
    return Product.fromJson(json);
  }

  Future<List<Product>> myProducts() async {
    final list = await _api.request<List<dynamic>>('GET', '/api/producer/products');
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> createProduct(Map<String, dynamic> body) async {
    final json = await _api.request<Map<String, dynamic>>(
      'POST',
      '/api/producer/products',
      body: body,
    );
    return Product.fromJson(json);
  }

  /// Geocodes a typed address via the API (Nominatim behind it). Throws when not found.
  Future<GeocodeResult> geocode(String address) async {
    final json = await _api.request<Map<String, dynamic>>(
      'GET',
      '/api/producer/geocode',
      query: {'q': address},
    );
    return GeocodeResult.fromJson(json);
  }

  Future<void> deleteProduct(String id) async {
    await _api.request<void>('DELETE', '/api/producer/products/$id');
  }

  Future<Order> createOrder(Map<String, dynamic> body) async {
    final json = await _api.request<Map<String, dynamic>>('POST', '/api/orders', body: body);
    return Order.fromJson(json);
  }

  Future<List<Order>> myOrders() async {
    final list = await _api.request<List<dynamic>>('GET', '/api/orders/mine');
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Order>> producerOrders() async {
    final list = await _api.request<List<dynamic>>('GET', '/api/producer/orders');
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> updateOrderStatus(String id, OrderStatus status) async {
    final json = await _api.request<Map<String, dynamic>>(
      'PATCH',
      '/api/orders/$id/status',
      body: {'status': orderStatusApi(status)},
    );
    return Order.fromJson(json);
  }

  Future<void> createReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    await _api.request<Map<String, dynamic>>(
      'POST',
      '/api/reviews',
      body: {'orderId': orderId, 'rating': rating, 'comment': comment},
    );
  }

  Future<List<Review>> producerReviews(String producerId) async {
    final list = await _api.request<List<dynamic>>(
      'GET',
      '/api/producers/$producerId/reviews',
      auth: false,
    );
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> uploadImage(
    List<int> bytes, {
    required String filename,
    String? mimeType,
  }) =>
      _api.uploadImage(bytes, filename: filename, mimeType: mimeType);
}

class GeocodeResult {
  const GeocodeResult(this.latitude, this.longitude, this.displayName);

  factory GeocodeResult.fromJson(Map<String, dynamic> json) => GeocodeResult(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
        json['displayName'] as String?,
      );

  final double latitude;
  final double longitude;
  final String? displayName;
}
