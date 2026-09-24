import 'package:flutter/material.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/screens/auth_screen.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/services/marketplace_service.dart';
import 'package:lokal/copy/order_payment_copy.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/widgets/payment_at_handover_hint.dart';
import 'package:lokal/widgets/product_network_image.dart';
import 'package:provider/provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _selling = false;
  List<Order> _buying = [];
  List<Order> _sellingOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAndLoad());
    }
  }

  @override
  void didUpdateWidget(covariant OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _ensureAndLoad();
    }
  }

  Future<void> _ensureAndLoad() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (ok != true) return;
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final market = context.read<MarketplaceService>();
    try {
      final buying = await market.myOrders();
      List<Order> selling = [];
      if (auth.isProducer) {
        selling = await market.producerOrders();
      }
      if (!mounted) return;
      setState(() {
        _buying = buying;
        _sellingOrders = selling;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<Order> get _list => _selling ? _sellingOrders : _buying;

  Future<void> _update(Order order, OrderStatus status) async {
    try {
      await context.read<MarketplaceService>().updateOrderStatus(order.id, status);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _review(Order order) async {
    final ratingCtrl = TextEditingController(text: '5');
    final commentCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hinda tootjat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ratingCtrl,
              decoration: const InputDecoration(labelText: 'Hinne 1–5'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: commentCtrl,
              decoration: const InputDecoration(labelText: 'Kommentaar'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tühista')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Saada')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    try {
      await context.read<MarketplaceService>().createReview(
            orderId: order.id,
            rating: int.tryParse(ratingCtrl.text) ?? 5,
            comment: commentCtrl.text,
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tellimused'),
        bottom: auth.isProducer
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    explicitChildNodes: true,
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Ostan'),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Müün'),
                        ),
                      ],
                      selected: {_selling},
                      onSelectionChanged: (s) {
                        setState(() => _selling = s.first);
                        _load();
                      },
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _list.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            'Tellimusi pole veel. Avasta kohalikke tooteid!',
                            style: TextStyle(color: LokalColors.muted),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _list.length,
                      itemBuilder: (context, i) {
                        final o = _list[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (o.productPhoto != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: ProductNetworkImage(
                                          imageUrl: o.productPhoto!,
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Semantics(
                                        label: !_selling
                                            ? '${o.productName}. ${OrderPaymentCopy.buyerOrderPaymentLine}. '
                                                '${orderStatusLabel(o.status)}'
                                            : '${o.productName}. ${orderStatusLabel(o.status)}',
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(o.productName, style: brandTitle(size: 18)),
                                            Text(
                                              '${_selling ? o.buyerName : o.farmName} · ${o.quantity} ${unitLabel(o.unit)}'
                                              '${_selling ? ' · ${o.totalPrice.toStringAsFixed(2)} €' : ''}',
                                              style: const TextStyle(color: LokalColors.muted),
                                            ),
                                            if (!_selling)
                                              Text(
                                                '${OrderPaymentCopy.buyerOrderPaymentLine} · ${o.totalPrice.toStringAsFixed(2)} €',
                                                style: PaymentAtHandoverHint.style,
                                              ),
                                            if (_selling)
                                              const PaymentAtHandoverHint(
                                                text: OrderPaymentCopy.producerOrderPaymentHint,
                                              ),
                                            Text(
                                              o.fulfillment == FulfillmentType.pickup
                                                  ? 'Järeletulemine'
                                                  : 'Kohaletoimetamine',
                                              style: const TextStyle(color: LokalColors.muted),
                                            ),
                                            const SizedBox(height: 6),
                                            Chip(
                                              label: Text(orderStatusLabel(o.status)),
                                              visualDensity: VisualDensity.compact,
                                              backgroundColor: LokalColors.beige,
                                            ),
                                            if (o.message != null)
                                              Text('„${o.message}”', style: const TextStyle(fontStyle: FontStyle.italic)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    if (_selling && o.status == OrderStatus.pending) ...[
                                      FilledButton(
                                        onPressed: () => _update(o, OrderStatus.accepted),
                                        child: const Text('Võta vastu'),
                                      ),
                                      OutlinedButton(
                                        onPressed: () => _update(o, OrderStatus.rejected),
                                        child: const Text('Keeldu'),
                                      ),
                                    ],
                                    if (_selling && o.status == OrderStatus.accepted)
                                      FilledButton(
                                        onPressed: () => _update(o, OrderStatus.completed),
                                        child: const Text('Märgi lõpetatuks'),
                                      ),
                                    if (!_selling && o.status == OrderStatus.pending)
                                      OutlinedButton(
                                        onPressed: () => _update(o, OrderStatus.cancelled),
                                        child: const Text('Tühista'),
                                      ),
                                    if (!_selling && o.canReview)
                                      OutlinedButton(
                                        onPressed: () => _review(o),
                                        child: const Text('Jäta hinnang'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
