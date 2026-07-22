import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'prepare_image_upload_io.dart'
    if (dart.library.html) 'prepare_image_upload_web.dart' as impl;

class PreparedUploadImage {
  const PreparedUploadImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}

/// Normalizes gallery/camera picks (incl. iPhone HEIC on Safari) into uploadable bytes.
Future<PreparedUploadImage> prepareImageForUpload(XFile file) async {
  final prepared = await impl.prepareImageForUpload(file);
  return PreparedUploadImage(
    bytes: prepared.bytes,
    filename: prepared.filename,
    mimeType: prepared.mimeType,
  );
}
