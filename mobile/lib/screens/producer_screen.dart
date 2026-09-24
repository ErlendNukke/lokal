import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lokal/core/config.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/services/marketplace_service.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/utils/prepare_image_upload.dart';
import 'package:lokal/widgets/product_card.dart';
import 'package:lokal/widgets/product_network_image.dart';
import 'package:provider/provider.dart';

class ProducerScreen extends StatefulWidget {
  const ProducerScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ProducerScreen> createState() => _ProducerScreenState();
}

class _ProducerScreenState extends State<ProducerScreen> {
  List<Product> _products = [];
  bool _loading = true;
  bool _showForm = false;
  bool _saving = false;

  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController(text: '5');
  final _quantity = TextEditingController(text: '10');
  final _location = TextEditingController(text: 'Tallinn');
  ProductCategory _category = ProductCategory.food;
  ProductUnit _unit = ProductUnit.piece;
  bool _pickup = true;
  bool _delivery = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _description, _price, _quantity, _location]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void didUpdateWidget(covariant ProducerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _quantity.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final products = await context.read<MarketplaceService>().myProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return;
    try {
      final prepared = await prepareImageForUpload(file);
      if (!mounted) return;
      final url = await context.read<MarketplaceService>().uploadImage(
            prepared.bytes,
            filename: prepared.filename,
            mimeType: prepared.mimeType,
          );
      setState(() => _photoUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _save() async {
    final auth = context.read<AuthService>();
    setState(() => _saving = true);
    try {
      await context.read<MarketplaceService>().createProduct({
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'category': categoryApi(_category),
        'price': double.tryParse(_price.text) ?? 5,
        'unit': unitApi(_unit),
        'quantity': double.tryParse(_quantity.text) ?? 10,
        'latitude': auth.user?.latitude ?? AppConfig.defaultLat,
        'longitude': auth.user?.longitude ?? AppConfig.defaultLng,
        'locationLabel': _location.text.trim(),
        'pickupAvailable': _pickup,
        'deliveryAvailable': _delivery,
        'photoUrls': _photoUrl == null ? <String>[] : [_photoUrl!],
      });
      _name.clear();
      _description.clear();
      _photoUrl = null;
      setState(() => _showForm = false);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _remove(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eemalda toode?'),
        content: Text(product.name),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tühista')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eemalda')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await context.read<MarketplaceService>().deleteProduct(product.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Müüja töölaud'),
        actions: [
          if (_showForm && _name.text.trim().isNotEmpty)
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvestan…' : 'Salvesta toode'),
            ),
          TextButton(
            onPressed: () => setState(() => _showForm = !_showForm),
            child: Text(_showForm ? 'Sulge' : 'Lisa toode'),
          ),
        ],
      ),
      body: Semantics(
        label: 'Müüja vorm',
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BrandHeader(subtitle: auth.user?.farmName ?? 'Lisa tooteid ja võta tellimusi vastu'),
          if (_showForm) ...[
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Nimi'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Kirjeldus'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ProductCategory>(
                      // ignore: deprecated_member_use
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Kategooria'),
                      items: ProductCategory.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(categoryLabel(c))))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v ?? ProductCategory.food),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _price,
                      decoration: const InputDecoration(labelText: 'Hind (€)'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ProductUnit>(
                      // ignore: deprecated_member_use
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Ühik'),
                      items: ProductUnit.values
                          .map((u) => DropdownMenuItem(value: u, child: Text(unitLabel(u))))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v ?? ProductUnit.piece),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quantity,
                      decoration: const InputDecoration(labelText: 'Kogus'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: _location, decoration: const InputDecoration(labelText: 'Asukoht')),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Järeletulemine'),
                      value: _pickup,
                      onChanged: (v) => setState(() => _pickup = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Kohaletoimetamine'),
                      value: _delivery,
                      onChanged: (v) => setState(() => _delivery = v),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo),
                      label: Text(_photoUrl == null ? 'Lisa foto' : 'Foto valitud'),
                    ),
                    if (_photoUrl != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ProductNetworkImage(imageUrl: _photoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _saving || _name.text.trim().isEmpty ? null : _save,
                      child: Text(_saving ? 'Salvestan…' : 'Salvesta toode'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Sinu tooted', style: brandTitle(size: 22)),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_products.isEmpty)
            const Text('Tooteid pole. Lisa esimene!', style: TextStyle(color: LokalColors.muted))
          else
            ..._products.map(
              (p) => ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: p.photo.isEmpty
                      ? Container(width: 56, height: 56, color: LokalColors.beigeDeep)
                      : ProductNetworkImage(imageUrl: p.photo, width: 56, height: 56, fit: BoxFit.cover),
                ),
                title: Text(p.name),
                subtitle: Text('${p.price.toStringAsFixed(2)} € / ${unitApi(p.unit)} · ${p.quantity} saadaval'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: LokalColors.danger),
                  onPressed: () => _remove(p),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}
