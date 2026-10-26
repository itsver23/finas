import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/ui_helpers.dart';


String paymentLabel(Map<String, dynamic> order) {
  final payment = (order['payment_status'] ?? '').toString().trim().toUpperCase();
  final status = (order['status'] ?? '').toString().trim().toUpperCase();
  if (payment == 'PAID' || status == 'PAID') return 'PAID';
  if (payment == 'PENDING' || status == 'PENDING') return 'PENDING';
  return payment.isNotEmpty ? payment : (status.isNotEmpty ? status : 'PENDING');
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersState();
}

class _OrdersState extends State<OrdersPage> {
  Future<List<Map<String, dynamic>>> fetch() async {
    final user = connected ? db.auth.currentUser : null;
    if (user == null) return [];

    final rows = await db
        .from('orders')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          actions: [
            IconButton(
              tooltip: 'Refresh orders',
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: !connected || db.auth.currentUser == null
            ? const Center(child: Text('Log in to view your orders'))
            : FutureBuilder<List<Map<String, dynamic>>>(
                future: fetch(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Could not load orders: ${snapshot.error}'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final orders = snapshot.data!;
                  if (orders.isEmpty) {
                    return const Center(child: Text('No orders yet'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {});
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        final id = (order['id'] ?? '').toString();
                        final total = order['total'];
                        final payment = paymentLabel(order);

                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.receipt_long_outlined,
                              color: red,
                            ),
                            title: Text(
                              'Order #${id.length > 8 ? id.substring(0, 8) : id}',
                            ),
                            subtitle: Text(
                              'Total: ${total is num ? peso(total) : 'Unavailable'}\nPayment Status: $payment',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OrderTrackingPage(orderId: id),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      );
}

// The existing class name is retained to avoid breaking other routes.
// This page now shows order total only; no delivery tracking.
class OrderTrackingPage extends StatefulWidget {
  final String orderId;

  const OrderTrackingPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingState();
}

class _OrderTrackingState extends State<OrderTrackingPage> {
  late Future<Map<String, dynamic>> _orderFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _orderFuture = _fetch();
  }

  Future<Map<String, dynamic>> _fetch() async {
    final user = connected ? db.auth.currentUser : null;
    if (user == null) throw Exception('Please log in first');

    final row = await db
        .from('orders')
        .select()
        .eq('id', widget.orderId)
        .eq('user_id', user.id)
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          actions: [
            IconButton(
              tooltip: 'Refresh order',
              onPressed: () => setState(_refresh),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _orderFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Could not load order: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => setState(_refresh),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final order = snapshot.data!;
            final total = order['total'];
            final payment = paymentLabel(order);
            return RefreshIndicator(
              onRefresh: () async {
                setState(_refresh);
                try {
                  await _orderFuture;
                } catch (_) {
                  // The FutureBuilder shows any loading errors.
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: ListTile(
                      title: const Text('Payment Status'),
                      subtitle: Text(
                        payment,
                        style: TextStyle(
                          color: payment == 'PAID' ? Colors.greenAccent : Colors.orangeAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      title: const Text(
                        'Order Total',
                        style: TextStyle(color: Colors.white70),
                      ),
                      subtitle: Text(
                        total is num ? peso(total) : 'Unavailable',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
