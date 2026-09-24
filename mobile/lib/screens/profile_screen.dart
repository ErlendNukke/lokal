import 'package:flutter/material.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/screens/auth_screen.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/widgets/product_card.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _farmName = TextEditingController();
  final _farmDescription = TextEditingController();
  UserRole _role = UserRole.buyer;
  bool _pickup = true;
  bool _delivery = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
    }
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _sync();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _farmName.dispose();
    _farmDescription.dispose();
    super.dispose();
  }

  Future<void> _sync() async {
    final auth = context.read<AuthService>();
    if (!auth.isLoggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
      if (ok != true) return;
    }
    if (!mounted) return;
    final user = context.read<AuthService>().user!;
    setState(() {
      _name.text = user.name;
      _city.text = user.city ?? '';
      _farmName.text = user.farmName ?? '';
      _role = user.role;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = context.read<AuthService>();
    try {
      await auth.updateProfile({
        'name': _name.text.trim(),
        'role': roleApi(_role),
        'city': _city.text.trim(),
        'farmName': _farmName.text.trim(),
        'farmDescription': _farmDescription.text.trim(),
        'pickupAvailable': _pickup,
        'deliveryAvailable': _delivery,
        'latitude': auth.user?.latitude,
        'longitude': auth.user?.longitude,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profiil salvestatud')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profiil')),
      body: user == null
          ? Center(
              child: FilledButton(
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
                },
                child: const Text('Logi sisse'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                BrandHeader(subtitle: '${user.email} · ${roleLabel(user.role)}'),
                const SizedBox(height: 12),
                TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nimi')),
                const SizedBox(height: 12),
                TextField(controller: _city, decoration: const InputDecoration(labelText: 'Linn')),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  // ignore: deprecated_member_use
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Roll'),
                  items: const [
                    DropdownMenuItem(value: UserRole.buyer, child: Text('Ostja')),
                    DropdownMenuItem(value: UserRole.producer, child: Text('Tootja')),
                    DropdownMenuItem(value: UserRole.both, child: Text('Mõlemad')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? UserRole.buyer),
                ),
                if (_role == UserRole.producer || _role == UserRole.both) ...[
                  const SizedBox(height: 12),
                  TextField(controller: _farmName, decoration: const InputDecoration(labelText: 'Talu / brändi nimi')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _farmDescription,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Kirjeldus'),
                  ),
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
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Salvestan…' : 'Salvesta'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () async {
                    await auth.logout();
                    if (!mounted) return;
                    setState(() {});
                  },
                  child: const Text('Logi välja'),
                ),
              ],
            ),
    );
  }
}
