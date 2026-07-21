import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kodukraam/theme/app_theme.dart';

void main() {
  test('brand palette stays forest/beige', () {
    expect(KodukraamColors.forest, const Color(0xFF2F5D50));
    expect(KodukraamColors.beige.toARGB32(), isNonZero);
  });
}
