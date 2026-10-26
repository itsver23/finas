import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart' as auth_config;
import 'auth_screen.dart';
import '../config/app_config.dart';
import '../config/ui_helpers.dart';
import '../models/item.dart';
import '../services/store_service.dart';

class ProductGrid extends StatelessWidget {
  final List<Item> products;
  const ProductGrid({super.key,required this.products});
  @override Widget build(BuildContext context) => products.isEmpty
    ? const Padding(padding:EdgeInsets.all(28),child:Center(child:Text('No products available yet.')))
    : LayoutBuilder(builder:(context, constraints) {
      final width = constraints.maxWidth;
      final columns = width >= 1000 ? 5 : width >= 650 ? 4 : 2;
      final spacing = width < 360 ? 6.0 : 10.0;
      final padding = width < 360 ? 6.0 : 10.0;
      final cardWidth = (width - padding * 2 - spacing * (columns - 1)) / columns;
      // Product photo stays proportional; reserve enough space for the title and bag button.
      final cardHeight = cardWidth * 1.12 + 62;
      return GridView.builder(
      shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      padding:EdgeInsets.all(padding),
      gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:columns,
        mainAxisExtent:cardHeight,
        crossAxisSpacing:spacing,mainAxisSpacing:spacing),
      itemCount:products.length,
      itemBuilder:(context,i){
        final item=products[i];
        return InkWell(
          onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>ProductPage(item:item))),
          child:Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),clipBehavior:Clip.antiAlias,child:Column(
            crossAxisAlignment:CrossAxisAlignment.start,
            children:[
              Expanded(child:Stack(fit:StackFit.expand,children:[
                ProductImage(item:item, fit: BoxFit.contain),
                Positioned(top:6,right:6,child:FavoriteButton(item:item)),
              ])),
              Padding(padding:const EdgeInsets.fromLTRB(8,6,5,6),child:Row(children:[
                Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text(item.name,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.bold)),
                  Text(peso(item.price),style:const TextStyle(fontWeight:FontWeight.bold,color:red)),
                ])),
                _QuickBagButton(item:item),
              ])),
            ],
          )),
        );
      },
    );
    });
}

class _QuickBagButton extends StatefulWidget {
  final Item item;
  const _QuickBagButton({required this.item});
  @override State<_QuickBagButton> createState()=>_QuickBagButtonState();
}
class _QuickBagButtonState extends State<_QuickBagButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _glow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final before = store.count;
    store.add(widget.item);
    if (store.count == before) {
      notice(context, 'Maximum available stock reached');
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Add ${widget.item.name} to cart',
    child: AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: red,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: red.withValues(alpha: 0.42 * _glow.value),
              blurRadius: 18 * _glow.value,
              spreadRadius: 3 * _glow.value,
            ),
          ],
        ),
        child: child,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _add,
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(Icons.shopping_bag_outlined,
                color: Colors.white, size: 22),
          ),
        ),
      ),
    ),
  );
}

class ProductImage extends StatelessWidget {
  final Item item;
  final BoxFit fit;
  const ProductImage({super.key, required this.item, this.fit = BoxFit.cover});

  String get fallbackAsset {
    final text = '${item.name} ${item.category}'.toLowerCase();
    if (text.contains('hoodie') || text.contains('sweatshirt')) return 'assets/products/hoodie.jpg';
    if (text.contains('jacket') || text.contains('outerwear')) return 'assets/products/jacket.jpg';
    if (text.contains('cargo') || text.contains('pants') || text.contains('jeans')) return 'assets/products/cargo.jpg';
    if (text.contains('short')) return 'assets/products/shorts.jpg';
    if (text.contains('cap') || text.contains('hat')) return 'assets/products/cap.jpg';
    if (text.contains('bag') || text.contains('backpack')) return 'assets/products/bag.jpg';
    if (text.contains('shoe') || text.contains('sneaker') || text.contains('footwear')) return 'assets/products/shoes.jpg';
    if (text.contains('dress') || text.contains('skirt')) return 'assets/products/dress.jpg';
    if (text.contains('polo')) return 'assets/products/polo.jpg';
    if (text.contains('top') || text.contains('ladies')) return 'assets/products/top.jpg';
    return 'assets/products/tee.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final image = item.image.trim();
    final fallback = fallbackAsset;
    Widget asset(String path) => Image.asset(path, fit: fit,
      width: double.infinity, height: double.infinity,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.checkroom, size: 28)));
    return Container(
      color: const Color(0xFF252525),
      width: double.infinity,
      child: image.startsWith('http://') || image.startsWith('https://')
          ? Image.network(image, fit: fit,
              errorBuilder: (_, __, ___) => asset(fallback))
          : asset(image.startsWith('assets/') ? image : fallback),
    );
  }
}
class FavoriteButton extends StatefulWidget {
  final Item item;
  const FavoriteButton({super.key, required this.item});
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _popping = false;

  Future<void> _toggle() async {
    if (!auth_config.connected || Supabase.instance.client.auth.currentUser == null) {
      final loggedIn = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
      if (!mounted || loggedIn != true ||
          Supabase.instance.client.auth.currentUser == null) {
        return;
      }
    }
    store.toggle(widget.item);
    setState(() => _popping = true);
    Future.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _popping = false);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final selected = store.favorites.contains(widget.item.id);
      return Material(
        color: Colors.black.withValues(alpha: .75),
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: selected ? 'Remove from wishlist' : 'Add to wishlist',
          onPressed: _toggle,
          icon: AnimatedScale(
            scale: _popping ? 1.35 : 1,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                selected ? Icons.favorite : Icons.favorite_border,
                key: ValueKey(selected),
                color: selected ? red : Colors.white,
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ProductPage extends StatefulWidget {
  final Item item;
  const ProductPage({super.key, required this.item});
  @override
  State<ProductPage> createState() => _ProductState();
}

class _ProductState extends State<ProductPage> {
  String size = 'M';
  String color = 'Black';
  bool _added = false;

  void _addToCart() {
    final before = store.count;
    store.add(widget.item);
    if (store.count == before) {
      notice(context, 'Maximum available stock reached');
      return;
    }
    setState(() => _added = true);
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted) setState(() => _added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item;
    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).width * 0.68).clamp(155.0, 300.0),
            child: ProductImage(item: p, fit: BoxFit.contain),
          ),
          const SizedBox(height: 18),
          Text(p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(peso(p.price), style: const TextStyle(fontSize: 23, color: red, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text('Color'),
          Wrap(spacing: 8, children: ['Black', 'White', 'Red'].map((s) =>
            ChoiceChip(label: Text(s), selected: color == s, onSelected: (_) => setState(() => color = s))).toList()),
          const SizedBox(height: 15),
          const Text('Size'),
          Wrap(spacing: 8, children: ['S', 'M', 'L', 'XL'].map((s) =>
            ChoiceChip(label: Text(s), selected: size == s, onSelected: (_) => setState(() => size = s))).toList()),
          const SizedBox(height: 16),
          Text('Stock: ${p.stock}'),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: p.stock > 0 ? _addToCart : null,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Row(
                  key: ValueKey(_added),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_added ? Icons.check_circle : Icons.shopping_cart),
                    const SizedBox(width: 8),
                    Text(_added ? 'Added to Cart!' : 'Add to Cart'),
                  ],
                ),
              ),
            )),
            const SizedBox(width: 12),
            FavoriteButton(item: p),
          ]),
        ],
      ),
    );
  }
}
