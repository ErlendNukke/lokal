import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? 'http://localhost:8080';

  final http.Client _client;
  final String baseUrl;
  String? token;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<T> request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool auth = true,
    T Function(dynamic json)? parser,
  }) async {
    final headers = <String, String>{
      if (body != null) 'Content-Type': 'application/json',
      if (auth && token != null) 'Authorization': 'Bearer $token',
    };

    late http.Response response;
    final uri = _uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
      case 'POST':
        response = await _client.post(uri, headers: headers, body: encoded);
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: encoded);
      case 'PATCH':
        response = await _client.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
      default:
        throw ApiException('Unsupported method $method');
    }

    if (response.statusCode >= 400) {
      String message = 'Request failed (${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['error'] != null) {
          message = json['error'].toString();
        }
      } catch (_) {}
      throw ApiException(message);
    }

    if (response.body.isEmpty || response.statusCode == 204) {
      return parser != null ? parser(null) : null as T;
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    return parser != null ? parser(json) : json as T;
  }

  Future<String> uploadImage(
    List<int> bytes, {
    required String filename,
    String? mimeType,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/uploads'));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: _imageMediaType(filename, mimeType),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      String message = 'Upload failed';
      try {
        final json = jsonDecode(response.body);
        if (json is Map && json['error'] != null) {
          message = json['error'].toString();
        }
      } catch (_) {}
      throw ApiException(message);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  MediaType _imageMediaType(String filename, String? mimeType) {
    final mime = mimeType?.split(';').first.trim().toLowerCase();
    if (mime != null && mime.startsWith('image/')) {
      return MediaType.parse(mime == 'image/jpg' ? 'image/jpeg' : mime);
    }
    final name = filename.toLowerCase();
    if (name.endsWith('.png')) return MediaType('image', 'png');
    if (name.endsWith('.webp')) return MediaType('image', 'webp');
    if (name.endsWith('.gif')) return MediaType('image', 'gif');
    return MediaType('image', 'jpeg');
  }
}
