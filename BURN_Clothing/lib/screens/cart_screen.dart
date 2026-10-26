import 'package:flutter/material.dart';
import '../config/ui_helpers.dart';
import '../services/store_service.dart';
import 'product_screen.dart';
import 'checkout_screen.dart';
import 'auth_screen.dart';
import '../config/app_config.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: Text('My Cart (${store.count})')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: store.cart.map((p) => ListTile(
                leading: SizedBox(width: 58, height: 65, child: ProductImage(item: p, fit: BoxFit.contain)),
                title: Text(p.name),
                subtitle: Text(peso(p.price)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => store.change(p, -1),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${store.quantities[p.id] ?? 0}'),
                    IconButton(
                      onPressed: () => store.change(p, 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Subtotal: ${peso(store.subtotal)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: store.cart.isEmpty ? null : () async {
                    if (store.isDemo) {
                      notice(context, 'Demo products cannot be purchased. Configure Supabase catalog first.');
                      return;
                    }
                    if (!connected) {
                      notice(context, 'Supabase is not configured. Checkout is unavailable.');
                      return;
                    }
                    if (db.auth.currentUser == null) {
                      final signedIn = await Navigator.push<bool>(context,
                        MaterialPageRoute(builder: (_) => const AuthPage()));
                      if (!context.mounted || signedIn != true || db.auth.currentUser == null) return;
                    }
                    if (!context.mounted) return;
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const CheckoutPage(),
                    ));
                  },
                  child: const Text('Proceed to Checkout'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
