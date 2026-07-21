import 'package:flutter/material.dart';
import 'package:kodukraam/screens/browse_screen.dart';
import 'package:kodukraam/screens/orders_screen.dart';
import 'package:kodukraam/screens/producer_screen.dart';
import 'package:kodukraam/screens/profile_screen.dart';
import 'package:kodukraam/services/auth_service.dart';
import 'package:provider/provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final pages = <Widget>[
      const BrowseScreen(),
      const OrdersScreen(),
      if (auth.isProducer) const ProducerScreen(),
      const ProfileScreen(),
    ];

    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.storefront_outlined), label: 'Avasta'),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), label: 'Tellimused'),
      if (auth.isProducer)
        const BottomNavigationBarItem(icon: Icon(Icons.eco_outlined), label: 'Müü'),
      const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profiil'),
    ];

    if (_index >= pages.length) {
      _index = 0;
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: items,
      ),
    );
  }
}
