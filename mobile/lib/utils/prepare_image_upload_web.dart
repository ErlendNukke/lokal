import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:web/web.dart';

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
  final blob = Blob([bytes.toJS].toJS, BlobPropertyBag(type: mime));
  final objectUrl = URL.createObjectURL(blob);
  try {
    final img = HTMLImageElement();
    final loaded = Completer<void>();
    img.onload = ((Event _) {
      if (!loaded.isCompleted) loaded.complete();
    }).toJS;
    img.onerror = ((Event _) {
      if (!loaded.isCompleted) {
        loaded.completeError(StateError('decode failed'));
      }
    }).toJS;
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

    final canvas = HTMLCanvasElement();
    canvas.width = w;
    canvas.height = h;
    final ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
    ctx.drawImage(img, 0, 0, w.toDouble(), h.toDouble());

    final outBlob = await _canvasToJpegBlob(canvas);
    return await _readBlobAsBytes(outBlob);
  } finally {
    URL.revokeObjectURL(objectUrl);
  }
}

Future<Blob> _canvasToJpegBlob(HTMLCanvasElement canvas) {
  final done = Completer<Blob>();
  canvas.toBlob(
    ((Blob? blob) {
      if (blob != null) {
        done.complete(blob);
      } else {
        done.completeError(StateError('jpeg export failed'));
      }
    }).toJS,
    'image/jpeg',
    _jpegQuality.toJS,
  );
  return done.future.timeout(const Duration(seconds: 20));
}

Future<Uint8List> _readBlobAsBytes(Blob blob) {
  final reader = FileReader();
  final done = Completer<Uint8List>();
  reader.onloadend = ((Event _) {
    final result = reader.result;
    if (result.isA<JSArrayBuffer>()) {
      done.complete(Uint8List.view((result as JSArrayBuffer).toDart));
    } else {
      done.completeError(StateError('read failed'));
    }
  }).toJS;
  reader.onerror = ((Event _) {
    done.completeError(StateError('read failed'));
  }).toJS;
  reader.readAsArrayBuffer(blob);
  return done.future.timeout(const Duration(seconds: 20));
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
