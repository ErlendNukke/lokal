
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lokal/utils/product_location.dart';

void main() {
  const tartu = LatLng(58.38, 26.72);
  const tallinn = LatLng(59.437, 24.7536);

  test('map tap wins even when address text changed', () {
    expect(
      productPointToSave(
        point: tartu,
        fromTap: true,
        geocodedForAddress: 'Tartu',
        currentAddress: 'something else',
      ),
      tartu,
    );
  });

  test('reuses geocode while address is unchanged', () {
    expect(
      productPointToSave(
        point: tallinn,
        fromTap: false,
        geocodedForAddress: 'Tallinn',
        currentAddress: 'Tallinn',
      ),
      tallinn,
    );
  });

  test('clears coords when address text changes so API geocodes again', () {
    expect(
      productPointToSave(
        point: tallinn,
        fromTap: false,
        geocodedForAddress: 'Tallinn',
        currentAddress: 'Pirita tee 26, Tallinn',
      ),
      isNull,
    );
  });
}
