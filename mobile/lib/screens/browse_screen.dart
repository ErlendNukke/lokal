import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:lokal/core/config.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/screens/product_screen.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/services/marketplace_service.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/widgets/product_card.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _search = TextEditingController();
  final _mapController = MapController();
  ProductCategory? _category;
  List<Product> _products = [];
  bool _loading = true;
  bool _locating = true;
  String? _error;
  String? _locationNote;
  late double _lat;
  late double _lng;
  bool _hasDeviceLocation = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    _lat = user?.latitude ?? AppConfig.defaultLat;
    _lng = user?.longitude ?? AppConfig.defaultLng;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resolveLocation();
      await _load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _locating = true;
      _locationNote = null;
    });
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationNote = 'Asukohateenus on välja lülitatud — kasutan vaikeasukohta.';
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locating = false;
          _locationNote = 'Asukohaluba puudub — kasutan vaikeasukohta.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _hasDeviceLocation = true;
        _locating = false;
        _locationNote = null;
      });
      try {
        _mapController.move(LatLng(_lat, _lng), 12);
      } catch (_) {
        // Map may not be ready yet; initialCenter updates on rebuild.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _locationNote = 'Asukohta ei õnnestunud määrata — kasutan vaikeasukohta.';
      });
    }
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
            radiusKm: AppConfig.radiusKm,
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

  Future<void> _refresh() async {
    await _resolveLocation();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lokal')),
      body: RefreshIndicator(
        onRefresh: _refresh,
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
                Icon(
                  _hasDeviceLocation ? Icons.my_location : Icons.location_searching,
                  size: 18,
                  color: LokalColors.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locating
                        ? 'Määran asukohta…'
                        : (_locationNote ?? '${AppConfig.radiusKm} km raadius'),
                    style: const TextStyle(color: LokalColors.muted, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: _refresh,
                  tooltip: 'Uuenda asukohta',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 220,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_lat, _lng),
                    initialZoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'ee.lokal.app',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(_lat, _lng),
                          radius: AppConfig.radiusKm * 1000,
                          useRadiusInMeter: true,
                          color: LokalColors.forest.withValues(alpha: 0.12),
                          borderStrokeWidth: 1.5,
                          borderColor: LokalColors.forest.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_lat, _lng),
                          width: 44,
                          height: 44,
                          child: const _UserLocationMarker(),
                        ),
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
              _loading
                  ? 'Laen…'
                  : '${_products.length} toodet · ${AppConfig.radiusKm} km raadiuses',
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
              const Text(
                'Selles raadiuses tooteid ei leitud.',
                style: TextStyle(color: LokalColors.muted),
              )
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

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED).withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF2F80ED),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}
