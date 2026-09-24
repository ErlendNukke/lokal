import 'package:flutter/material.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/widgets/product_network_image.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.delay = 0,
  });

  final Product product;
  final VoidCallback onTap;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Semantics(
        button: true,
        label: product.name,
        onTap: onTap,
        child: ExcludeSemantics(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LokalColors.border),
                boxShadow: [
                  BoxShadow(
                    color: LokalColors.forest.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 11,
                      child: product.photo.isEmpty
                          ? Container(color: LokalColors.beigeDeep)
                          : ProductNetworkImage(
                              imageUrl: product.photo,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: brandTitle(size: 17),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${product.producer.farmName} · ${product.distanceKm?.toStringAsFixed(1) ?? '—'} km',
                          style: const TextStyle(color: LokalColors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${product.price.toStringAsFixed(2)} € / ${unitLabel(product.unit)}',
                          style: const TextStyle(
                            color: LokalColors.forestDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.subtitle = 'Lähedalt.'});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lokal', style: brandTitle(size: 34)),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: LokalColors.muted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
