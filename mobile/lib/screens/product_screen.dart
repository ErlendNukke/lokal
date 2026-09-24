import 'package:flutter/material.dart';
import 'package:lokal/core/config.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/screens/auth_screen.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/services/marketplace_service.dart';
import 'package:lokal/copy/order_payment_copy.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/widgets/payment_at_handover_hint.dart';
import 'package:lokal/widgets/product_network_image.dart';
import 'package:provider/provider.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.productId});

  final String productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? _product;
  List<Review> _reviews = [];
  bool _loading = true;
  bool _ordering = false;
  String? _error;
  double _quantity = 1;
  FulfillmentType _fulfillment = FulfillmentType.pickup;
  final _message = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _message.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    final market = context.read<MarketplaceService>();
    try {
      final product = await market.getProduct(
        widget.productId,
        lat: auth.user?.latitude ?? AppConfig.defaultLat,
        lng: auth.user?.longitude ?? AppConfig.defaultLng,
      );
      final reviews = await market.producerReviews(product.producer.id);
      if (!mounted) return;
      setState(() {
        _product = product;
        _reviews = reviews;
        _fulfillment = product.pickupAvailable ? FulfillmentType.pickup : FulfillmentType.delivery;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _order() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (ok != true) return;
    }

    if (!mounted) return;
    setState(() => _ordering = true);
    try {
      await context.read<MarketplaceService>().createOrder({
        'productId': widget.productId,
        'quantity': _quantity,
        'fulfillment': fulfillmentApi(_fulfillment),
        'message': _message.text.trim().isEmpty ? null : _message.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(OrderPaymentCopy.orderConfirmation)),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      appBar: AppBar(title: const Text('Toode')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: LokalColors.danger)))
              : ListView(
                  children: [
                    if (product!.photo.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: ProductNetworkImage(imageUrl: product.photo, fit: BoxFit.cover),
                      )
                    else
                      Container(height: 220, color: LokalColors.beigeDeep),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: brandTitle(size: 28)),
                          const SizedBox(height: 6),
                          Text(
                            '${product.price.toStringAsFixed(2)} € / ${unitLabel(product.unit)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: LokalColors.forestDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${product.producer.farmName} · ★ ${product.producer.ratingAvg.toStringAsFixed(1)} '
                            '(${product.producer.ratingCount}) · ${product.distanceKm?.toStringAsFixed(1) ?? '—'} km',
                            style: const TextStyle(color: LokalColors.muted),
                          ),
                          const SizedBox(height: 12),
                          Text(product.description ?? ''),
                          const SizedBox(height: 8),
                          Text(
                            'Saadaval: ${product.quantity} ${unitLabel(product.unit)} · ${product.locationLabel ?? 'Eesti'}',
                            style: const TextStyle(color: LokalColors.muted),
                          ),
                          const SizedBox(height: 24),
                          Text('Telli', style: brandTitle(size: 22)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _quantityCtrl,
                            decoration: const InputDecoration(labelText: 'Kogus'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => _quantity = double.tryParse(v) ?? 1,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<FulfillmentType>(
                            // ignore: deprecated_member_use
                            value: _fulfillment,
                            decoration: const InputDecoration(labelText: 'Kättesaamine'),
                            items: [
                              if (product.pickupAvailable)
                                const DropdownMenuItem(
                                  value: FulfillmentType.pickup,
                                  child: Text('Järeletulemine'),
                                ),
                              if (product.deliveryAvailable)
                                const DropdownMenuItem(
                                  value: FulfillmentType.delivery,
                                  child: Text('Kohaletoimetamine'),
                                ),
                            ],
                            onChanged: (v) => setState(() => _fulfillment = v ?? FulfillmentType.pickup),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _message,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Sõnum tootjale',
                              hintText: 'Millal sobib?',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const PaymentAtHandoverHint(text: OrderPaymentCopy.orderSectionHint),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _ordering ? null : _order,
                            child: Text(_ordering ? 'Saadan…' : 'Telli'),
                          ),
                          const SizedBox(height: 28),
                          Text('Arvustused', style: brandTitle(size: 22)),
                          const SizedBox(height: 8),
                          if (_reviews.isEmpty)
                            const Text('Arvustusi veel pole.', style: TextStyle(color: LokalColors.muted))
                          else
                            ..._reviews.map(
                              (r) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('${r.reviewerName} · ★ ${r.rating}'),
                                subtitle: Text(r.comment ?? ''),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
