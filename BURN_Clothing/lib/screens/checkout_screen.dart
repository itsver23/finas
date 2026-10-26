import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/ui_helpers.dart';
import '../services/store_service.dart';
import '../services/payment_service.dart';
import 'address_screen.dart';
import 'auth_screen.dart';
import 'payment_screen.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override State<CheckoutPage> createState() => _CheckoutState();
}
class _CheckoutState extends State<CheckoutPage> {
  String delivery = 'Standard';
  String? selectedAddress;
  bool busy = false;
  List<Map<String, dynamic>> addresses = [];
  @override void initState() { super.initState(); refreshAddresses(); }
  Future<void> refreshAddresses() async {
    if (!connected || db.auth.currentUser == null) return;
    try {
      final result = await db.from('addresses').select('id,full_name,street,city,postal_code')
        .eq('user_id', db.auth.currentUser!.id).order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        addresses = List<Map<String,dynamic>>.from(result);
        if (!addresses.any((a) => a['id'] == selectedAddress)) {
          selectedAddress = addresses.isEmpty ? null : addresses.first['id'] as String;
        }
      });
    } catch (e) { if (mounted) notice(context, 'Cannot load addresses: $e'); }
  }
  Future<void> pay() async {
    if (!connected) { notice(context, 'Configure Supabase first'); return; }
    if (db.auth.currentUser == null) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
      if (mounted) refreshAddresses();
      return;
    }
    if (selectedAddress == null) { notice(context, 'Select or add a shipping address'); return; }
    if (store.cart.isEmpty || store.isDemo) { notice(context, 'Demo items cannot be purchased'); return; }
    setState(() => busy = true);
    try {
      final url = await PaymentService.createCheckout(
        items: store.cart.map((p) => {'product_id': p.id, 'quantity': store.quantities[p.id]}).toList(),
        addressId: selectedAddress!, delivery: delivery,
      );
      if (mounted) await Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage(url: url)));
    } catch (e) { if (mounted) notice(context, 'Checkout failed: $e'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Shipping Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      if (addresses.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('No saved addresses yet.')),
      RadioGroup<String>(
        groupValue: selectedAddress,
        onChanged: (value) => setState(() => selectedAddress = value),
        child: Column(
          children: [
            for (final a in addresses)
              RadioListTile<String>(
                title: Text(a['full_name'].toString()),
                subtitle: Text('${a['street']}, ${a['city']} ${a['postal_code']}'),
                value: a['id'] as String,
              ),
          ],
        ),
      ),
      OutlinedButton(onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressPage()));
        if (mounted) refreshAddresses();
      }, child: const Text('Add New Address')),
      const SizedBox(height: 16),
      const Text('Delivery Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      RadioGroup<String>(
        groupValue: delivery,
        onChanged: (value) {
          if (value != null) setState(() => delivery = value);
        },
        child: const Column(
          children: [
            RadioListTile<String>(
              title: Text('Standard Delivery — ₱70'),
              value: 'Standard',
            ),
            RadioListTile<String>(
              title: Text('Express Delivery — ₱150'),
              value: 'Express',
            ),
          ],
        ),
      ),
      const Divider(),
      Text('Total: ${peso(store.subtotal + (delivery == 'Standard' ? 70 : 150))}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: busy ? null : pay, child: Text(busy ? 'Creating payment...' : 'Continue to Payment')),
      const Padding(padding: EdgeInsets.only(top: 12), child: Text('Payment is confirmed only by the verified Xendit webhook. Returning from the payment page does not mark an order as paid.')),
    ]),
  );
}
