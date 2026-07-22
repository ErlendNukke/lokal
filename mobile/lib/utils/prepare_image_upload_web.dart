import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

const _maxEdge = 1600;
const _jpegQuality = 0.85;

/// Web (incl. iPhone Safari): draw into a canvas and export JPEG.
/// Safari can decode HEIC into an img element; the Java API cannot.
Future<({Uint8List bytes, String filename, String mimeType})> prepareImageForUpload(
  XFile file,
) async {
  final raw = await file.readAsBytes();
  if (raw.isEmpty) {
    throw StateError('Tühi pilt');
  }
  final sourceMime = file.mimeType?.split(';').first.trim().toLowerCase() ??
      _mimeFromName(file.name) ??
      'application/octet-stream';

  try {
    final jpeg = await _reencodeToJpeg(raw, sourceMime);
    return (bytes: jpeg, filename: 'photo.jpg', mimeType: 'image/jpeg');
  } catch (_) {
    throw StateError(
      'Pilti ei õnnestunud lugeda. Proovi JPG/PNG või lülita iPhone’is '
      'Seaded → Kaamera → Vormingud → Enim ühilduv.',
    );
  }
}

Future<Uint8List> _reencodeToJpeg(Uint8List bytes, String mime) async {
  final blob = html.Blob([bytes], mime);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);
  try {
    final img = html.ImageElement();
    final loaded = Completer<void>();
    img.onLoad.listen((_) {
      if (!loaded.isCompleted) loaded.complete();
    });
    img.onError.listen((_) {
      if (!loaded.isCompleted) {
        loaded.completeError(StateError('decode failed'));
      }
    });
    img.src = objectUrl;
    await loaded.future.timeout(const Duration(seconds: 20));

    final srcW = img.naturalWidth;
    final srcH = img.naturalHeight;
    if (srcW <= 0 || srcH <= 0) {
      throw StateError('invalid dimensions');
    }

    final scale = srcW > srcH
        ? (_maxEdge / srcW).clamp(0.0, 1.0)
        : (_maxEdge / srcH).clamp(0.0, 1.0);
    final w = (srcW * scale).round().clamp(1, _maxEdge);
    final h = (srcH * scale).round().clamp(1, _maxEdge);

    final canvas = html.CanvasElement(width: w, height: h);
    final ctx = canvas.context2D;
    ctx.drawImageScaled(img, 0, 0, w, h);

    final outBlob = await canvas.toBlob('image/jpeg', _jpegQuality);
    if (outBlob == null) {
      throw StateError('jpeg export failed');
    }
    final reader = html.FileReader();
    final done = Completer<Uint8List>();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        done.complete(result);
      } else if (result is ByteBuffer) {
        done.complete(result.asUint8List());
      } else {
        done.completeError(StateError('read failed'));
      }
    });
    reader.onError.listen((_) => done.completeError(StateError('read failed')));
    reader.readAsArrayBuffer(outBlob);
    return done.future.timeout(const Duration(seconds: 20));
  } finally {
    html.Url.revokeObjectUrl(objectUrl);
  }
}

String? _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.heic')) return 'image/heic';
  if (lower.endsWith('.heif')) return 'image/heif';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}
