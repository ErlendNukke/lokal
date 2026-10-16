import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokal/theme/app_theme.dart';

void main() {
  test('brand palette uses icon orange-red', () {
    expect(LokalColors.primary, const Color(0xFFD9381E));
    expect(LokalColors.surfaceSoft.toARGB32(), isNonZero);
  });
}
