import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../config/ui_helpers.dart';
import 'screens.dart';
import '../services/store_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _openAuth({bool signUp = false}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AuthPage(initialScreen: signUp ? 1 : 0),
    ));
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    if (!connected) return;

    try {
      await db.auth.signOut();
      store.clearFavorites();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AuthPage(initialScreen: 0),
        ),
      );

      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        notice(context, 'Unable to log out. Please try again.');
      }
    }
  }

  void _go(Widget page) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => page),
      );

  Widget _action({required String label, required IconData icon,
      required VoidCallback onTap, bool primary = false}) {
    return Expanded(
      child: SizedBox(
        height: 52,
        child: FilledButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 19),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          style: FilledButton.styleFrom(
            backgroundColor: primary ? red : const Color(0xFF292323),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: primary ? BorderSide.none : const BorderSide(color: Color(0xFF503338)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _link(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF211B1C),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: red, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(
                    fontSize: 12, color: Colors.white60)),
                ],
              )),
              const Icon(Icons.chevron_right, color: Colors.white60),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _content(User? user) {
    final signedIn = user != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF351316), Color(0xFF1B1718)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF572027)),
          ),
          child: Column(children: [
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF30282A),
                border: Border.all(color: red.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Icon(signedIn ? Icons.person : Icons.person_outline,
                size: 39, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(signedIn ? 'MY ACCOUNT' : 'WELCOME TO BURN',
              style: const TextStyle(fontSize: 11, letterSpacing: 2.4,
                fontWeight: FontWeight.w700, color: Color(0xFFFF6474))),
            const SizedBox(height: 8),
            Text(signedIn ? (user.email ?? 'BURN Member') : 'Your style starts here.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(signedIn ? 'Welcome back to BURN Clothing.' :
                'Log in to manage your orders, saved addresses and favorites.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, height: 1.45,
                fontSize: 13)),
            const SizedBox(height: 22),
            if (!signedIn) Row(children: [
              _action(label: 'LOG IN', icon: Icons.login,
                onTap: () => _openAuth(), primary: true),
              const SizedBox(width: 10),
              _action(label: 'SIGN UP', icon: Icons.person_add_alt_1_outlined,
                onTap: () => _openAuth(signUp: true)),
            ]) else SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 19),
                label: const Text('LOG OUT'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF744047)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 27),
        const Text('MY BURN', style: TextStyle(fontSize: 13,
          fontWeight: FontWeight.w800, letterSpacing: 1.8)),
        const SizedBox(height: 14),
        _link(Icons.receipt_long_outlined, 'My Orders',
          'View purchases and order updates', () => _go(const OrdersPage())),
        _link(Icons.location_on_outlined, 'My Addresses',
          'Manage your delivery details', () => _go(const AddressPage())),
        _link(Icons.favorite_border, 'Wishlist',
          'See the pieces you love', () => _go(Scaffold(
            appBar: AppBar(title: const Text('Wishlist')),
            body: const WishlistPage(),
          ))),
        const SizedBox(height: 20),
        const Center(child: Text('BURN CLOTHING  â€¢  WEAR YOUR FIRE.',
          style: TextStyle(color: Colors.white38, fontSize: 10,
            letterSpacing: 1.2))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!connected) return _content(null);
    return StreamBuilder<AuthState>(
      stream: db.auth.onAuthStateChange,
      builder: (context, snapshot) => _content(db.auth.currentUser),
    );
  }
}

