import '../config/app_config.dart';

class PaymentService {
  static Future<String> createCheckout({
    required List<Map<String, dynamic>> items,
    required String addressId,
    required String delivery,
  }) async {
    if (!connected) {
      throw StateError('Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    if (db.auth.currentSession == null) {
      throw StateError('Please log in before checkout.');
    }
    if (items.isEmpty) {
      throw StateError('Your cart is empty.');
    }
    final response = await db.functions.invoke('create-checkout', body: {
      'items': items,
      'address_id': addressId,
      'delivery': delivery,
    });
    final data = response.data;
    if (response.status != 200 || data is! Map) {
      final reason = data is Map ? data['error']?.toString() : null;
      throw StateError(reason ?? 'Could not start payment (HTTP ${response.status}).');
    }
    final url = data['invoice_url']?.toString();
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw StateError('Payment provider did not return a valid checkout URL.');
    }
    return url!;
  }
}
