import 'package:flutter/material.dart';
import 'package:lokal/core/config.dart';
import 'package:lokal/models/models.dart';
import 'package:lokal/services/auth_service.dart';
import 'package:lokal/theme/app_theme.dart';
import 'package:lokal/widgets/product_card.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _register = false;
  bool _loading = false;
  String? _error;
  UserRole _role = UserRole.buyer;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthService>();
    try {
      if (_register) {
        await auth.register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          role: _role,
          city: AppConfig.defaultCity,
          latitude: AppConfig.defaultLat,
          longitude: AppConfig.defaultLng,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fillDemo(String email) {
    setState(() {
      _register = false;
      _email.text = email;
      _password.text = 'password123';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_register ? 'Loo konto' : 'Logi sisse')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const BrandHeader(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sisselogimine'),
                selected: !_register,
                onSelected: (_) => setState(() => _register = false),
                selectedColor: LokalColors.forest,
                labelStyle: TextStyle(color: !_register ? Colors.white : LokalColors.ink),
              ),
              ChoiceChip(
                label: const Text('Registreeru'),
                selected: _register,
                onSelected: (_) => setState(() => _register = true),
                selectedColor: LokalColors.forest,
                labelStyle: TextStyle(color: _register ? Colors.white : LokalColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_register) ...[
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nimi')),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'E-post'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            decoration: const InputDecoration(labelText: 'Parool'),
            obscureText: true,
          ),
          if (_register) ...[
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
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: LokalColors.danger)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: Text(_loading ? 'Palun oota…' : (_register ? 'Loo konto' : 'Logi sisse')),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    try {
                      await context.read<AuthService>().googleDemo();
                      if (!context.mounted) return;
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      setState(() => _error = e.toString());
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
            child: const Text("Jätka Google'iga (demo)"),
          ),
          const SizedBox(height: 24),
          const Text('Demo kontod (parool: password123)', style: TextStyle(color: LokalColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(label: const Text('Ostja · Anna'), onPressed: () => _fillDemo('anna@lokal.app')),
              ActionChip(label: const Text('Tootja · Mari'), onPressed: () => _fillDemo('mari@lokal.app')),
              ActionChip(label: const Text('Tootja · Jüri'), onPressed: () => _fillDemo('juri@lokal.app')),
            ],
          ),
        ],
      ),
    );
  }
}
