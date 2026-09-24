import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/widgets/product_network_image.dart';

void main() {
  testWidgets('shows light loading shell before image loads', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: ProductNetworkImage(
              imageUrl: 'https://example.com/product-photo.jpg',
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final coloredBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
    expect(
      coloredBoxes.any((box) => box.color == LokalColors.beigeDeep),
      isTrue,
    );
  });
}
