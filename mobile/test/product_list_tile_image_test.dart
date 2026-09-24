import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lokal/widgets/product_network_image.dart';

void main() {
  testWidgets('ListTile with ProductNetworkImage lays out title without overflow', (tester) async {
    const productName = 'Maasikamoos';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const ProductNetworkImage(
                    imageUrl: 'https://example.com/berry.jpg',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(productName),
                subtitle: const Text('4.50 € / kg · 10 saadaval'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text(productName), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });
}
