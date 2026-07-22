import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Native iOS/Android: [ImagePicker] with quality/size already re-encodes HEIC → JPEG.
Future<({Uint8List bytes, String filename, String mimeType})> prepareImageForUpload(
  XFile file,
) async {
  final bytes = await file.readAsBytes();
  if (bytes.isEmpty) {
    throw StateError('Tühi pilt');
  }
  var name = file.name.trim();
  var mime = file.mimeType?.split(';').first.trim().toLowerCase();
  final lower = name.toLowerCase();
  if (lower.endsWith('.heic') ||
      lower.endsWith('.heif') ||
      mime == 'image/heic' ||
      mime == 'image/heif') {
    name = 'photo.jpg';
    mime = 'image/jpeg';
  }
  if (name.isEmpty) name = 'photo.jpg';
  mime ??= _mimeFromName(name) ?? 'image/jpeg';
  return (bytes: bytes, filename: name, mimeType: mime);
}

String? _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}
