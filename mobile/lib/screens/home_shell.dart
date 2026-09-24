import 'package:flutter/material.dart';
import 'package:lokal/screens/browse_screen.dart';
import 'package:lokal/screens/orders_screen.dart';
import 'package:lokal/screens/producer_screen.dart';
import 'package:lokal/screens/profile_screen.dart';
import 'package:lokal/services/auth_service.dart';
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
    final profileTabIndex = auth.isProducer ? 3 : 2;

    final pages = <Widget>[
      const BrowseScreen(),
      OrdersScreen(isActive: _index == 1),
      if (auth.isProducer) ProducerScreen(isActive: _index == 2),
      ProfileScreen(isActive: _index == profileTabIndex),
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
