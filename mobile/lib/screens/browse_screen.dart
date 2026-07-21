import 'package:flutter_map/flutter_map.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/services/marketplace_service.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/widgets/product_card.dart';
import 'package:lokal/core/config.dart';
import 'package:lokal/screens/product_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _search = TextEditingController();
  ProductCategory? _category;
  int _radiusKm = 20;
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  double get _lat =>
      context.read<AuthService>().user?.latitude ?? AppConfig.defaultLat;
  double get _lng =>
      context.read<AuthService>().user?.longitude ?? AppConfig.defaultLng;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await context.read<MarketplaceService>().searchProducts(
            lat: _lat,
            lng: _lng,
            radiusKm: _radiusKm,
            category: _category,
            q: _search.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _products = products;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lokal')),
      body: RefreshIndicator(
        onRefresh: _load,
        color: LokalColors.forest,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const BrandHeader(),
            const SizedBox(height: 8),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Otsi maasikaid, mett, leiba…',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _load(),
              onChanged: (_) {
                // debounce-ish: reload on clear or after short delay via submit
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in categoryOptions) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${c.emoji} ${c.label}'),
                        selected: _category == c.key,
                        onSelected: (_) {
                          setState(() => _category = c.key);
                          _load();
                        },
                        selectedColor: LokalColors.forest,
                        labelStyle: TextStyle(
                          color: _category == c.key ? Colors.white : LokalColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Raadius', style: TextStyle(color: LokalColors.muted, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                for (final km in radiusOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('$km km'),
                      selected: _radiusKm == km,
                      onSelected: (_) {
                        setState(() => _radiusKm = km);
                        _load();
                      },
                      selectedColor: LokalColors.forest,
                      labelStyle: TextStyle(
                        color: _radiusKm == km ? Colors.white : LokalColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(_lat, _lng),
                    initialZoom: 11,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ee.lokal.app',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final p in _products)
                          Marker(
                            point: LatLng(p.latitude, p.longitude),
                            width: 28,
                            height: 28,
                            child: GestureDetector(
                              onTap: () => _openProduct(p),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: LokalColors.forest,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 6),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Lähedal', style: brandTitle(size: 24)),
            Text(
              _loading ? 'Laen…' : '${_products.length} toodet · $_radiusKm km raadiuses',
              style: const TextStyle(color: LokalColors.muted),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: LokalColors.danger))
            else if (_products.isEmpty)
              const Text('Selles raadiuses tooteid ei leitud. Proovi suuremat raadiust.',
                  style: TextStyle(color: LokalColors.muted))
            else
              ..._products.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: ProductCard(
                        product: e.value,
                        delay: e.key * 40,
                        onTap: () => _openProduct(e.value),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductScreen(productId: product.id)),
    );
  }
}
