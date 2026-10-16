import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokal/theme/app_theme.dart';

void main() {
  test('brand palette stays forest/beige', () {
    expect(LokalColors.forest, const Color(0xFF0A6E62));
    expect(LokalColors.beige.toARGB32(), isNonZero);
  });
}
