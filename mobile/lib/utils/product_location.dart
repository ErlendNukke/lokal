
import 'package:latlong2/latlong.dart';

/// Coordinates to send on create/update.
///
/// - A map tap always wins.
/// - A previously geocoded point is reused only while the typed address is unchanged.
/// - Otherwise the API geocodes the typed address (null, null).
LatLng? productPointToSave({
  required LatLng? point,
  required bool fromTap,
  required String? geocodedForAddress,
  required String currentAddress,
}) {
  if (point == null) return null;
  if (fromTap) return point;
  return geocodedForAddress == currentAddress.trim() ? point : null;
}
